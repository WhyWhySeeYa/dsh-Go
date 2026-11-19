import AVFoundation
import ActivityKit
import BackgroundTasks
import CoreLocation
import UIKit

/// Keeps a turn the user started going after they leave the app, where the system allows it:
/// iOS 26 and later, while it isn't short of resources. The system shows its own progress card
/// and the user can end the task there. Elsewhere, and once it ends, the engine pauses at its
/// next tool call as it always did. Main thread only.
final class ContinuedRun {
  /// Whether the task is running now.
  var onChange: ((Bool) -> Void)?

  private var wanted = false
  /// The system or the user ended it: not again until the next turn.
  private var spent = false
  private var submitted: String?
  private var task: BGTask?
  private var progress: Timer?

  init() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(becameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
  }

  func update(running: Bool) {
    guard running != wanted else { return }
    wanted = running
    trace(running ? "requested" : "idle")
    if running {
      spent = false
    } else {
      finish(success: true)
    }
  }

  /// Continued tasks show a system Live Activity as soon as submitted. Submit
  /// at the foreground-to-background boundary so an ordinary foreground chat
  /// does not leave an always-on progress card above the conversation.
  @objc private func willResignActive() {
    if wanted { submit() }
  }

  @objc private func becameActive() {
    // Returning through Control Center or from another app ends the card. A
    // still-running turn can request a fresh task on the next departure.
    finish(success: true)
  }

  private func submit() {
    guard #available(iOS 26.0, *), !spent, task == nil, submitted == nil,
      UIApplication.shared.applicationState != .background
    else { return }
    // Each request registers its own identifier, so a late launch can't be taken for a newer turn's.
    let identifier = "\(Bundle.main.bundleIdentifier ?? "dsh").continued.\(UUID().uuidString)"
    let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { [weak self] task in
      guard let self, let task = task as? BGContinuedProcessingTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.started(task)
    }
    guard registered else { trace("registration-failed"); return }
    let request = BGContinuedProcessingTaskRequest(
      identifier: identifier,
      title: String(localized: "DSH Go is working"),
      subtitle: String(localized: "This conversation is still going"))
    // Now or not at all: a turn is no use to anyone once it has already paused.
    request.strategy = .fail
    submitted = identifier
    do {
      try BGTaskScheduler.shared.submit(request)
      trace("submitted")
    } catch {
      if submitted == identifier { submitted = nil }
      trace("submit-failed-\((error as NSError).code)")
      // The system said no. The engine pauses in the background, as it does without this.
    }
  }

  @available(iOS 26.0, *)
  private func started(_ task: BGContinuedProcessingTask) {
    guard wanted, task.identifier == submitted else {
      task.setTaskCompleted(success: false)
      return
    }
    submitted = nil
    self.task = task
    trace("running")
    task.expirationHandler = { [weak self, weak task] in
      DispatchQueue.main.async {
        guard let self, let task, self.task === task else { return }
        self.spent = true
        self.trace("expired")
        self.finish(success: false)
      }
    }
    // A turn's length isn't known and the system expects to see progress: this moves and never ends.
    task.progress.totalUnitCount = 1_000_000
    progress = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak task] _ in
      task?.progress.completedUnitCount += 1
    }
    onChange?(true)
  }

  // Bounded, content-free development evidence for actual OS acceptance.
  // Never include tool arguments, endpoints, tokens or conversation identifiers.
  private func trace(_ stage: String) {
    guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    let file = directory.appendingPathComponent("dsh-background-task.log")
    let previous = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
    let line = "\(Date().timeIntervalSince1970) continued \(stage)\n"
    try? (String(previous.suffix(8192)) + line).write(to: file, atomically: true, encoding: .utf8)
  }

  private func finish(success: Bool) {
    progress?.invalidate()
    progress = nil
    if let submitted {
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: submitted)
      self.submitted = nil
    }
    guard let running = task else { return }
    task = nil
    running.setTaskCompleted(success: success)
    onChange?(false)
  }
}


// MARK: - Background run: location keep-alive + Live Activity

/// Keeps a running turn alive after the app leaves the foreground: background
/// location updates keep the process scheduled, and a Live Activity shows the
/// turn on the Lock Screen and in the Dynamic Island.
///
/// Location needs `location` in UIBackgroundModes and an Always authorization;
/// without it the app behaves exactly as before and the engine pauses when the
/// system suspends it. Main thread only.
/// Plays silence while the app is in the background so iOS keeps scheduling the
/// process (the `audio` background mode is already declared). The session mixes
/// with others and is never deactivated on stop, so music, voice playback and
/// recording owned by other roles keep working.
private final class SilentAudioKeepAlive {
  private var engine: AVAudioEngine?
  private var player: AVAudioPlayerNode?
  private var observer: NSObjectProtocol?
  private(set) var running = false

  func start() {
    guard !running else { return }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
      let engine = AVAudioEngine()
      let player = AVAudioPlayerNode()
      engine.attach(player)
      let format = AVAudioFormat(standardFormatWithSampleRate: 8_000, channels: 1)!
      engine.connect(player, to: engine.mainMixerNode, format: format)
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8_000)!
      buffer.frameLength = 8_000
      if let channels = buffer.floatChannelData {
        for channel in 0..<Int(format.channelCount) {
          memset(channels[channel], 0, Int(buffer.frameLength) * MemoryLayout<Float>.size)
        }
      }
      player.scheduleBuffer(buffer, at: nil, options: .loops)
      try engine.start()
      player.play()
      self.engine = engine
      self.player = player
      running = true
      observeInterruptions()
    } catch {
      stop()
    }
  }

  func stop() {
    guard running || engine != nil else { return }
    running = false
    player?.stop()
    engine?.stop()
    player = nil
    engine = nil
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
    // Never deactivate here: another role (voice, media) may own the session.
  }

  private func observeInterruptions() {
    observer = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
    ) { [weak self] note in
      guard let self,
        let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
        AVAudioSession.InterruptionType(rawValue: raw) == .ended
      else { return }
      if self.running {
        self.stop()
        self.start()
      }
    }
  }
}

@available(iOS 16.2, *)
@MainActor
final class RunBackground: NSObject, CLLocationManagerDelegate {
  static let shared = RunBackground()

  private let location = CLLocationManager()
  private let silentAudio = SilentAudioKeepAlive()
  private var activity: Activity<RunActivityAttributes>?
  private var startedAt = Date()
  private var wanted = false

  override init() {
    super.init()
    location.delegate = self
    location.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    location.distanceFilter = 500
    location.pausesLocationUpdatesAutomatically = false
    location.allowsBackgroundLocationUpdates = true
    NotificationCenter.default.addObserver(
      self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification,
      object: nil)
  }

  /// Silence only matters once the app is leaving the foreground; starting it
  /// earlier would hold an audio session during ordinary foreground chats.
  @objc private func willResignActive() {
    if wanted { silentAudio.start() }
  }

  @objc private func didBecomeActive() {
    silentAudio.stop()
  }

  /// Whether the keep-alive is holding the app right now (the turn is running).
  var isActive: Bool { wanted }

  /// Called whenever the engine's turn state changes.
  func update(running: Bool) {
    guard running != wanted else { return }
    wanted = running
    if running {
      startedAt = Date()
      startLocation()
      startActivity()
    } else {
      stopLocation()
      silentAudio.stop()
      endActivity()
    }
  }

  private func startLocation() {
    switch location.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      print("[RunBackground] location updates started")
      location.startUpdatingLocation()
    case .notDetermined:
      print("[RunBackground] asking for Always location")
      location.requestAlwaysAuthorization()
    default:
      // Denied or restricted: the Live Activity still runs, the engine pauses.
      break
    }
  }

  private func stopLocation() {
    location.stopUpdatingLocation()
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    Task { @MainActor in
      if status == .authorizedAlways, self.wanted {
        self.location.startUpdatingLocation()
      }
    }
  }

  private func startActivity() {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      print("[RunBackground] live activities disabled")
      return
    }
    let attributes = RunActivityAttributes(name: "DSH Go")
    let state = RunActivityAttributes.ContentState(
      title: String(localized: "Working"),
      detail: String(localized: "This conversation is still going"),
      startedAt: startedAt)
    do {
      activity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nil),
        pushType: nil)
    } catch {
      print("[RunBackground] activity request failed: \(error)")
      activity = nil
    }
  }

  private func endActivity() {
    guard let activity else { return }
    self.activity = nil
    let state = RunActivityAttributes.ContentState(
      title: String(localized: "Done"),
      detail: "",
      startedAt: startedAt)
    Task {
      await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .default)
    }
  }
}

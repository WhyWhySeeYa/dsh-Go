import ActivityKit
import Foundation

/// One running turn, mirrored into a Live Activity. The app starts and updates
/// it; the widget extension draws it. Both targets compile this file, so the
/// attributes type is the same on both sides.
@available(iOS 16.1, *)
public struct RunActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// The conversation or task line shown on the Lock Screen.
    public var title: String
    /// A short secondary line (current step, model, …). Empty hides it.
    public var detail: String
    /// When the turn started; the card shows a timer from it.
    public var startedAt: Date

    public init(title: String, detail: String, startedAt: Date) {
      self.title = title
      self.detail = detail
      self.startedAt = startedAt
    }
  }

  /// The app name shown in the card's header.
  public var name: String

  public init(name: String) {
    self.name = name
  }
}

# iOS usage and build guide

[简体中文](ios-fork.md) · [Back to the README](../README.en.md)

This branch is an unofficial fork of [ccch1mneyyy/dsh-Go](https://github.com/ccch1mneyyy/dsh-Go), originally created by [ccch1mneyyy](https://github.com/ccch1mneyyy). This guide covers iOS test builds; see [app/ios/README.md](../app/ios/README.md) for the complete upstream project details and limitations.

## Install an existing IPA

1. Download an available `dsh-go-ios.ipa` from this repository's Releases. If none is public, build one using the instructions below.
2. Use LCSign or another compatible tool and your own certificate to sign the app, embedded frameworks, and extensions before installing. Unsupported certificate capabilities may prevent sharing, widgets, or other features from working.
3. In Settings → Local engine, install and start the runtime, then configure your model endpoint and API key in the app.

The IPA filename does not change the app's display name on the phone. Do not upload or share API keys, signing certificates, device pairing records, or personal conversations.

## Build with GitHub Actions

After enabling workflows on the fork, choose `iOS compile` → `Run workflow`, select `ios/special`, and leave `regression_only` unchecked. When the `engine` job's archive check succeeds, download the `ios-unsigned-ipa` artifact; the IPA inside is named `dsh-go-ios.ipa`. The artifact is retained for 14 days by default and does not automatically create or publish a Release. GitHub-hosted builds are subject to account usage and billing settings.

## Build on a Mac

You need macOS with Xcode, Flutter 3.47.7, Python 3.11 or later, and the iOS project's LLVM/lld, Meson, Ninja, and Rust toolchains. For exact versions and environment details, see the [upstream iOS project documentation](../app/ios/README.md). Prepare the engine and optional phone-control native library, then build the unsigned app:

```sh
git clone --branch ios/special https://github.com/yeluoshuangyu/dsh-Go.git
cd dsh-Go
bash tooling/ios/prepare-engine.sh
bash tooling/ios/build-phone-self-runner.sh
cd app
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter build ios --release --no-codesign
```

Place the built app under the IPA's `Payload` directory:

```sh
ipa_stage=$(mktemp -d)
mkdir -p "$ipa_stage/Payload"
cp -R build/ios/iphoneos/Runner.app "$ipa_stage/Payload/"
ditto -c -k --keepParent "$ipa_stage/Payload" "$PWD/dsh-go-ios.ipa"
```

A successful build, simulator run, or archive check does not replace installation and functional verification on a user's device. Enhanced phone control requires a developer connection, a compatibly signed helper, and other device setup. Push notifications, background execution, and the native-media plugin's `voice` capability have the limitations described upstream.

## Attribution and assets

See [LICENSE](../LICENSE) for the code license and [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) for third-party notices. The upstream name, marks, and some artwork have separate terms; read [ASSETS.md](../ASSETS.md) and comply with the applicable permissions before distributing a modified version.

# dsh-go-ios

[简体中文](README.md) · [iOS usage and build guide](docs/ios-fork.en.md)

This is an unofficial iPhone-focused maintenance branch based on [ccch1mneyyy/dsh-Go](https://github.com/ccch1mneyyy/dsh-Go), originally created by [ccch1mneyyy](https://github.com/ccch1mneyyy). Shared upstream source and project history are retained; iOS maintenance takes place on `ios/special`. This project is not affiliated with DeepSeek.

## Download and installation

[View this repository's Releases](https://github.com/yeluoshuangyu/dsh-Go/releases). Public releases will provide a file named `dsh-go-ios.ipa`; if no file is available, build one using the guide below. The IPA is **unsigned** and must be signed with your own tool before installation. Signing must handle the embedded frameworks, share extension, and widget; available capabilities depend on the certificate and configuration.

After installation, open Settings → Local engine to install and start the runtime, then configure your own model provider in the app. Keep API keys, signing certificates, and device pairing records on your own devices; do not commit them to this repository.

## Features and verification

- The app supports a local engine and remote hosts; model requests require a provider configured by the user.
- The upstream iOS project provides an optional Linux guest, file and system tools, sharing, a widget, and phone control. Some capabilities require device permissions, compatible signing, or additional setup.
- The initial build has been installed and launched on an iPhone. Simulator checks exercised the local engine, tool-assisted conversations, and the Linux guest. Other devices, model providers, and permission configurations need separate verification.
- iOS controls background execution; remote notifications after leaving the app are not implemented yet. The native-media plugin's `voice` capability is also unavailable; see the [upstream iOS notes](app/ios/README.md) for details.

## Build

- **GitHub Actions:** run `iOS compile` from Actions, select `ios/special`, and leave `regression_only` disabled. On success, download the `ios-unsigned-ipa` artifact and extract `dsh-go-ios.ipa`. An artifact is not automatically a published Release and is retained for 14 days by default.
- **Build on a Mac:** Xcode, Flutter, and the project's iOS native dependencies are required. See the [iOS usage and build guide](docs/ios-fork.en.md) and the [upstream iOS project notes](app/ios/README.md).

Actions may need to be enabled on a new fork. Hosted builds are subject to the account's usage and billing settings.

## Changes on this branch

This branch updates the Chinese and English landing pages and iOS usage guides, and names the successful iOS workflow artifact `dsh-go-ios.ipa`. The current app source is based on the identified upstream commit; future functional changes should continue to be documented.

## License and attribution

See [LICENSE](LICENSE) for the code license and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for third-party notices. The upstream name, marks, and some artwork have separate terms; read [ASSETS.md](ASSETS.md) and comply with the applicable permissions before distributing a modified version. The [upstream repository](https://github.com/ccch1mneyyy/dsh-Go) contains the full original introduction and documentation for other platforms.

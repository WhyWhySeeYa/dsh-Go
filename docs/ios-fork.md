# iOS 使用与构建说明

[English](ios-fork.en.md) · [返回首页](../README.md)

此分支是 [ccch1mneyyy/dsh-Go](https://github.com/ccch1mneyyy/dsh-Go) 的非官方 Fork，原作者是 [ccch1mneyyy](https://github.com/ccch1mneyyy)。本文件说明 iOS 测试构建，完整工程和限制仍以 [app/ios/README.md](../app/ios/README.md) 为准。

## 安装现有 IPA

1. 从本仓库的 Releases 下载可用的 `dsh-go-ios.ipa`。如果没有公开版本，可以按下方步骤构建。
2. 使用 LCSign 或其他兼容工具，利用自己的证书对主 App、内嵌 framework 和扩展签名后安装。证书不支持的权限可能使分享、小组件或其他能力不可用。
3. 在 App 的「设置 → 本机引擎」安装并启动运行环境；随后在模型设置中自行填写服务地址和 API Key。

IPA 文件名不改变手机上的 App 显示名称。不要上传或分享 API Key、签名证书、设备配对记录或个人对话。

## 在 GitHub Actions 中构建

在 Fork 的 Actions 页面启用工作流后，选择 `iOS compile` → `Run workflow`，分支选 `ios/special`，不勾选 `regression_only`。`engine` 任务的归档检查通过后，下载 `ios-unsigned-ipa` 构建产物；压缩文件内的 IPA 名称为 `dsh-go-ios.ipa`。该产物默认保留 14 天，不会自动创建或公开 Release。GitHub 托管构建机受账号配额和计费设置约束。

## 在 Mac 上构建

需要 macOS 与 Xcode、Flutter 3.47.7、Python 3.11 或更新版本，以及项目 iOS 工程所需的 LLVM/lld、Meson、Ninja 和 Rust 工具链。具体版本及环境说明见 [上游 iOS 工程文档](../app/ios/README.md)。准备引擎和可选手机操控原生库后，构建未签名 App：

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

将构建出的 App 放入 IPA 的 `Payload`：

```sh
ipa_stage=$(mktemp -d)
mkdir -p "$ipa_stage/Payload"
cp -R build/ios/iphoneos/Runner.app "$ipa_stage/Payload/"
ditto -c -k --keepParent "$ipa_stage/Payload" "$PWD/dsh-go-ios.ipa"
```

构建、模拟器或文件完整性检查都不能替代用户设备上的安装与功能验证。手机操控增强需要开发者连接、匹配签名的辅助程序和其他设备配置；推送、后台执行和插件媒体 `voice` 仍有上游文档所述限制。

## 署名与素材

代码许可证和第三方声明分别见 [LICENSE](../LICENSE) 和 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。原项目名称、标识和部分美术素材有独立条件，修改版发布前请阅读 [ASSETS.md](../ASSETS.md) 并遵守相应授权。

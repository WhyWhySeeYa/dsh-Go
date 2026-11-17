# dsh-go-ios

[English](README.en.md) · [iOS 使用与构建说明](docs/ios-fork.md)

这是面向 iPhone 的非官方维护分支，基于 [ccch1mneyyy/dsh-Go](https://github.com/ccch1mneyyy/dsh-Go)；原作者为 [ccch1mneyyy](https://github.com/ccch1mneyyy)。仓库保留上游共享源码和项目历史，iOS 相关维护在 `ios/special` 分支进行。本项目与 DeepSeek 官方无关联。

## 下载与安装

[查看本仓库 Releases](https://github.com/yeluoshuangyu/dsh-Go/releases)。公开版本会提供名为 `dsh-go-ios.ipa` 的文件；若发布页暂时没有文件，请按下方说明自行构建。IPA 为**未签名包**，需要使用自己的签名工具处理后再安装。签名时须正确处理包内框架、分享扩展和小组件；可用权限取决于证书和配置。

安装后可在「设置 → 本机引擎」安装和启动运行环境，并在 App 内配置自己的模型服务。API Key、签名证书和设备配对记录应留在自己的设备上，不要提交到仓库。

## 功能与验证状态

- 支持本机引擎和远程主机；模型请求需要连接用户配置的服务商。
- 可选 Linux 环境、文件和系统工具、分享扩展、小组件及手机操控由上游 iOS 工程提供；部分能力需要设备权限、兼容的签名或额外配置。
- 本分支的初始测试包已经在 iPhone 上安装并打开；模拟器覆盖了本机引擎、对话工具回合和 Linux guest。不同设备、模型服务和权限组合仍需分别验证。
- iOS 后台任务受系统调度限制；离开 App 后的远程推送提醒尚未完成。插件原生媒体的 `voice` 能力目前也未提供，具体边界见 [iOS 说明](app/ios/README.md)。

## 构建

- **GitHub Actions：**在 Actions 中运行 `iOS compile`，选择 `ios/special`，保持 `regression_only` 关闭。成功后下载 `ios-unsigned-ipa` 产物，解压可得到 `dsh-go-ios.ipa`。产物不是自动发布的 Release，默认保留 14 天。
- **Mac 本地构建：**需要 Xcode、Flutter 和项目 iOS 原生依赖。完整步骤见 [iOS 使用与构建说明](docs/ios-fork.md)；上游工程细节见 [app/ios/README.md](app/ios/README.md)。

GitHub Actions 在新 Fork 中可能需要先启用；使用托管构建机受账号配额与计费设置约束。

## 本分支的修改

本分支调整了中英文首页和 iOS 使用文档，并将 iOS 工作流的成功构建产物命名为 `dsh-go-ios.ipa`。当前 App 源码以所标注的上游提交为基础，后续功能改动应继续记录。

## 许可证与来源

代码许可见 [LICENSE](LICENSE)，第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。原项目名称、标识及部分美术素材有单独条件，修改版发布前请阅读 [ASSETS.md](ASSETS.md) 并遵守相应授权。原项目的完整介绍和其他平台说明见[上游仓库](https://github.com/ccch1mneyyy/dsh-Go)。

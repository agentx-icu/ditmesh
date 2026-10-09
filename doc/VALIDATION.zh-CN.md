[English](./VALIDATION.md)

# 验证记录 — 2026-10-08

已验证源码：`21224e60ddfe03a90db298b1ba82360e0b0d844e`。工具链：Flutter 3.41.9 / Dart 3.11.5。

## 自动化检查

| 检查 | 结果 |
|---|---|
| [Analyze](https://github.com/agentx-icu/ditmesh/actions/runs/37737114668) | 严格分析、源码守卫、包和应用测试通过。 |
| 应用测试 | 1344 通过；跳过 2 个按需图片导出测试。 |
| 包测试 | 聊天 269、API 79、核心 92、DSP 107、音频 I/O 124、训练 212、无线电工具 18 通过；DSP 跳过 2 个已有的首块噪声底测试。 |
| [原生库与平台构建](https://github.com/agentx-icu/ditmesh/actions/runs/37737115108) | 13 个必需任务全部通过：六个原生目标、六个应用构建和质量检查。 |
| 原生集成 | Linux 和两种 macOS 架构各 11 通过，跳过 1 个单独节点工作入口；三个目标的独立双进程测试均通过。 |
| 真实节点投递 | 双向单聊和群聊、加密资料重启、离线队列恰好投递一次、自动重新入群通过。 |
| 网络行为 | 局域网端口及双客户端连接、节点公钥校验、取消、探测隔离和实例保留通过。 |
| 打包回归 | macOS 运行时 9、打包/overlay/缓存 8、截图导入 19 项检查通过。 |
| [桌面 E2E](https://github.com/agentx-icu/ditmesh/actions/runs/37737114750) | macOS、Linux、Windows 的界面导航、持久化和全部 13 个场景的中英文截图通过。 |
| [视觉矩阵](https://github.com/agentx-icu/ditmesh/actions/runs/37737114693) | 38 个配置、76 张 PNG，覆盖十种语言、五种风格、浅深色及手机/桌面布局。 |

DSP 跳过项涉及极低音量首块噪声可能产生多余起始符号的问题。应用中的按需图片导出测试由截图及视觉工作流执行。

## 截图与安装包

[图库](screenshots/README.zh-CN.md)包含 **156 张截图**：13 个场景 × 中英文 × macOS/iPhone/iPad/Android/Linux/Windows。

| 目标 | 已验证安装包 |
|---|---|
| Android | APK、AAB |
| iOS | IPA |
| macOS | ARM64、Intel 各一组 PKG/ZIP |
| Linux | x86_64 DEB、RPM、tar.gz |
| Windows | x64 MSI、ZIP |

平台构建输出的 **12 个安装包**均已下载并检查产物完整性、SHA-256、归档完整性及内嵌原生库。两种 macOS 架构中的全部 Mach-O 均符合应用要求的最低版本 **13.0**。安装包检查还覆盖信号塔图标及十种语言的 Apple 权限说明。

复现命令见[测试指南](testing/TEST_PYRAMID.zh-CN.md)、[构建指南](operations/BUILD_AND_DEPLOY.zh-CN.md)和[截图指南](../tool/screenshots/README.zh-CN.md)。

## 聊天体验 worktree 的本地验证 — 2026-10-09

分支 `codex/chat-onboarding-playback` 基于 `71c9e95`，在 macOS ARM64 本地用 Flutter 3.41.9 / Dart 3.11.5 验证。上文 CI 与安装包证据属于其标注的历史发布版本。

| 检查 | 本地结果 |
|---|---|
| 后端 / 纯 Dart API | 后端 345 通过，跳过 5 个原生/工作节点按需入口；API 89 通过。下方单独原生运行覆盖原生按需入口。 |
| 应用 / Morse I/O | 应用 1576 通过，跳过 2 个按需图片导出测试；Morse I/O 143 通过。 |
| 原生集成 / 回调 | 12 项原生集成及 7 项回调检查通过，跳过 1 个独立工作节点入口；协调脚本启动的两个真实节点均通过。 |
| 真实节奏记录投递 | 单聊与 NGC 可完整重放的准确时序、相同文字不同标识、真实回执、加密重启、节奏记录持久队列及群重连通过。 |
| 评审回归 | 整数溢出边界、删除队列后的回执保留、旧空 ID 队列、晚到元数据不增加到达计数、等待协商时退出、重启/旧 hello/迟到 ACK、准备播放时的拍发优先级、接收失败/重试/恢复、清空及会话失效、待发布状态容量回收通过。 |
| 引导 / 投递界面 | 独立规格及质量复核通过；3 倍字号测试实际滚动两种头部并打开好友流程。 |
| 原始采集 / 播放器 | 独立规格复核通过；320×640 与 667×375 完整页面在 3 倍字号下拍发、发送、原始回放和暂停正常，投递按钮保持至少 48×48。 |
| 最终代码评审 | 独立 Codex 完整评审通过；布局、准备播放、接收持久化和失效容量问题均已修复，接收/传输最终复核的 10 项测试通过。 |
| 依赖完整性 / 源码检查 | 离线 bootstrap、固定子模块无修改通过；全部应用、包和工具的 `--fatal-infos` 分析零问题；复杂度、import 和 UI 文案守卫通过。 |
| 打包 / 导入检查 | 打包 8、macOS 运行时 9、截图导入 19 项通过。 |
| macOS 应用 | Debug 构建、冷启动导航测试及 4 项原生持久化测试通过；重新读取文件后，引导关闭状态和逐会话收听、原始节奏、循环词段偏好正确恢复。 |

固定 libsodium 1.0.20 的下载端点超时后，本次原生验证使用 Homebrew libsodium 1.0.21，仓库发布固定版本仍为 1.0.20。本地链接提示 Homebrew 动态库最低要求 macOS 26，因此本次运行不证明 macOS 13 的分发兼容性。本机 Command Line Tools 27 SDK 与所选链接器不兼容，打包测试和应用构建显式使用 Xcode 26.4 SDK。

最终真实节点证据目录：`/var/folders/cz/1y3n3_k12g5d1jmk7m425kr00000gn/T/ditmesh_real_peers_tqvectwq`。新节奏记录传输约定见[已实现 RFC](rfcs/2026-10-09-keyed-rhythm.zh-CN.md)。

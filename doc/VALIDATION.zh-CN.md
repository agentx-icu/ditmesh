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

## 模拟器 / 仿真器证据（2026-10-10）

**这是模拟器和仿真器证据，不是真机证据。** 本次没有连接任何手机或平板。以下内容都在同一台 Mac（Apple silicon）上，基于 `46691f8` 的分支 `agentx/simulator-validation` 运行，使用 Flutter 3.41.9 / Dart 3.11.5 的 Debug 构建。移动设备评审的真机矩阵仍然欠着。

| 目标 | 镜像 | 说明 |
|---|---|---|
| iOS 模拟器 | iPhone 17 Pro，iOS 26.4（23E254a），Xcode 26.4 | 灵动岛、主屏幕指示条。Tim2Tox 模拟器 XCFramework（arm64 + x86_64）由本树构建。 |
| Android 仿真器 | `sdk_gphone64_arm64`，Android 16 / API 36，Google APIs，构建号 BE2A.250530.026.F3，无窗口运行 | 手势导航，4 KB 页（未安装 16 KB 镜像，所以没有运行 P1）。arm64 `libtim2tox_ffi.so` 由本树用 NDK r28.2 构建。 |

聊天运行在**真实 Tox 后端**上：两台设备通过公共 DHT 互加好友并互发消息。`DITMESH_FAKE_BACKEND` 只用于已有的启动和持久化冒烟测试。远程控制探针 `apps/ditmesh/integration_test/device_matrix_test.dart` 驱动界面，并带时间戳记录生命周期、连接和消息事件；系统层操作由 `xcrun simctl` 和 `adb` 完成。`flutter test` 结束时会卸载应用，所以凡是重新启动时必须保留应用数据的场景，都改用正式 Debug 构建（`flutter build ios --simulator` / `flutter build apk`）。屏幕方向由应用请求（`SystemChrome.setPreferredOrientations`），不是旋转设备。当地时间约 01:16 起，另一个会话的 MorseCQ 测试也在使用这台 Android 仿真器，有时会占据前台；依赖前台的运行已重跑，或在事后核对。

| 项目 | 结果 |
|---|---|
| 启动 / 持久化冒烟（假后端） | `app_launch_test` 和 `persistence_test` 在两台设备上均为 5/5。 |
| 身份、DHT、好友（真实后端） | 上线耗时：iOS 12 秒，Android 8 至 9 秒。好友请求约 5 秒送达；约 40 秒内双方都显示在线；消息约 1.5 秒送达。 |
| L1，Android | 分别进入后台 10 秒、120 秒和 900 秒。离开前台约 10 秒后，Android 16 把应用的 UID 放进 `APP_BACKGROUND` 防火墙链（`dumpsys netpolicy`）。对端在 33 至 40 秒后看到好友离线；约 70 秒后进程被冻结（`ActivityManager: freezing`）。60 秒的 `mayBeDisconnected` 提示在第 60 秒触发。断网后发出的消息在恢复前台后 11 至 13 秒到达。**发现：** 在原生 API 36 上，60 秒的 Android 预算提示偏乐观，实际约 10 秒后就收不到消息了。仍需真机确认。 |
| L1，iOS | 无法测量：模拟器在后台 900 秒期间一直让应用运行（心跳不断，仍能收到消息）。已获得 `beginBackgroundTask`，30 秒的 `mayBeDisconnected` 提示按时触发。计时仍欠真机测量。 |
| L3 | Android：进入后台 5 秒后收到的消息，在 `ditmesh_messages`（重要性 4）上发出了通知。iOS：应用在后台时 SpringBoard 记录了角标更新；横幅没有目视检查。 |
| L9 | Android 后台 900 秒（已冻结）：依次出现 `mayBeDisconnected`、`foreground`、`reconnectRequested`；5 秒内从连接中恢复为在线。通过。 |
| L8、L5 | 未尝试（没有自动化点按通知）。仍欠。 |
| N1，Android | 关闭 Wi-Fi（切换到仿真蜂窝网络）再打开：没有中断，双向约 1.5 秒送达。飞行模式：无线电关闭后，自身状态仍显示 `online` 达 73 秒。退出飞行模式后：5.5 秒上线，24 秒后好友上线。 |
| N1，消息丢失（**缺陷，未修复**） | 对端悄然离开、发送方尚未察觉的约 10 秒内发出的消息，停在 `sent`，双方恢复在线后也不会送达（2 次复现 2 次）。toxcore 在好友离线时会丢弃未确认的消息，而 Tim2Tox 对一直没有送达回执的消息不会重发（`third_party/tim2tox/dart/lib/service/ffi_chat_service.dart`，`applyNativeDeliveryAck`）。需要 overlay 或上游修复。 |
| N2、N3、N7、N9 | 仅限真机（运营商 NAT64；VPN / 专用代理 / 认证门户；电量；iOS 本地网络隐私，模拟器不强制）。未尝试。 |
| A3、A5 | 仅限真机（音频路由、音频焦点）。未尝试。 |
| T1，带已拍发草稿旋转 | 两台设备切到横屏再切回：草稿保留，Flutter 错误为 0。安全区内边距：iOS 横屏左右各 62、底部 20；Android 横屏左侧 52。通过。 |
| T9，大字体 | iOS 辅助功能 XXXL（3.12×）和 Android 字体缩放 2.0：会话列表、会话和"我"页面的 Flutter 错误均为 0。输入区可滚动，历史区域变小。通过。 |
| T7、P5、P6、P7 | 未尝试：iOS 模拟器没有摄像头，仿真器需要配置虚拟场景二维码；没有运行 iPad（只用了一台模拟器）。 |
| P8 | Android 按应用设置语言：de-DE 和 zh-CN 即时生效，重置后回到系统语言。通过。 |
| P9 | 在 Android 设置里屏蔽 `ditmesh_messages` 后，"我"页面显示"已在系统设置中屏蔽"；解除屏蔽后回到应用，该行消失。通过。 |
| P11 | Android 16：返回键和左边缘手势都会关闭会话。在主界面根部按返回会结束 Activity（`detached`；进程保留，重新启动时开新任务），重新启动后能重新打开身份。在 D1 修复之后通过。 |
| D1 | iOS 向处于飞行模式的对端发消息（发件箱 1 条）。应用转入后台，1 秒后被终止。重新启动后重新连接。对端退出飞行模式后，接收方历史中恰好有一份，发送方该行为已送达。**修复（见下）后通过。** |
| D1，冷启动（**缺陷，已修复**） | 修复前，两个平台上已有身份的每一次冷启动都以 `identity_mismatch` 失败，重试也一直停在"离线"。引擎在登录之前比较 Tox 地址，而 Tim2Tox 只在登录后才报告自身地址。已在 `packages/ditmesh_chat/lib/src/engine/chat_engine.dart` 修复。新增的 `test/native_cold_start_test.dart`（needs-native）在子进程中重新打开身份：修复前失败，修复后通过。同一进程内重启会掩盖这个缺陷。 |
| D1，被杀后的草稿（**缺陷，未修复**） | iOS：发送后约 2 秒应用被杀，已发送的文字会作为会话草稿重新出现（2 次复现 2 次）；15 秒后被杀则不会出现。用户可能因此重复发送。原因未确认。 |
| 屏幕阅读器 | TalkBack（Android）：主界面的控件都有标签（"Chat, Tab 1 of 4"、"Contacts"、"Tap to reconnect"）。模拟器不提供 VoiceOver，仍欠真机检查。 |

修复的本地门禁：`ditmesh_chat` 的 386 个单元测试通过，原生测试 13 个通过、1 个跳过（使用本树构建的 macOS arm64 库）；真实节点测试通过（私聊、NGC、加密重启、持久队列、NGC 重新加入）；`tool/test_pyramid.sh --level gates` 通过。不带参数运行 `tool/build_ios_ffi.sh` 时，在 macOS 自带的 bash 3.2 下会失败（`set -u` 下的空数组），已修复。

仍欠真机：iOS 和厂商 Android 上的 L1 计时、L5、L8、N1 至 N3、N7、N9、A1、A3、A5、T2（手势区内按下）、T7、T8 复制反馈、P1（16 KB 设备），以及 iPad 上的 P5、P6、P7、VoiceOver。

[English](./README.md)

# 产品截图（跨平台）

一条命令在真实设备 / 桌面窗口里启动真实的应用，灌入演示数据，按中英文两种语言走完
所有产品场景，并把帧发布到仓库里的 `doc/screenshots/<platform>/<locale>/`。

截图固定使用清爽现代风格，与中英文 README 产品设计图一致。明暗模式默认浅色，可通过 `DITMESH_SHOT_THEME` 调整，不跟随设备保存的风格。

```bash
tool/screenshots/capture.sh                          # 默认 macOS，en + zh
tool/screenshots/capture.sh --platforms macos,ios,ipad,android
tool/screenshots/capture.sh --platforms android --device emulator-5554
tool/screenshots/capture.sh --locales zh --keep      # 只截一种语言，保留暂存目录
```

平台：`macos`、`linux`、`windows`（本机桌面）、`ios`（iPhone 模拟器）、`ipad`
（iPad 模拟器）、`android`（模拟器或真机）。设备按平台从 `flutter devices` 里自动
选择，也可用 `--device` 指定；Android 模拟器需事先启动。`ios` 和 `ipad` 产出 App Store
Connect 截图：不传 `--device` 时脚本自行启动 6.9 英寸 iPhone（iPhone 17 Pro Max，否则 16 Pro
Max：1320×2868）或 13 英寸 iPad（iPad Pro 13-inch M5，否则 M4：2064×2752）模拟器，按原生
像素比截取为 RGB PNG，`verify` 拒绝其他尺寸或带 alpha 通道的帧（`doc/release/APP_STORE.zh-CN.md` §10）。

发布其他主机的截图时，先下载同一 UI 版本成功 CI 的截图产物，再把产物中的
`screenshots` 目录传给 `--from`。该模式保留源目录，使用相同的完整性、大小和重复帧
校验后再发布，不会启动本机设备。
源目录和输出目录必须独立、互不嵌套；所选来源目录及 PNG 不允许使用符号链接。

```bash
tool/screenshots/capture.sh --platforms linux --from /path/to/artifact/screenshots
```

导入回归检查已接入 Analyze CI；本地运行
`python3 tool/screenshots/capture_import_test.py`，测试创建一次性 PNG 图片，不依赖已有截图画廊。

## 工作原理

整条流水线就是一个普通的 `integration_test`：

| 部件 | 文件 |
|---|---|
| 编排（选设备、`flutter drive`、校验、发布） | `tool/screenshots/capture.sh` |
| 场景 × 语言的真实 UI 走查 | `apps/ditmesh/integration_test/screenshots_test.dart` |
| 演示数据（主角、好友、QSO、通联网、好友请求、一周训练） | `apps/ditmesh/integration_test/support/seed_data.dart` |
| 导航与场景清单 `kScenes` | `apps/ditmesh/integration_test/support/scene_walk.dart` |
| Flutter 层截帧、窗口尺寸、主题钉死 | `apps/ditmesh/integration_test/support/shot_harness.dart` |
| 宿主侧：写出 PNG | `apps/ditmesh/test_driver/integration_test.dart` |

- **后端**：`--dart-define=DITMESH_FAKE_BACKEND=true`。不起 Tox 节点、不落盘；
  用 `package:ditmesh_chat_api/testing.dart` 的测试钩子（`addFakeFriend`、
  `receiveMessage`、`addFakeGroupMember` 等）在进程内灌数据，并用 `FileTrainerStore`
  准备聊天辅助练习所需的本地数据。
- **截帧**：应用包在一个 `RepaintBoundary` 里，每个场景从 Flutter 层 `toImage`。
  六种目标设备做法完全一样，不需要系统权限，也不会截到别的窗口（Flutter 3.41.9 的
  `integration_test` 只在 Android / iOS 有原生 `takeScreenshot`）。PNG 以 base64
  装进 `binding.reportData`，由 `flutter drive` 宿主写成
  `<platform>/<locale>/<scene>.png`。
- **桌面窗口**：harness 通过 `window_manager` 把真实窗口调整到
  `DITMESH_SHOT_WINDOW`（默认 `1280x800`）并居中。它设置的是含标题栏和边框的外框，
  所以 harness 会量出装饰尺寸再调整一次，直到 Flutter 视图本身就是请求的尺寸。macOS
  可能把超出可见区域的窗口钳小，此时接受较小尺寸并打日志；Linux 与 Windows 上尺寸
  不符即失败。
- **像素比**：桌面 1.0，iOS 用原生像素比（App Store 尺寸），Android `min(dpr, 2)`，可用
  `DITMESH_SHOT_PIXEL_RATIO` 覆盖。iOS 帧不带 alpha。
- **主题**：钉死为浅色（`DITMESH_SHOT_THEME=light|dark|system`），不跟随宿主外观。
- **参数校验**：参数格式错误或越界直接失败，不再静默退回默认值——窗口边长
  (0, 8192]、像素比 [0.25, 4]、主题只能是上述三个名字之一。
- **每帧都有断言**：截帧前走查会断言场景页面及其灌入内容（消息气泡、好友、翻译器
  输出），只点击可命中的目标。`pumpAndSettle` 超时（无尽动画）可以容忍，其它任何
  错误都让运行失败。
- **语言**：每种语言单独一遍，用各自的一份演示文案（中文帧里是中文名字和中文群名；
  电码正文保持 CW 缩写，那才是空中实际拍发的内容）。
- **发布门禁**：只有当该平台本机 `flutter drive` 或来源 CI 截图成功、每种语言的每个场景都存在、
  不小于 8 KiB、且没有两帧字节相同（用 `cmp` 确认，不只看校验和）时，才复制进
  `doc/screenshots/`。替换集先在目标旁边整套装好再整体换入；失败的平台不动仓库里的帧。
  暂存目录（`DITMESH_SHOT_STAGING`，否则是临时目录）在任何失败时都保留。`--locales`
  只给子集时只校验不发布（画廊必须始终包含所有语言），要发布局部集合用 `--out`。
  `--device` 给的 id 会核对是否属于所请求的平台。

`flutter test integration_test/screenshots_test.dart -d <device>` 会把同一套走查当作
普通 UI 测试跑（每个场景都必须渲染成功，无溢出、无缺失控件），帧被丢弃；
`tool/test_pyramid.sh --level e2e` 就是这么用它的。

## 场景

`welcome`、`create_identity`、`backup_wizard`（首次启动），然后基于已有身份：
`learn_home`、`stats`、`training_settings`、`receive_drill`、`send_practice`、
`chat_list`、`conversation`、`contacts`、`groups`、`group_conversation`、
`reference`、`translator`、`listen`、`me`。

新增场景：在 `scene_walk.dart` 里导航并 `shots.capture(tester, locale, 'name')`，把名字
加进那里的 `kScenes` 和 `capture.sh` 的 `SCENES`，再在 `doc/screenshots/README.md`
加一行。

## 坑（都是搭建时踩过的）

- 两次 `pumpWidget` 的根控件类型相同时，框架会**原地更新**旧元素而不是替换，
  `AppScope` 会继续用第一个后端。走查里每个应用根都带不同的 `key`。
- `pumpAndSettle` 遇到无限动画（光标闪烁、转圈）会抛异常；harness 的 `settle()` 会
  接住并继续。
- SnackBar 会盖住输入区的发送按钮 4 秒；合成点击落在提示条上，而 `flutter test` 只
  打印一条警告。要么 `ScaffoldMessenger.clearSnackBars()`，要么断言结果，绝不能只
  断言输入过的文本。
- Android 在没有 `libtim2tox_ffi.so` 时需要 `ditmeshAllowMissingFfi` 才能做纯 UI 构建；
  `capture.sh` 以 `ORG_GRADLE_PROJECT_ditmeshAllowMissingFfi=true` 导出它。还需要
  `JAVA_HOME` 指向 arm64 的 JDK——非交互式 ssh 不会加载设置它的 profile。
- 从 ssh 会话启动 macOS 窗口照样能渲染和截帧（Flutter 层不依赖合成器），但运行中
  不要抢焦点。

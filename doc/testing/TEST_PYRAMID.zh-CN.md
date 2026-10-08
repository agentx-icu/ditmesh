[English](./TEST_PYRAMID.md)

# 测试金字塔

自下而上四层。每一层在自己的层级上都便宜到可以每次推送前跑；最顶层需要设备，在
发布前于 macOS 上跑，并由按需触发的 `e2e.yml` 工作流执行。

```bash
tool/test_pyramid.sh                     # 全部层级，以本机桌面为设备
tool/test_pyramid.sh --level unit
tool/test_pyramid.sh --level e2e --device macos
```

| 层级 | 内容 | 位置 | 何时跑 | 数量（2026-10-03） |
|---|---|---|---|---|
| **门禁** | 分析器（零问题）、500 行复杂度、导入守卫、UI 字面量守卫 | `tool/*.dart` | 每次推送，CI `analyze.yml` | — |
| **单元** | 纯 Dart 引擎（`morse_core`、`morse_trainer`、`morse_dsp`、`radio_tools`）、聊天契约及内存假实现（`ditmesh_chat_api`）、Tim2Tox 传输层（`ditmesh_chat`，排除 `needs-native` smoke）、Flutter I/O 的 sink 与键控器（`morse_io`） | `packages/*/test` | 每次推送，CI `analyze.yml` | 543 |
| **控件** | 每个界面配假后端，在手机与桌面两种尺寸下：启动门、引导、聊天、学习、统计、手册、收听、通知、桌面外壳、多语言 | `apps/ditmesh/test` | 每次推送，CI `analyze.yml` | 867 |
| **进程内集成** | 按 `main()` 的方式接线的服务：`AppScope` → `AppServices` → 假实现；有 `libtim2tox_ffi` 时的无头 Tox smoke（`needs-native`，`native.yml`） | `apps/ditmesh/test/di`、`packages/ditmesh_chat/test/native*_test.dart` | 随控件层；原生工作流 | 计入上面 |
| **端到端（真实 UI）** | 在真实平台上运行应用自己的 `main()`，按新用户的点击路径驱动：引导 → 每个页签 → 一次练习 → 加好友并发一句 → 翻译器 → 我；外加 17 场景 × 2 语言的截图走查 | `apps/ditmesh/integration_test` | 发布前在 macOS；`e2e.yml` 按需；已在 macOS、iOS 模拟器、Android 模拟器验证（2026-09-30） | 7 个测试，每平台 34 帧 |

端到端层还运行 `integration_test/persistence_test.dart`：用临时文件和独立键验证真实应用支持目录存储、Keychain/Keystore，以及不使用缓存的原生偏好重新读取。每个发布平台都应运行；文件存储单测无法验证原生插件权限。

端到端层永远带 `--dart-define=DITMESH_FAKE_BACKEND=true`：内存后端不创建 Tox 身份、
不保存资料，每次启动都从引导页开始。会碰到设备的只有：启动测试跑的是真实 `main()`，
所以应用正常的 `settings.json`（语言、窗口位置）会写到 application-support 目录；截图走查
把灌入的进度和假资料写在一个临时目录里，测试结束时删除。

存储范围、问题清单与各平台验证边界见[持久化审计](./PERSISTENCE_AUDIT.zh-CN.md)。

## 每层的职责

- **单元**证明数学与协议：时序、译码、评分、SRS，以及控件层依赖的假服务行为。
- **控件**在密闭环境里快速证明每个界面的行为（整个应用约 40 秒），两种布局都覆盖。
  bug 的回归测试通常落在这一层。
- **进程内集成**证明接线而非界面：`AppScope` 提供了树里要读的东西，销毁顺序正确。
- **端到端**证明下面几层都做不到的事：真实平台上的插件初始化（窗口管理、托盘、通知、
  音频）、真实的 `main()`、真实的导航与文本输入，以及——通过截图——每个场景在两种
  语言下都无溢出地渲染。

## 只有顶层才发现的 bug（2026-09-30，首次运行）

1. **桌面上每次 debug 启动都在首帧崩溃**：`AppScope` 用普通 `Provider` 暴露
   `DesktopShellController`（一个 `ChangeNotifier`），provider 的 debug 检查拒绝这种
   用法。密闭测试传的是 `desktopShell: null`，release 构建又跳过断言，所以下面几层
   都看不到。回归测试现在在集成层（`test/di/app_scope_desktop_shell_test.dart`）。
2. **添加好友面板**在滑出时触发框架的语义断言（"invisible SemanticsNodes"），macOS 上
   一次、iOS 上又一次：Tox ID 输入框后缀槽里的 `Tooltip`，在面板收缩时被布局成负高度。
   现在移动端的扫码动作是输入框下方一个带文字的按钮（桌面保留提示行），任何平台的
   输入框都不再有后缀图标。
3. **正确率趋势图**把练习次数标成 `1 2 3 5 6 7`（分数步长四舍五入），坐标轴标题还压在
   最后一个刻度上。截图里看出来的；改为整数步长并把标题单独放一行。

## 添加测试

把测试放到能观察到该行为的最低一层。界面行为 → 控件层。接线或生命周期事实 →
`test/di`。任何需要插件或真实 `main()` 的 → `integration_test/`；如果是一个场景，
加进已有的走查而不是新建文件（见 `tool/screenshots/README.zh-CN.md`）。

[English](./README.md)

# 桌面 shell（`lib/desktop/`）

面向 macOS / Windows / Linux 的窗口管理与系统托盘。在 Android、iOS 和 web 上这里的一切都是空操作：
控制器仍然跟踪状态（未读数、关闭到托盘标志），但从不调用插件。

| 文件 | 职责 |
|------|------|
| `desktop_platform.dart` | `DesktopShellConfig`、`isDesktopTarget`、托盘资源路径 |
| `desktop_shell_controller.dart` | `DesktopShellController`（ChangeNotifier）：标题 + 未读数、显示/隐藏/切换、关闭到托盘、退出、窗口边界持久化、托盘菜单 |
| `init_desktop_shell.dart` | `initDesktopShell(config)`——在真实插件之上构建控制器 |
| `window_api.dart`、`tray_api.dart`、`screen_api.dart` | 控制器所依赖的、不含插件的接口 |
| `real/` | `WindowManagerApi`、`TrayManagerApi`、`ScreenRetrieverApi`——唯一导入插件的文件 |
| `testing/` | `FakeWindowApi`、`FakeTrayApi`、`FakeScreenApi`、`InMemoryKeyValueStore` |
| `window_bounds.dart` | 持久化的几何信息 + 纯函数的夹取规则 |
| `shortcuts.dart` | `ToggleSidetoneIntent`、`FocusSearchIntent`、`NewMessageIntent`、`desktopShortcutBindings()` |
| `key_value_store.dart` | 由编排器提供实现的两方法持久化接口 |

插件（固定在 `apps/ditmesh/pubspec.yaml`）：`window_manager ^0.5.2`、`tray_manager ^0.5.3`、
`screen_retriever ^0.2.2`。三者都只声明 `linux` / `macos` / `windows` 的插件实现，
移动端没有任何实现，因此它们在移动端构建中只是惰性的 Dart 代码。

## 从 `main.dart` 接线

`main()` 只在桌面目标上构建 shell，使用与 App 其余部分相同的设置存储
（`DesktopStoreAdapter` 包装 `<application support>/settings.json`）：

```dart
DesktopShellController? desktopShell;
if (isDesktopTarget(defaultTargetPlatform)) {
  desktopShell = await initDesktopShell(
    DesktopShellConfig(
      store: DesktopStoreAdapter(settingsStore),
      appName: currentS().appName,               // product name, never translated
      log: kDebugMode ? debugPrint : null,
    ),
  );
}
```

未提供 `log` sink 时保持静默；`main()` 仅在 debug 构建启用原始 shell 诊断。

`initDesktopShell` 必须在 `WidgetsFlutterBinding.ensureInitialized()` **之后**、`runApp` **之前**运行：
`window_manager` 以隐藏状态创建窗口，shell 恢复持久化的边界（夹取到当前显示器范围内），
然后才显示窗口，因此没有可见的跳动。

控制器交给 `DitmeshApp`，再由 `AppServices` 接到会话上：

```dart
shell.addBeforeQuitListener(_beforeQuit);       // flush durable stores, disconnect
shell.updateStrings(strings.s);                 // persisted language, then every change
shell.setUnreadCount(total);                    // "(3) DitMesh" title, tray tooltip, macOS badge
```

`setCloseToTray(value)` 是设置开关（会持久化）；`showWindow()` 恢复被隐藏的窗口。

`AppShell` 已安装 `shortcuts.dart` 的搜索和新消息绑定。macOS 的 Cmd+K（Windows/Linux 的
Ctrl+K）选中聊天页并聚焦现有会话搜索，不清空筛选词；Cmd/Ctrl+N 选中聊天页并打开现有联系人
路由以选择收件人，按住按键不会堆叠联系人页。搜索图标和联系人按钮的本地化提示展示平台快捷键。
命令只作用于露出的外壳，不截获已聚焦文本编辑器、IME 组字、对话框或覆盖路由；没有系统级键盘监听。

`ToggleSidetoneIntent` 与 Cmd/Ctrl+Shift+M 仍只是定义：App 没有共享声音所有者，外壳未安装该绑定。
Flutter 快捷键接线不会填充 iPadOS 26 原生菜单栏。原生菜单覆盖、实体键盘/触控板、非美式布局和
全键盘控制仍需单独界定实现或补设备证据。

## 行为

- **窗口**：最小 360×640（类手机的竖屏仍可用；布局是响应式的），默认 1100×760 并在主显示器上居中，
  显示器更小时两者都缩到工作区大小（小面板上 Windows 200 % 缩放）。持久化的边界恢复到包含窗口中心的
  那块显示器上；若该显示器已不存在则使用主显示器。
- **关闭**：`setPreventClose(true)` 始终开启，因此关闭请求会到达控制器。关闭到托盘默认关闭，可在“我”中设置；开启**且**托盘可用时
  窗口隐藏；否则（设置关闭，或没有托盘宿主）shell 持久化边界、运行 `onBeforeQuit`、销毁托盘和窗口——
  然后 runner 退出。从托盘菜单退出永远是真正的退出。
- **托盘**：每个平台各自的图标，提示文本 = App 名称（+ " — N 未读"），菜单为
  显示/隐藏 · 退出；仅传入 `onToggleSound` 音频所有者时显示声音菜单。在宿主传递点击的平台上（macOS、Windows）
  左键切换窗口。每个托盘调用都被容错处理：没有托盘则禁用托盘，缺少方法（Linux 的提示文本）只记录一次日志。
- **语言**：菜单标签、提示文本和未读窗口标题都是 `S` 字符串（`lib/l10n/app_*.arb` 中的 `desktop*` 键）；
  产品名（`DesktopShellConfig.appName`）是占位符，从不翻译。控制器在 `main()` 中构建，那时 `LocaleController`
  还不存在，所以它先使用 `currentS()`（平台语言，或 `strings:` 参数）；`AppServices` 在启动时以持久化的选择、
  之后在每次语言切换时（`StringsResolver`）调用 `updateStrings(S)`，重新设置标题并在排队的托盘更新之后重建托盘。
  快捷键标签（`shortcutLabel`）只随平台变化（`⌘K` / `Ctrl+K`），不随语言变化。
- **持久化键**：`desktop.windowBounds`（JSON）、`desktop.closeToTray`、`desktop.soundEnabled`。

## 各操作系统注意事项

- **Linux**：`tray_manager` 构建时需要 `libayatana-appindicator3-dev`（或旧的
  `libappindicator3-dev`），运行时需要一个 StatusNotifier 宿主（GNOME 需要 AppIndicator 扩展；
  KDE / XFCE / Cinnamon 开箱即用）。隐藏前通过有超时的 `gdbus` 检查 `IsStatusNotifierHostRegistered`；无宿主时以无托盘模式运行：
  关闭即退出而不是隐藏。AppIndicator 不传递左键点击也不支持提示文本；上下文菜单是原生的（右键）。
- **macOS**：图标是*模板*图像（`tray_template_36.png`，黑色 + alpha），以 `isTemplate: true` 传入，
  因此不能带任何颜色。未读数作为状态栏项的标题显示在图标旁边。runner 禁用最后窗口自动终止，以等待关闭检查点完成；
  显式退出仍通过 `NSApp.terminate` 结束进程，Dock 重开恢复并聚焦现有窗口。
- **Windows**：托盘需要真正的 `.ico`（`tray_icon.ico`，16/20/24/32/40/48 px 帧，对应 100–300% DPI 的小图标尺寸）。边界以逻辑像素表示；
  `window_manager` 用设备像素比换算，因此两次会话之间的 DPI 变化由夹取处理，而不是由我们处理。

## 重新生成图标

```bash
dart run tool/gen_tray_icons.dart     # from the repository root
```

使用 `package:image`（App 的开发依赖）写出 `apps/ditmesh/assets/tray/tray_template_{16,22,32,36,64}.png`、
`tray_icon_{16,22,32,36,64}.png` 和 `tray_icon.ico`。

`DesktopInstance.acquire()` 在偏好和后端打开前运行。操作系统锁覆盖整个 support 根目录，
持有至进程结束；独立的回环激活 sidecar 允许第二个进程唤起原窗口。最小化、最大化和
全屏切换期间保留普通窗口边界。

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

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'desktop/desktop.dart';

/// shared_preferences behind the shell's two-method store.
class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore(this._prefs);
  final SharedPreferences _prefs;
  @override
  Future<String?> get(String key) async => _prefs.getString(key);
  @override
  Future<void> set(String key, String value) => _prefs.setString(key, value);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final desktopShell = await initDesktopShell(
    DesktopShellConfig(
      store: PrefsKeyValueStore(prefs),
      appName: 'DitMesh',
      closeToTray: true,
      onToggleSound: (enabled) { /* hand to the sidetone owner */ },
      onBeforeQuit: () async { /* account teardown, bounded by a timeout */ },
    ),
  );
  runApp(
    ChangeNotifierProvider.value(value: desktopShell, child: const DitmeshApp()),
  );
}
```

`initDesktopShell` 必须在 `WidgetsFlutterBinding.ensureInitialized()` **之后**、`runApp` **之前**运行：
`window_manager` 以隐藏状态创建窗口，shell 恢复持久化的边界（夹取到当前显示器范围内），
然后才显示窗口，因此没有可见的跳动。`initDesktopShell` 返回控制器；把它当作 `Future<void>` 来 await
也可以。

然后，从未读状态所在之处：

```dart
desktopShell.setUnreadCount(total);          // "(3) DitMesh" title, tray tooltip, macOS badge
await desktopShell.setCloseToTray(value);    // settings toggle; persisted
await desktopShell.showWindow();             // e.g. on an incoming call
```

快捷键 intent 只是纯定义。要激活它们：

```dart
Shortcuts(
  shortcuts: desktopShortcutBindings(),      // Cmd/Ctrl+K, +N, +M
  child: Actions(
    actions: {
      FocusSearchIntent: CallbackAction<FocusSearchIntent>(onInvoke: (_) => ...),
      NewMessageIntent: CallbackAction<NewMessageIntent>(onInvoke: (_) => ...),
      ToggleSidetoneIntent: CallbackAction<ToggleSidetoneIntent>(onInvoke: (_) => ...),
    },
    child: child,
  ),
)
```

## 行为

- **窗口**：最小 360×640（类手机的竖屏仍可用；布局是响应式的），默认 1100×760 并在主显示器上居中，
  显示器更小时两者都缩到工作区大小（小面板上 Windows 200 % 缩放）。持久化的边界恢复到包含窗口中心的
  那块显示器上；若该显示器已不存在则使用主显示器。
- **关闭**：`setPreventClose(true)` 始终开启，因此关闭请求会到达控制器。关闭到托盘开启**且**托盘可用时
  窗口隐藏；否则（设置关闭，或没有托盘宿主）shell 持久化边界、运行 `onBeforeQuit`、销毁托盘和窗口——
  然后 runner 退出。从托盘菜单退出永远是真正的退出。
- **托盘**：每个平台各自的图标，提示文本 = App 名称（+ " — N 未读"），菜单为
  显示/隐藏 · 声音开/关（复选框，占位回调）· 退出。在宿主传递点击的平台上（macOS、Windows）
  左键切换窗口。每个托盘调用都被容错处理：没有托盘则禁用托盘，缺少方法（Linux 的提示文本）只记录一次日志。
- **持久化键**：`desktop.windowBounds`（JSON）、`desktop.closeToTray`。

## 各操作系统注意事项

- **Linux**：`tray_manager` 构建时需要 `libayatana-appindicator3-dev`（或旧的
  `libappindicator3-dev`），运行时需要一个 StatusNotifier 宿主（GNOME 需要 AppIndicator 扩展；
  KDE / XFCE / Cinnamon 开箱即用）。没有宿主时第一个托盘调用会抛出异常，shell 以无托盘模式运行：
  关闭即退出而不是隐藏。AppIndicator 不传递左键点击也不支持提示文本；上下文菜单是原生的（右键）。
- **macOS**：图标是*模板*图像（`tray_template_32.png`，黑色 + alpha），以 `isTemplate: true` 传入，
  因此不能带任何颜色。未读数作为状态栏项的标题显示在图标旁边。关闭最后一个窗口通常会终止 App
  （`applicationShouldTerminateAfterLastWindowClosed`）；runner 的默认值没问题，因为关闭在到达 AppKit
  之前就已被拦截。
- **Windows**：托盘需要真正的 `.ico`（`tray_icon.ico`，16/20/24/32/40/48 px 帧，对应 100–300% DPI 的小图标尺寸）。边界以逻辑像素表示；
  `window_manager` 用设备像素比换算，因此两次会话之间的 DPI 变化由夹取处理，而不是由我们处理。

## 重新生成图标

```bash
dart run tool/gen_tray_icons.dart     # from the repository root
```

使用 `package:image`（App 的开发依赖）写出 `apps/ditmesh/assets/tray/tray_template_{16,22,32}.png`、
`tray_icon_{16,22,32}.png` 和 `tray_icon.ico`。

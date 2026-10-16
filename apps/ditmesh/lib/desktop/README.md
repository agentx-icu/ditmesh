[简体中文](./README.zh-CN.md)

# Desktop shell (`lib/desktop/`)

Window management and system tray for macOS / Windows / Linux. On Android,
iOS and web everything here is a no-op: the controller still tracks state
(unread count, close-to-tray flag) but never calls a plugin.

| File | Role |
|------|------|
| `desktop_platform.dart` | `DesktopShellConfig`, `isDesktopTarget`, tray asset paths |
| `desktop_shell_controller.dart` | `DesktopShellController` (ChangeNotifier): title + unread, show/hide/toggle, close-to-tray, quit, bounds persistence, tray menu |
| `init_desktop_shell.dart` | `initDesktopShell(config)` — builds the controller on the real plugins |
| `window_api.dart`, `tray_api.dart`, `screen_api.dart` | plugin-free interfaces the controller talks to |
| `real/` | `WindowManagerApi`, `TrayManagerApi`, `ScreenRetrieverApi` — the only files importing the plugins |
| `testing/` | `FakeWindowApi`, `FakeTrayApi`, `FakeScreenApi`, `InMemoryKeyValueStore` |
| `window_bounds.dart` | persisted geometry + pure clamping rules |
| `shortcuts.dart` | `ToggleSidetoneIntent`, `FocusSearchIntent`, `NewMessageIntent`, `desktopShortcutBindings()` |
| `key_value_store.dart` | two-method persistence interface the orchestrator backs |

Plugins (pinned in `apps/ditmesh/pubspec.yaml`): `window_manager ^0.5.2`,
`tray_manager ^0.5.3`, `screen_retriever ^0.2.2`. All three declare
`linux` / `macos` / `windows` plugin implementations and nothing for mobile,
so they compile into mobile builds as inert Dart.

## Wiring from `main.dart`

`main()` builds the shell on desktop targets only, over the same settings
store the rest of the app uses (`DesktopStoreAdapter` over
`<application support>/settings.json`):

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

`initDesktopShell` must run **after** `WidgetsFlutterBinding.ensureInitialized()`
and **before** `runApp`: `window_manager` creates the window hidden, the shell
restores the persisted bounds (clamped to the current displays) and only then
shows it, so there is no visible jump.

The controller is handed to `DitmeshApp`; `AppServices` then wires it to the
session:

```dart
shell.addBeforeQuitListener(_beforeQuit);       // flush durable stores, disconnect
shell.updateStrings(strings.s);                 // persisted language, then every change
shell.setUnreadCount(total);                    // "(3) DitMesh" title, tray tooltip, macOS badge
```

`setCloseToTray(value)` is the settings toggle (persisted); `showWindow()`
restores a hidden window.

`shortcuts.dart` defines `desktopShortcutBindings()` (Cmd/Ctrl+K search, +N
new message, +M sidetone) as pure intents. The app does not install them yet;
to activate them, wrap the shell in `Shortcuts(shortcuts:
desktopShortcutBindings(), child: Actions(actions: {...}, child: ...))`.

## Behaviour

- **Window**: minimum 360×640 (phone-like portrait stays usable; the layout
  is responsive), default 1100×760 centred on the primary display, both
  shrunk to the work area when the display is smaller (Windows 200 % on a
  small panel). Persisted bounds are restored onto the display that contains
  the window's centre; if that display is gone the primary is used.
- **Close**: `setPreventClose(true)` is always on, so a close request reaches
  the controller. With close-to-tray on **and** a working tray the window
  hides; otherwise (setting off, or no tray host) the shell persists bounds,
  runs `onBeforeQuit`, destroys the tray and the window — the runner then
  exits. Quit from the tray menu is always a real exit.
- **Tray**: icon per platform, tooltip = app name (+ " — N unread messages"),
  menu Show/Hide · Sound on/off · Quit. The sound checkbox is persisted, but
  `main()` passes no `onToggleSound`, so it does not yet change any app sound. Left
  click toggles the window where the host delivers clicks (macOS, Windows).
  Every tray call is tolerated: a missing tray disables the tray, a missing
  method (Linux tooltip) is logged once.
- **Language**: menu labels, tooltip and the unread window title are `S`
  strings (`desktop*` keys in `lib/l10n/app_*.arb`); the product name
  (`DesktopShellConfig.appName`) is a placeholder and never translated. The
  controller is built in `main()` before the `LocaleController` exists, so it
  starts from `currentS()` (platform locale, or the `strings:` argument) and
  `AppServices` calls `updateStrings(S)` with the persisted choice on start
  and on every language change (`StringsResolver`); that re-sets the title
  and rebuilds the tray behind any queued tray update. Keyboard shortcut
  labels (`shortcutLabel`) stay platform-specific (`⌘K` / `Ctrl+K`), not
  language-specific.
- **Persistence keys**: `desktop.windowBounds` (JSON), `desktop.closeToTray`,
  `desktop.soundEnabled`.

## Per-OS caveats

- **Linux**: `tray_manager` needs `libayatana-appindicator3-dev` (or the
  legacy `libappindicator3-dev`) at build time and a StatusNotifier host at
  run time (GNOME needs the AppIndicator extension; KDE / XFCE / Cinnamon work
  out of the box). Without a host the first tray call throws and the shell
  runs tray-less: close then quits instead of hiding. AppIndicator delivers no
  left click and no tooltip; the context menu is native (right click).
- **macOS**: the icon is a *template* image (`tray_template_32.png`, black +
  alpha) and is passed with `isTemplate: true`, so it must carry no colour.
  The unread count is shown as the status item's title next to the icon.
  Closing the last window would normally terminate the app
  (`applicationShouldTerminateAfterLastWindowClosed`); the runner's default
  is fine because close is intercepted before it reaches AppKit.
- **Windows**: the tray needs a real `.ico` (`tray_icon.ico`, 16/20/24/32/40/48 px
  frames, the small-icon sizes of 100–300 % DPI). Bounds are logical pixels; `window_manager` converts using the
  device pixel ratio, so a DPI change between sessions is handled by the
  clamp, not by us.

## Regenerating icons

```bash
dart run tool/gen_tray_icons.dart     # from the repository root
```

Writes `apps/ditmesh/assets/tray/tray_template_{16,22,32}.png`,
`tray_icon_{16,22,32}.png` and `tray_icon.ico` using `package:image`
(dev dependency of the app).

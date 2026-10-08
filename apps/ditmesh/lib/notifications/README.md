[简体中文](./README.zh-CN.md)

# Notifications, badge and background handling

`lib/notifications/` posts OS notifications for chat events and keeps the
unread badge in step with the conversation list; `lib/lifecycle/` tracks
foreground/background and drives the mobile background policy. Both talk to
the backend only through the `ditmesh_chat_api` contract and to the plugins
only through two interfaces (`LocalNotificationsApi`, `BadgeApi`) with
recording fakes under `testing/`.

## Plugins

| Package | Version | Why this one |
|---|---|---|
| `flutter_local_notifications` | `^22.3.1` (Flutter ≥ 3.38.1, Dart ≥ 3.10) | Endorsed federated implementations for **all five** targets: Android/iOS/macOS in the main package, `flutter_local_notifications_linux` 8.0.1 (D-Bus), `flutter_local_notifications_windows` 3.1.1 (WinRT toasts over FFI). |
| `app_badge_plus` | `^1.3.5` (Flutter ≥ 3.32) | Android / iOS / macOS badge. No Linux or Windows implementation; `AppBadgePlusApi.isSupported()` returns false there without touching a channel. |

Evidence: pub.dev package metadata read on 2026-09-30 (`flutter.plugin.platforms`
lists `windows: {default_package: flutter_local_notifications_windows}` and
`linux: {default_package: flutter_local_notifications_linux}`; `app_badge_plus`
lists android/ios/macos only). Plugin READMEs are in the pub cache.

## Per-platform behaviour

| | Android | iOS | macOS | Windows | Linux |
|---|---|---|---|---|---|
| OS notification backend | NotificationCompat, 3 channels (`ditmesh_messages`, `ditmesh_friend_requests`, `ditmesh_group_invites`) | UNUserNotificationCenter | UNUserNotificationCenter | WinRT toast (`flutter_local_notifications_windows`, AUMID `icu.agentx.ditmesh`, fixed CLSID) | `org.freedesktop.Notifications` over D-Bus |
| Runtime permission | `POST_NOTIFICATIONS` on 13+: asked once, in the foreground, when the plugin is ready (or on the next resume if the app was in the background then); a post never prompts, it checks silently (`isPermissionGranted`) and drops the banner when not granted. `ensurePermission()` asks on demand | Alert + badge + sound authorization (same rules) | Same as iOS | None | None |
| Shown while app is in the foreground | Yes (only for conversations not on screen) | Yes — `presentBanner/List` on | Yes | Yes | Yes |
| Grouping per conversation | `groupKey` + `InboxStyle` (last 5 lines, "N new messages" summary) | `threadIdentifier` stack | `threadIdentifier` stack | None (one toast per conversation, replaced by id) | None (replaced by id) |
| Tap → `takePendingTap()` (signalled on `tapTargets`) | Yes, incl. cold start (`getNotificationAppLaunchDetails`; a tap stays pending until the shell takes it - startup gate, unlock) | Yes, incl. cold start | Yes | Yes while running; **cold-start payload only when packaged as MSIX** | Yes while running |
| Cancel on open / read | Yes | Yes | Yes | **No-op unless MSIX-packaged** (plugin limitation, README) | Yes |
| Unread badge | Launcher-dependent (Samsung, Xiaomi/HyperOS, Huawei, OPPO, vivo, Sony, HTC…; stock Pixel shows a dot only) | Exact | Exact (Dock) | Not supported → no-op | Not supported → no-op |
| Sound | Channel default, `playSound` per prefs | `presentSound` per prefs | Same | Default toast sound; `WindowsNotificationAudio.silent()` when off | `suppressSound` when off |
| Background budget (`AppLifecycleCoordinator`) | 60 s hint (OEM-dependent; Doze / vendor savers freeze sooner or later) | 30 s (no `voip`; `audio` only while playback runs) | none — never suspended | none | none |
| Reconnect on resume | `IdentityService.connect()` after any background period | Same | Same (after `hidden`, e.g. minimised) | Same | Same |

Connection state never produces an OS notification. `ConnectionBannerPolicy`
exposes one `ValueListenable<bool>` that turns on after two continuous minutes
of not-online (`connecting` counts) and off the moment the node is online; the
shell renders it as an in-app banner.

### Windows: OS toasts vs. in-app fallback

Windows is supported natively by `flutter_local_notifications` ≥ 18 through the
endorsed FFI package, so no in-app fallback is needed for *showing*
notifications. Two limitations remain for an unpackaged (`flutter build
windows` .exe) app, straight from the plugin README:

- `cancel()` / `getActiveNotifications()` do nothing — toasts stay in the
  Action Center until the user dismisses them (opening the conversation does
  not clear them);
- the cold-start payload is unavailable.

Both go away once the app ships as MSIX (`package:msix`). Until then the
behaviour is "notification appears; tapping it while the app runs opens the
conversation". `AppBadgePlusApi` is a no-op on Windows (no taskbar overlay
support in the plugin).

## Manifest / plist changes

### `android/app/src/main/AndroidManifest.xml`

Added at `<manifest>` level:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

`flutter_local_notifications` ≥ 16 already merges both from its own manifest;
they are repeated so the runtime permission the app asks for is visible in the
app's manifest. **No** `ScheduledNotificationReceiver` /
`ScheduledNotificationBootReceiver` (they exist for *scheduled* notifications;
DitMesh only posts live ones from the Tox poll loop) and **no**
`ActionBroadcastReceiver` (no notification actions). No foreground service:
DitMesh does not ship toxee's `ToxPollingService`; if the product later wants
Android background polling, that is a separate native service plus
`FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_DATA_SYNC` permissions.

### `ios/Runner/Info.plist`

Declares **no** `UIBackgroundModes` (removed `audio` on 2026-10-02).

- **Not `voip`**: DitMesh has no ToxAV; declaring `voip` without a VoIP feature
  is not honest and App Review rejects it (plan §5.6/§7).
- **Not `audio`**: `SidetoneSink` stops its voice whenever the app is
  backgrounded and nothing else plays there, so the mode would be unused
  (App Review guideline 2.5.4). Re-add it only together with a feature that
  really keeps playing in the background (e.g. a training session that
  continues with the screen off), and make sure that feature's audio session
  is `.playback`.
- The ~30 s budget comes from `AppLifecycleCoordinator` holding a
  `beginBackgroundTask` assertion (`lib/lifecycle/background_task_api.dart`
  ↔ the `icu.agentx.ditmesh/background_task` channel in `AppDelegate.swift`)
  from background until resume or the end of the budget. Without it iOS
  freezes the app ~5 s in, cutting the durability flush short.
- **`fetch` deliberately not declared**: `BGAppRefreshTask` needs a native
  handler and `BGTaskSchedulerPermittedIdentifiers`; toxee has one, DitMesh
  does not yet. Add both together or neither.

### macOS

No plist or entitlement change needed for `UNUserNotificationCenter`; the
plugin installs its own delegate. Notifications require a signed bundle
(`flutter run -d macos` ad-hoc signing is enough for local testing).

## Required follow-ups outside this module's ownership

1. **`android/app/build.gradle.kts` — core library desugaring** (hard build
   requirement of `flutter_local_notifications` ≥ 10):
   ```kotlin
   android {
       compileOptions {
           isCoreLibraryDesugaringEnabled = true
           sourceCompatibility = JavaVersion.VERSION_17
           targetCompatibility = JavaVersion.VERSION_17
       }
   }
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   }
   ```
   AGP is already 8.11.1 (matches the plugin's minimum).
2. **`ios/Runner/AppDelegate.swift`** — the iOS plugin relies on the app
   delegate forwarding notification-center callbacks (the macOS plugin does
   not). Add inside `didFinishLaunchingWithOptions`, before `super`:
   ```swift
   UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
   ```
   Without it, tap callbacks and foreground presentation do not work on iOS.
3. **Wiring in `main.dart` / `AppScope`** (see below).
4. **Prefs persistence**: `NotificationPrefs.toJson()` / `fromJson()` are
   ready; the owner of app settings should load/save them.

## Wiring snippet (orchestrator)

```dart
// In AppScope (once per session, after the identity is ready):
final lifecycle = AppLifecycleCoordinator(identity: identity)..attach();
final prefs = NotificationPrefs.fromJson(settings.notificationsJson);
final center = NotificationCenter(
  chat: chat,
  notifications: FlutterLocalNotificationsApi(),
  badge: AppBadgePlusApi(),
  prefs: prefs,
  isForeground: lifecycle.isForeground,
);
final banner = ConnectionBannerPolicy(identity: identity)..start();
unawaited(center.start());

// Route taps (AppShell): the centre keeps the newest tap until the router
// takes it, so a cold-start tap or one that came while the unlock screen
// showed is not lost. AppShell drains it after its first frame and on every
// signal, then hands conversations to ChatPage / GroupsPage via ShellRouter
// (inline pane on wide layouts, a route on phones; an already open
// conversation is reused), friend requests to contacts, invites to Groups.
final tapSub = center.tapTargets.listen((_) => route(center.takePendingTap()));
WidgetsBinding.instance.addPostFrameCallback((_) => route(center.takePendingTap()));

// ConversationScreen (ConversationAttention): claim while the user actually
// looks at it (visible tab, route on top, app in the foreground) with an
// owner token, release otherwise. Messages are marked read only then.
center.claimActiveConversation(widget.target.id, owner);
center.releaseActiveConversation(owner);

// Banner: ValueListenableBuilder(valueListenable: banner.offlineBannerVisible, ...)
// with context.s.shellOfflineBanner and a Reconnect action calling
// StartupController.reconnect(). The policy exposes state only, no text.

// Me page: NotificationSettingsSection — prefs.enabled, one "message
// content" switch driving both showText and showPattern (a pattern reveals
// the text too), and "Allow notifications" calling center.ensurePermission();
// per-conversation "Mute" in the conversation menu via prefs.setMuted(id, v).

// Dispose order: tapSub.cancel(); center.dispose(); banner.dispose();
// lifecycle.dispose(); then the services.
```

## Language

All user-visible text (titles, "Friend request from {name}", "Invite to
{group}", the "N new messages" inbox summary, Android channel names and
descriptions, the Linux `Open` action) comes from the generated `S` class
(`notification*` keys in `lib/l10n/app_*.arb`); there is no English const
class any more. Nothing here has a `BuildContext`, so the text is resolved
through an `S Function()`:

- `NotificationCenter` / `NotificationComposer` / `FlutterLocalNotificationsApi`
  take `strings:` and default to `currentS()` (`lib/i18n/current_strings.dart`),
  which follows the app's `LocaleController`. `AppServices` passes
  `() => strings.s` from its `StringsResolver`, tests pass
  `() => lookupS(const Locale('zh'))`.
- The function is called **at post time**, so a language switch applies to the
  next notification. Banners already in the shade / Action Center keep the
  language they were posted in; they are replaced (same id) by the next
  message for that conversation anyway.
- **Android channel names follow the language** (2026-09-30): `initialize`
  creates the three channels, and `LocalNotificationsApi.refreshStrings()`
  re-creates them with the current strings on every language change
  (`AppServices` listens to the `StringsResolver` and forwards through
  `NotificationCenter.refreshStrings()`; a change that lands while the
  channels are still being written is replayed once `initialize` finishes).
  Re-creating a channel with the same id updates its name/description only:
  importance and sound stay what the first creation set (Android rule).
- Windows registers `windowsAppName` (`Ditmesh`, the product name) with the
  toast platform; product names are never translated.
- `AppLifecycleCoordinator` / `LifecycleHint` and `ConnectionBannerPolicy`
  expose enums and booleans only; their text lives in the shell widgets.

## What needs a device to verify

- Android 13+: permission dialog appears once; denial suppresses posting;
  inbox grouping renders; badge count on Samsung / Xiaomi launchers; dot only
  on Pixel. Android 8–12: channels appear in Settings, no dialog.
- iOS: authorization prompt; banner shown in foreground for a non-open
  conversation; thread stacking on the lock screen; badge; tap on a cold-start
  notification opens the conversation (needs the AppDelegate line above);
  app suspended ~30 s after backgrounding without playback, `mayBeDisconnected`
  hint and reconnect on resume; whether an active Morse playback keeps the
  socket alive under the `audio` mode.
- macOS: authorization prompt (signed bundle), Dock badge, `hidden` on
  minimise → notifications while minimised.
- Windows: toast appears for an unpackaged build; tap while running opens the
  conversation; confirm the MSIX limitations above; sound toggle.
- Linux (GNOME / KDE): D-Bus notification, `Open` action, sound suppression.

## Tests (files written, not run in this round)

`test/notifications/`: `notification_center_test.dart` (background posts
text + pattern; active conversation open → none; muted → none; badge follows
unread; friend requests / group invites; taps; permission; inbox grouping;
Linux/unsupported gating), `app_lifecycle_coordinator_test.dart` (fake-clock
budget, resume reconnect, desktop no-countdown, hooks),
`connection_banner_policy_test.dart`, `notification_payload_test.dart`,
`notification_prefs_test.dart`.

[English](./README.md)

# 通知、角标与后台处理

`lib/notifications/` 为聊天事件发送操作系统通知，并让未读角标与会话列表保持同步；
`lib/lifecycle/` 跟踪前台/后台并驱动移动端后台策略。两者都只通过 `ditmesh_chat_api` 契约与后端对话，
只通过两个接口（`LocalNotificationsApi`、`BadgeApi`）与插件对话，`testing/` 下有记录式假实现。

## 插件

| 包 | 版本 | 为什么选它 |
|---|---|---|
| `flutter_local_notifications` | `^22.3.1`（Flutter ≥ 3.38.1，Dart ≥ 3.10） | **全部五个**目标平台都有官方背书的联合实现：Android/iOS/macOS 在主包内，`flutter_local_notifications_linux` 8.0.1（D-Bus），`flutter_local_notifications_windows` 3.1.1（通过 FFI 的 WinRT toast）。 |
| `app_badge_plus` | `^1.3.5`（Flutter ≥ 3.32） | Android / iOS / macOS 角标。没有 Linux 或 Windows 实现；`AppBadgePlusApi.isSupported()` 在那里返回 false，不触碰任何 channel。 |

依据：2026-09-30 读取的 pub.dev 包元数据（`flutter.plugin.platforms` 列出
`windows: {default_package: flutter_local_notifications_windows}` 和
`linux: {default_package: flutter_local_notifications_linux}`；`app_badge_plus` 只列出
android/ios/macos）。插件 README 在 pub 缓存中。

## 各平台行为

| | Android | iOS | macOS | Windows | Linux |
|---|---|---|---|---|---|
| 系统通知后端 | NotificationCompat，3 个频道（`ditmesh_messages`、`ditmesh_friend_requests`、`ditmesh_group_invites`） | UNUserNotificationCenter | UNUserNotificationCenter | WinRT toast（`flutter_local_notifications_windows`，AUMID `icu.agentx.ditmesh`，固定 CLSID） | 通过 D-Bus 的 `org.freedesktop.Notifications` |
| 运行时权限 | 13+ 上的 `POST_NOTIFICATIONS`：插件就绪后在前台请求一次（若当时在后台，则在下次回到前台时请求）；发送通知从不弹窗，只静默检查（`isPermissionGranted`），未授权时丢弃横幅。`ensurePermission()` 按需请求 | 提醒 + 角标 + 声音授权（同样规则） | 与 iOS 相同 | 无 | 无 |
| App 在前台时是否显示 | 是（仅对不在屏幕上的会话） | 是——`presentBanner/List` 开启 | 是 | 是 | 是 |
| 按会话分组 | `groupKey` + `InboxStyle`（最近 5 行，"N 条新消息"摘要） | `threadIdentifier` 堆叠 | `threadIdentifier` 堆叠 | 无（每个会话一条 toast，按 id 替换） | 无（按 id 替换） |
| 点击 → `takePendingTap()`（由 `tapTargets` 发出信号） | 是，包括冷启动（`getNotificationAppLaunchDetails`；点击会一直挂起，直到外壳取走——启动门、解锁） | 是，包括冷启动 | 是 | 运行中可以；**冷启动载荷仅在打包为 MSIX 时可用** | 运行中可以 |
| 打开 / 已读时取消 | 是 | 是 | 是 | **除非打包为 MSIX，否则为空操作**（插件限制，见 README） | 是 |
| 未读角标 | 取决于启动器（三星、小米/HyperOS、华为、OPPO、vivo、索尼、HTC……；原生 Pixel 只显示圆点） | 精确 | 精确（Dock） | 不支持 → 空操作 | 不支持 → 空操作 |
| 声音 | 频道默认，按偏好设置 `playSound` | 按偏好设置 `presentSound` | 相同 | 默认 toast 声音；关闭时 `WindowsNotificationAudio.silent()` | 关闭时 `suppressSound` |
| 后台预算（`AppLifecycleCoordinator`） | 60 s 提示（依 OEM 而异；Doze / 厂商省电会更早或更晚冻结） | 30 s（没有 `voip`；`audio` 仅在播放期间有效） | 无——从不挂起 | 无 | 无 |
| 恢复时重连 | 任何后台时段之后 `IdentityService.connect()` | 相同 | 相同（在 `hidden` 之后，例如最小化） | 相同 | 相同 |

连接状态从不产生系统通知。`ConnectionBannerPolicy` 暴露一个 `ValueListenable<bool>`：
连续两分钟不在线（`connecting` 也算）后置为 true，节点上线的那一刻置为 false；
shell 把它渲染为应用内横幅。

### Windows：系统 toast 与应用内回退

`flutter_local_notifications` ≥ 18 通过官方背书的 FFI 包原生支持 Windows，因此*显示*通知不需要
应用内回退。对未打包（`flutter build windows` 生成的 .exe）的 App，仍有两个限制，直接来自插件 README：

- `cancel()` / `getActiveNotifications()` 什么都不做——toast 会留在操作中心，直到用户关闭
  （打开会话不会清除它们）；
- 冷启动载荷不可用。

一旦 App 以 MSIX（`package:msix`）发布，这两个限制都会消失。在此之前的行为是"通知出现；
App 运行中点击它会打开会话"。`AppBadgePlusApi` 在 Windows 上是空操作（插件不支持任务栏覆盖角标）。

## Manifest / plist 变更

### `android/app/src/main/AndroidManifest.xml`

在 `<manifest>` 层级添加：

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

`flutter_local_notifications` ≥ 16 已经从自己的 manifest 合并了这两项；这里重复声明是为了让 App
请求的运行时权限在 App 自己的 manifest 中可见。**没有** `ScheduledNotificationReceiver` /
`ScheduledNotificationBootReceiver`（它们是为*定时*通知准备的；DitMesh 只从 Tox 轮询循环发送即时通知），
也**没有** `ActionBroadcastReceiver`（没有通知操作按钮）。没有前台服务：DitMesh 不附带 toxee 的
`ToxPollingService`；如果产品以后想要 Android 后台轮询，那是一个独立的原生服务加上
`FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_DATA_SYNC` 权限。

### `ios/Runner/Info.plist`

**不**声明任何 `UIBackgroundModes`（`audio` 已于 2026-10-02 移除）。

- **不是 `voip`**：DitMesh 没有 ToxAV；没有 VoIP 功能却声明 `voip` 并不诚实，App Review 会拒绝
  （方案 §5.6/§7）。
- **不是 `audio`**：App 进入后台时 `SidetoneSink` 会停止发声，后台也没有别的东西在播放，声明它就是
  一个未使用的模式（App Review 准则 2.5.4）。只有在加入真正需要后台持续播放的功能（例如熄屏继续的训练）时
  才一并加回，并确保该功能的音频会话是 `.playback`。
- 约 30 s 的预算来自 `AppLifecycleCoordinator` 从进入后台到回到前台或预算结束期间持有的
  `beginBackgroundTask`（`lib/lifecycle/background_task_api.dart` ↔ `AppDelegate.swift` 中的
  `icu.agentx.ditmesh/background_task` 通道）。没有它，iOS 约 5 s 后就会冻结 App，持久化刷新会被截断。
- **刻意不声明 `fetch`**：`BGAppRefreshTask` 需要原生处理器和 `BGTaskSchedulerPermittedIdentifiers`；
  toxee 有，DitMesh 还没有。要么两者一起添加，要么都不加。

### macOS

`UNUserNotificationCenter` 不需要 plist 或 entitlement 变更；插件会安装自己的 delegate。
通知需要签名过的 bundle（`flutter run -d macos` 的 ad-hoc 签名足以本地测试）。

## 本模块所有权之外的必要后续工作

1. **`android/app/build.gradle.kts`——核心库脱糖（core library desugaring）**
   （`flutter_local_notifications` ≥ 10 的硬性构建要求）：
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
   AGP 已经是 8.11.1（满足插件的最低要求）。
2. **`ios/Runner/AppDelegate.swift`**——iOS 插件依赖 App delegate 转发通知中心回调
   （macOS 插件不需要）。在 `didFinishLaunchingWithOptions` 内、`super` 之前添加：
   ```swift
   UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
   ```
   没有这一行，iOS 上的点击回调和前台展示都不工作。
3. **在 `main.dart` / `AppScope` 中接线**（见下文）。
4. **偏好设置持久化**：`NotificationPrefs.toJson()` / `fromJson()` 已就绪；App 设置的所有者
   应负责加载/保存它们。

## 接线片段（编排器）

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

// 路由点击（AppShell）：通知中心保留最新一次点击，直到路由取走它，
// 因此冷启动点击或解锁界面显示期间的点击都不会丢失。AppShell 在首帧后
// 以及每次收到信号时取出它，再经 ShellRouter 交给 ChatPage / GroupsPage
// （宽布局用内嵌面板，手机上推入路由；已打开的会话直接复用），好友请求
// 打开联系人，群邀请切到群组页。
final tapSub = center.tapTargets.listen((_) => route(center.takePendingTap()));
WidgetsBinding.instance.addPostFrameCallback((_) => route(center.takePendingTap()));

// ConversationScreen（ConversationAttention）：仅在用户真正看着它时
// （标签页可见、路由在最上层、应用在前台）用 owner 令牌占用，否则释放。
// 也只有这时才把消息标为已读。
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

## 语言

所有用户可见文本（标题、「来自 {name} 的好友请求」、「邀请加入 {group}」、「N 条新消息」的
收件箱摘要、Android 频道名与描述、Linux 的「打开」动作）都来自生成的 `S` 类
（`lib/l10n/app_*.arb` 里的 `notification*` 键），不再有英文常量类。这里没有
`BuildContext`，文本通过 `S Function()` 解析：

- `NotificationCenter` / `NotificationComposer` / `FlutterLocalNotificationsApi`
  接受 `strings:`，默认 `currentS()`（`lib/i18n/current_strings.dart`），跟随应用的
  `LocaleController`。`AppServices` 从其 `StringsResolver` 传 `() => strings.s`，测试传
  `() => lookupS(const Locale('zh'))`。
- 该函数在**发送时**调用，所以切换语言后从下一条通知起生效。已在通知栏 / 操作中心里的横幅
  保持发出时的语言；同一会话的下一条消息会以相同 id 替换它。
- **Android 频道名跟随语言**（2026-09-30）：`initialize` 创建三个频道，之后每次语言切换
  `LocalNotificationsApi.refreshStrings()` 都用当前文本重新创建它们（`AppServices` 监听
  `StringsResolver`，经 `NotificationCenter.refreshStrings()` 转发；频道仍在写入期间到达的
  切换会在 `initialize` 结束时补跑一次）。以相同 id 重新创建只更新名称/描述：重要性与提示音
  保持首次创建时的值（Android 规则）。
- Windows 向 toast 平台注册的是 `windowsAppName`（`Ditmesh`，产品名）；产品名从不翻译。
- `AppLifecycleCoordinator` / `LifecycleHint` 与 `ConnectionBannerPolicy` 只暴露枚举和布尔值；
  它们的文本在外壳 widget 里。

## 需要真机验证的内容

- Android 13+：权限对话框只出现一次；拒绝后不再发送；收件箱分组正确渲染；三星 / 小米启动器上的
  角标计数；Pixel 上只有圆点。Android 8–12：频道出现在设置中，没有对话框。
- iOS：授权提示；前台对未打开的会话显示横幅；锁屏上的线程堆叠；角标；点击冷启动通知打开会话
  （需要上面的 AppDelegate 那一行）；无播放时进入后台约 30 s 后 App 被挂起、`mayBeDisconnected`
  提示以及恢复时重连；活跃的摩尔斯播放在 `audio` 模式下是否能维持套接字存活。
- macOS：授权提示（签名 bundle）、Dock 角标、最小化时 `hidden` → 最小化期间的通知。
- Windows：未打包构建能出现 toast；运行中点击打开会话；确认上述 MSIX 限制；声音开关。
- Linux（GNOME / KDE）：D-Bus 通知、`Open` 操作、声音抑制。

## 测试

`test/notifications/`：`notification_center_test.dart`（后台发送文本 + 点划模式；活跃会话打开 → 不发送；
已静音 → 不发送；角标跟随未读；好友请求 / 群组邀请；点击；权限；收件箱分组；Linux/不支持平台的门控），
`app_lifecycle_coordinator_test.dart`（假时钟预算、恢复重连、桌面端无倒计时、钩子），
`connection_banner_policy_test.dart`、`notification_payload_test.dart`、
`notification_prefs_test.dart`。

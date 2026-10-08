[English](./README.md)

# ditmesh_chat

基于 Tim2Tox 的 [`ditmesh_chat_api`](../ditmesh_chat_api) 实现：通过 Tox P2P 网络提供身份、好友、
会话、明文消息和群组。**这是工作区中唯一允许导入 `tim2tox_dart` 或腾讯云 Chat SDK 的包**
（由 `tool/import_guard.dart` 强制执行）。App 只与契约对话；它只在构建后端时才接触这个包：

```dart
final backend = await DitmeshChatBackend.create(logger: CallbackChatLogger(myLog));
switch (await backend.identity.inspect()) {
  case IdentityState.none:   await backend.identity.create(displayName: 'W1AW', password: pw);
  case IdentityState.locked: await backend.identity.unlock(pw);
  case IdentityState.ready:  await backend.identity.open();
}
await backend.identity.connect();          // init → login → startPolling
backend.chat.conversationChanges.listen(...);
```

## 架构（方案 §3.2 "B 变体"）

```
apps/ditmesh ──► ditmesh_chat_api (contract) ◄── ditmesh_chat
                                                  │  DitmeshChatBackend
                                                  ├─ Tim2ToxIdentityService   identity.json, tox_profile.tox, password verifier, backup
                                                  ├─ Tim2ToxChatService        friends / conversations / messages / groups (+ parts)
                                                  ├─ Tim2ToxEngine            one FfiChatService per connected session
                                                  ├─ adapters/                Tim2Tox host interfaces (prefs, bootstrap, scratch, logger)
                                                  └─ native/                  setNativeLibraryName('tim2tox_ffi')
                                                          │
                                third_party/tim2tox/dart  │  FfiChatService (Dart)  ──ffi──►  libtim2tox_ffi (c-toxcore, --no-toxav)
```

**单一数据路径。** 与 toxee 的混合运行时不同，DitMesh 既不安装 `Tim2ToxSdkPlatform` 也不安装
UIKit，并且从不调用 `TIMManager.initSDK`。一切都沿 `FfiChatService` → `Tim2ToxFfi` →
`libtim2tox_ffi` 流动；服务监听 `FfiChatService.messages`，并每隔 `pollInterval`（3 s）轮询
`getFriendList`、`getFriendApplications`、`knownGroups`、`getPendingGroupInvites`。补丁版 SDK 的
进程级自定义回调钩子（`NativeLibraryManager.customCallbackHandler`，toxee 里由
`Tim2ToxSdkPlatform` 持有）在这里由 `engine/native_callbacks.dart`（`NativeCustomCallbacks`）接管：
把 `friendAddResult` 路由到等待中的 `addFriend` completer，把 `DartNotifyGroup*` 通知
（`groupQuitNotification`、`groupJoinNotification`、`groupJoinFailedNotification`、
`groupInviteNotification`）路由到当前 session，并和 toxee 一样按 session 归属过滤；
`groupChatIdStored` / `groupTypeStored` 触发拉取式的 `syncGroupIdentitiesFromNative()` 而不是写
偏好；`clearHistoryMessage` 忽略。没有这个钩子，SDK 会丢掉所有自定义回调，`addFriend` 要等 30 s
超时才返回（2026-09-30 在 macOS 上由原生 smoke 测试发现）。

### 身份生命周期

| 状态 | 含义 | 转换 |
|---|---|---|
| `none` | 没有 `tox_profile.tox` | `create()`（引导实例铸造 Tox ID，然后被销毁） |
| `locked` | 校验器持有密码**或**文件是 Tox 加密的 | `unlock(pw)` |
| `ready` | 明文档案，或本次运行中已解锁 | `connect()` / `disconnect()` |

静态加密：设置了密码时，`tox_profile.tox` 在磁盘上**始终**是加密的。`connect()` 在
`init` 之前把密码交给 Tim2Tox（`setProfilePassphrase`）；原生层直接打开加密档案并对每次
保存加密，因此应用运行中、进入后台或被杀死时都不会留下明文档案（旧版本留下的明文文件会在第一次
保存时迁移）。连接期间修改密码会对运行中的会话重新加密（`rekeyLiveProfilePassphrase`），之后
任何一步失败都会回滚。`disconnect()` 仍会加密它发现的明文文件，并在之后的断开中持续重试。
PBKDF2-HMAC-SHA256 校验器（`flutter_secure_storage`：Keychain / Keystore / libsecret / DPAPI）
是旧明文文件"是否设有密码"的权威；对于加密档案，成功的 `tox_pass_decrypt` 证明密码正确，并在
密码修改或恢复中断后修复过期的校验器。消息记录、草稿和待处理的好友请求**不**受密码保护
（Tim2Tox 以明文 JSON 保存记录）；身份文件仅限所有者访问（0700 / 0600），并排除在系统备份之外。

`PersistentIdentityService.persist()` 在挂起或导出前等待 savedata、延迟写入的历史、待发送队列和
已注册 `IdentityDataStore` 的写入。替换前先让这些存储停止旧身份的写入；身份流仅在替换成功后
发布 `null`，再发布恢复后的身份，即使公钥相同也会重新发布。

磁盘布局（`IdentityPaths`，位于平台的 application-support 目录下）：

```
ditmesh/identity/
  identity.json              display name, status, Tox ID, hasPassword
  profile/tox_profile.tox    Tox savedata
  data/chat_history/  data/offline_message_queue.json  data/file_recv/  data/avatars/  data/scratch/
  training/                  IdentityService.dataDirectory() — other modules' per-identity state
```

### 备份格式（`exportBackup` / `importBackup`）

`BackupContainer`：无依赖、带长度前缀的归档。

```
"MCQB" | version u8 = 1 | flags u8 (bit0: profile encrypted) | count u32
entry*: pathLen u16 | path (UTF-8, '/'-separated) | size u64 | bytes
```

条目：`identity.json`、`tox_profile.tox`（设有身份密码时用该密码加密）、`dataDirectory()` 下
每个文件对应的 `training/<relative path>`。解码时校验路径（不允许 `..`、绝对路径、反斜杠和
Windows 盘符）。导出先冲刷已注册的存储；导入先完成所有归档文件的暂存，目录替换失败时回滚。
归档包括身份、Tox savedata 和学习文件；聊天历史、待发送队列与偏好不在此格式范围内。
`importBackup` 替换当前身份；加密的档案需要密码（否则 `wrong_password`），并把密码带入校验器，
这样恢复后的身份可以用同一密码解锁。

### 消息

- `sendText` → `sendTextWithResult`（C2C）/ `sendGroupTextWithResult`（群组）。超过
  `maxMessageBytes`（**1322**，`TOX_MAX_MESSAGE_LENGTH − 50`）的文本抛出 `message_too_long`：
  Tim2Tox 会把它们拆成多条独立消息。
- Tim2Tox 把发给离线好友 / 尚未连接的群组的消息排队，并返回一条 `pending` 行；持久队列让它在
  重启后仍显示待发送，即使上游加载历史时清除了临时标志。冲刷成功后该行以
  `sent` 状态在 `messageEvents` 上重新发出。Tim2Tox 在这条路径上没有独立的失败标记
  （`_markPendingItemFailed` 同样把 `isPending` 置为 false），因此目前不会产生 `failed`——
  已在上游 `tim2tox_core` 拆分中跟踪。
- `cloudCustomData` 在 Tim2Tox 中**仅限本地**（从不经 Tox 发送）；DitMesh 不使用它
  （方案 §5.2 第 1 层是明文）。
- 会话是派生出来的：历史 id ∪ 好友 ∪ 群组，再减去隐藏（已删除）的；未读数来自 Tim2Tox 的已读屏障；
  置顶/草稿/隐藏来自 `ConversationMetaStore`（`shared_preferences` 中按账号划分的键）。
- 待处理好友请求在账号专属缓存中保留附言和到达时间，直到接受或拒绝。已拒绝请求也按账号隔离；
  已有的单身份全局拒绝列表会被当前账号迁移一次。

### 仍走腾讯绑定的部分及原因

`FfiChatService` 针对（打过补丁的）腾讯 SDK 编译，少数操作只能通过其 `Dart*` 兼容导出到达 Tox，
这些导出由 `libtim2tox_ffi` 实现。`NativeLibrarySetup.ensure()`——由 `DitmeshChatBackend.create()`
在第一个 `FfiChatService` 之前调用——像 toxee 的 `LoggingBootstrap` 一样执行
`setNativeLibraryName('tim2tox_ffi')`，使这些绑定加载我们的库而不是 `dart_native_imsdk`。

| 操作 | 路径 | 说明 |
|---|---|---|
| `leaveGroup` | `FfiChatService.quitGroup` → `NativeLibraryManager.bindings.DartQuitGroup` | 与 toxee 一致 |
| `groupMembers` | `GroupBindings.members` → `DartGetGroupMemberList` | 与 tim2tox 的 platform 发出的调用相同；按公钥去重 |
| `inviteToGroup`（好友在线） | `GroupBindings.invite` → `DartInviteUserToGroup` | 绕过 `TIMGroupManager`，其包装器在没有 `TIMManager.initSDK` 时会拒绝 |
| `inviteToGroup`（好友离线） | 在 `ConversationMetaStore` 中排队，好友上线时发送 | Tim2Tox 自己的重放使用 `TIMGroupManager`，因此需要 `initSDK`；我们的不需要 |

`TIMManager.initSDK` 是刻意不调用的：它会安装 SDK 自己的原生消息监听器——也就是 toxee 需要
`BinaryReplacementHistoryHook` 来调和的第二条入站路径。

### `tencent_cloud_chat_common` 桩包

`tim2tox_dart` 的 pubspec 要求 `tencent_cloud_chat_common`（一个 UIKit widget 包，带有庞大的插件树：
TUICore、hive、audioplayers……）。只有 `Tim2ToxSdkPlatform` 导入它，而 DitMesh 编译的任何代码
都不会触及那个文件。`third_party/stubs/tencent_cloud_chat_common` 是一个满足 pub 要求的空包；
根目录的 `pubspec_overrides.yaml` 指向它。如果未来 tim2tox 的改动让 `FfiChatService` 触及
`Tim2ToxSdkPlatform`，编译会大声失败（缺少导入），而不是悄悄把 UIKit 拉进来。当上游发布不含 UIKit 的
`tim2tox_core` 时移除该桩包（方案 §3.2 D）。

## 引导

```bash
export PATH=/home/user/flutter/bin:$PATH
dart run tool/bootstrap_deps.dart     # submodule → vendor SDK → patches → root pubspec_overrides.yaml
dart pub get                          # workspace root
flutter analyze packages/ditmesh_chat
flutter test packages/ditmesh_chat    # needs-native test skips itself without the library
dart run tool/bootstrap_deps.dart --offline-check-only   # CI: prove the tree matches the lock
```

`tool/bootstrap_deps.dart`（从 toxee 移植，去掉了 UIKit 分支）：

1. `git submodule sync` / `update --init -- third_party/tim2tox`（固定在 toxee 使用的同一提交
   `9d4245a`；嵌套的 c-toxcore 子模块不初始化——只有原生构建需要它们）。
2. 按 `third_party/tim2tox/tool/tencent_cloud_chat_sdk.lock.json` 下载 `tencent_cloud_chat_sdk`
   （8.9.7540+3，SHA-256 校验）到 `third_party/tencent_cloud_chat_sdk/`。
3. 用 tim2tox 自己的 `apply_sdk_patches.dart` 应用 tim2tox 的 22 个补丁系列
   （补丁 0001 添加 `setNativeLibraryName`）。
3b. 叠加 DitMesh 自己的 overlay `third_party/overlays/tencent_cloud_chat_sdk/`
   （`tool/vendor_overlay.dart`）：把插件的*平台*半边换成空操作的插件类，并删掉所有腾讯二进制——
   `TXIMSDK_Plus_iOS_XCFramework` / `TXIMSDK_Plus_Mac` / `HydraAsync` 三个 pod、
   `com.tencent.imsdk:imsdk-plus` AAR 与 `libdart_native_imsdk.so`、`ImSDK.dll` /
   `dart_native_imsdk.dll`。DitMesh 只用插件的 Dart 绑定（指向 `libtim2tox_ffi`），应用调用的
   东西一样不少；生成的插件注册器仍能找到各自的类。overlay 的哈希记为 vendor state 里的
   `overlay_sha256`（`--offline-check-only` 会校验）；toxee 保留完整插件，因为混合运行时需要它。
4. 写入**根目录**的 `pubspec_overrides.yaml`（`tim2tox_dart`、`tencent_cloud_chat_sdk`、
   `tencent_cloud_chat_common` → 路径）——pub 工作区只在根目录读取 overrides。
   `--offline-check-only` 的状态保存在 `third_party/.vendor_state.json`。

生成物，永不提交：`third_party/tencent_cloud_chat_sdk/`、`third_party/.vendor_state.json`
（两者都在 `third_party/.gitignore` 中）以及根目录的 `pubspec_overrides.yaml`
（把它加入根目录 `.gitignore`）。

## 原生库前置条件

Dart 包不需要它也能编译，但每条运行时路径都需要**不带 ToxAV** 构建的 `libtim2tox_ffi`
（DitMesh 没有通话功能）：

```bash
# from a toxee checkout with tool/ci/build_tim2tox.sh, or tim2tox's own build.sh
tool/ci/build_tim2tox.sh --no-toxav          # Linux x86_64 / Windows x64 / macOS x86_64+arm64 / Android arm64-v8a / iOS arm64
```

| 平台 | 产物及 `Tim2ToxFfi.open()` 的查找位置 | 最低系统版本 |
|---|---|---|
| macOS | 可执行文件旁的 `libtim2tox_ffi.dylib`、`../Frameworks/`，或 `tim2tox/build/ffi/` | 10.15 |
| Linux | 可执行文件旁或 `../lib/` 下的 `libtim2tox_ffi.so` | — |
| Windows | 可执行文件旁或 `../lib/` 下的 `tim2tox_ffi.dll` | 10 |
| Android | `jniLibs/<abi>/` 中的 `libtim2tox_ffi.so`（System.loadLibrary） | API 21 |
| iOS | 嵌入 bundle 的 `tim2tox_ffi.framework` | 13 |

开发循环可以用 `DitmeshChatBackend.create(nativeLibraryPathOverride: ...)` 固定一个绝对路径
（必须在库首次打开之前设置）。移动端兼容：整个包都是共享 Dart，这里没有任何桌面专有的东西。
使用 `flutter_secure_storage` 11.x 是因为它的 Windows 插件依赖 `win32 ^6`，正是 App 的
`share_plus` 需要的主版本。

## 测试

`flutter test packages/ditmesh_chat` 无需原生库即可运行：

- `identity_service_test.dart`——inspect/create/unlock/open 状态机、围绕 connect/disconnect 的静态加密、
  校验器优先于文件的权威性、changePassword、备份导出/导入往返、deleteIdentity（假的 `ProfileCrypto`、
  内存 secure store、假的 `ChatEngine`）。
- `chat_service_test.dart`——真实的 `FfiChatService` 跑在 `Tim2ToxFfi` 绑定假实现之上
  （Flutter 测试绑定 + 模拟的 `path_provider` channel，与 toxee 相同）：离线发送 → `pending`、
  入站 → `received` + 未读、会话派生/排序、置顶/草稿/删除持久化、群组映射、邀请排队、校验错误、
  会话分离。
- `backup_container_test.dart`、`prefs_adapter_test.dart`、`password_verifier_test.dart`
  （RFC 7914 PBKDF2 测试向量）。
- `identity_persistence_test.dart`、`transport_persistence_test.dart`、`key_value_store_test.dart`、
  `message_mapper_test.dart`——写入中断、身份替换屏障、注册存储冲刷、群组未读与邀请恢复、偏好写入
  错误，以及重启后待发送状态恢复。

### 原生冒烟测试（`@Tags(['needs-native'])`）

`test/native_smoke_test.dart` 在单进程内驱动真实的库：创建身份 → 连接 → 接入 DHT →
向离线对端排队一条发送 → 创建 / 列出成员 / 退出一个群组（`DartGetGroupMemberList`、
`DartQuitGroup`）→ 断开连接。库无法打开时它会自行跳过；在 CI 中用
`flutter test --exclude-tags=needs-native` 显式排除。在开发机上：

```bash
bash tool/ci/build_tim2tox.sh --target macos-arm64 --mode release   # 或 linux-x86_64 …
cd packages/ditmesh_chat && TIM2TOX_FFI_LIB=$PWD/../../build/native/macos-arm64/libtim2tox_ffi.dylib \
  flutter test --tags needs-native test/native_smoke_test.dart
```

在 Mac 上约 10 s 通过（2026-09-30）：身份 → DHT → 好友请求（由路由过来的 `friendAddResult`
即时返回）→ 离线发送入队 → 建群 / 列成员 / 退群 → 断开。

`test/native_persistence_test.dart` 创建带密码的身份、更新档案、添加离线好友、建立 NGC、排队文本，
保存草稿与置顶，再让相同路径上的全新后端恢复所有值并解密 savedata。测试无需等待 DHT 连接：

```bash
TIM2TOX_FFI_LIB=/absolute/path/to/libtim2tox_ffi.dylib \
  flutter test --no-pub test/native_persistence_test.dart
```

双对端互发需要两个进程（Tim2Tox 默认的单例实例模型——多实例只为其自身的 auto_tests 存在）：
用不同的 `IdentityPaths` 根目录运行冒烟测试两次并互加 Tox ID，或者对着一个 toxee 实例驱动；
该测试战役就是方案中的 M0b 试验。

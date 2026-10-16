[English](./README.md)

# ditmesh_chat_api

DitMesh UI 与聊天后端之间的纯 Dart 契约。UI 只依赖这个包；`packages/ditmesh_chat` 在 Tim2Tox 之上
实现它，并且是唯一允许导入 Tim2Tox 或腾讯 SDK 的包（`tool/import_guard.dart`）。

## 内容

| 文件 | 内容 |
|---|---|
| `lib/src/models.dart` | `Identity`、`IdentityState`、`Friend`、`FriendRequest`、`Conversation`、`ChatMessage`、`Group`、`GroupMember`、`GroupInvite`、`ConnectionStatus`、`MessageStatus`、`GroupKind`、`ChatException` |
| `lib/src/identity_service.dart` | `IdentityService`：inspect / create / unlock / open / 密码 / 资料 / 基础备份 / connect / delete / `dataDirectory()`；`PersistentIdentityService.persist()` 与 `IdentityDataStore` 落盘屏障 |
| `lib/src/encrypted_backup.dart` | `EncryptedBackupService`：按 `BackupCategory` 选择内容的完整加密备份，含清单、预览与 `RestoreReport` |
| `lib/src/backup_media.dart` | 可选备份携带哪些已保存的工作台录音的规则 |
| `lib/src/chat_service.dart` | `ChatService`：好友、请求、屏蔽、会话、历史、`sendText`（可附 `KeyedRecording`）、取消/重试、`messageEvents`、群组、邀请 |
| `lib/src/keyed_recording.dart` | `KeyedRecording`：经过校验的拍发原始点划/间隔时序 |
| `lib/src/message_search.dart` | 分页、可取消的历史搜索 |
| `lib/src/outbox.dart` | `OutboxInspector`：持久化发送队列中的内容 |
| `lib/src/network_bootstrap.dart` | `NetworkBootstrapService`：自动 / 手动 / 局域网节点配置与探测 |
| `lib/src/peer_text.dart`、`lib/src/tox_address.dart` | 清理对端提供的文本；表单、二维码、后端与假实现共用的 Tox ID 校验 |
| `lib/testing.dart` | `FakeIdentityService`、`FakeChatService`、`FakeNetworkBootstrapService`——widget 测试与 `DITMESH_FAKE_BACKEND` 演示模式共用的内存假实现 |

## 设计说明

- **身份优先。** 聊天和按身份保存的练习数据都需要已打开的身份。启动门在渲染任何内容之前先调用
  `inspect()`，其他模块把按身份划分的数据持久化在 `dataDirectory()` 下。
- **文本保持互通。** 每条消息都是任何 Tim2Tox 客户端（toxee）都能读取的 UTF-8 文本。可选的
  `KeyedRecording` 把发送方的原始节奏带给兼容的 DitMesh 对端，传输方式见
  [原始拍发节奏契约](../../doc/rfcs/2026-10-09-keyed-rhythm.zh-CN.md)。没有节奏时，接收方按收听者自己的速度播放文本。
- **离线是常态。** Tox 没有服务器存储。发给离线对端的消息返回 `MessageStatus.pending`，
  由后端在对端上线时冲刷；UI 必须解释这一点，而不是显示错误。排队中的发送可以取消（`cancelled`），
  失败的发送可以用同一个消息 ID 重试。
- **状态名副其实。** `sent` 表示本机传输层已接受；`delivered` 需要对端回执（群组为至少一名成员）。
  两者都不代表已读或已收听。
- **流会重放。** `ChatService` 的每个 `*Changes` 流都会先向每个监听者发送当前值，再发送每次变化；可以有任意多个监听者，同步 getter 始终与之一致。
  不要依赖 `isBroadcast`：Tim2Tox 后端的流返回 false，假实现的流返回 true。
  `NetworkBootstrapService.changes` 以及 `FakeIdentityService` 的身份与连接流是不重放的普通广播流，应在监听前先读取 getter。

## 版本

契约 v0.1（`pubspec.yaml` 0.1.0）。只做增量扩展；重命名或删除成员需要在同一次改动中同时更新
`packages/ditmesh_chat`、假实现和所有 UI 使用方。

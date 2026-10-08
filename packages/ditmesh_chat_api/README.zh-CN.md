[English](./README.md)

# ditmesh_chat_api

DitMesh UI 与聊天后端之间的纯 Dart 契约。UI 只依赖这个包；`packages/ditmesh_chat` 在 Tim2Tox 之上
实现它，并且是唯一允许导入 Tim2Tox 或腾讯 SDK 的包（`tool/import_guard.dart`）。

## 内容

| 文件 | 内容 |
|---|---|
| `lib/src/models.dart` | `Identity`、`IdentityState`、`Friend`、`FriendRequest`、`Conversation`、`ChatMessage`、`Group`、`GroupMember`、`GroupInvite`、`ConnectionStatus`、`MessageStatus`、`GroupKind`、`ChatException` |
| `lib/src/identity_service.dart` | `IdentityService`：inspect / create / unlock / open / password / profile / backup / connect / delete / `dataDirectory()` |
| `lib/src/chat_service.dart` | `ChatService`：好友、请求、会话、历史、`sendText`、`messageEvents`、群组、邀请 |
| `lib/testing.dart` | `FakeIdentityService`、`FakeChatService`——widget 测试与 `DITMESH_FAKE_BACKEND` 开发模式共用的内存假实现 |

## 设计说明

- **身份优先。** 训练同样需要身份（2026-09-30 的产品决策）。启动门在渲染任何内容之前先调用
  `inspect()`，其他模块把按身份划分的数据持久化在 `dataDirectory()` 下。
- **线上传输明文。** `sendText` 只承载 UTF-8 文本；任何 Tim2Tox 客户端（toxee）都能读取。
  摩尔斯渲染发生在接收侧，按收听者自己的速度进行。键控时序传输是 v2 特性，需要上游 Tim2Tox 的改动
  （方案 §5.2）。
- **离线是常态。** Tox 没有服务器存储。发给离线对端的消息返回 `MessageStatus.pending`，
  由后端在对端上线时冲刷；UI 必须解释这一点，而不是显示错误。
- **流会重放。** 每个 `*Changes` 流都是广播流，并向新的监听者重放当前值；同步 getter 始终与之一致。

## 版本

契约 v0.1。只做增量扩展；重命名或删除成员需要在同一次改动中同时更新 `packages/ditmesh_chat` 和
所有 UI 使用方。

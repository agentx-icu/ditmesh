[English](./2026-09-30-tim2tox-message-annotation.md)

# RFC：消息注解上线（Tim2Tox D 线第 1 项）

> 状态：**草案，尚未提交上游**（2026-09-30）。目标仓库：`agentx-icu/tim2tox`
>（子模块 pin `9d4245a`）。D 线的其它项——Dart 侧自定义包 API、有损包 API、`failed`
> 消息状态——见 §7，各自另起提案。

## 1. 问题

`FfiChatService.sendTextWithResult(peerId, text, {cloudCustomData})` 只把
`cloudCustomData` **存在本地**：接收方的 `ChatMessage` 永远拿不到它
（`dart/lib/service/ffi_chat_service.dart`，"One-shot cloudCustomData … carries no
cloudCustomData"）。`sendGroupTextWithResult` 干脆没有这个参数。

两个使用方都需要随文本一起传输的、按消息挂载的结构化元数据：

- **toxee**：回复引用与转发元数据（`V2TIM` 的 `cloudCustomData`）只在发送方显示，接收方
  静默丢失——混合运行时的已知缺口。
- **DitMesh**：v2「录制键控」（方案 §5.2 第二层）必须把发送方的键控时序（`wpm`、
  Farnsworth、量化后的元素时长）连同明文一起送达，接收方才能回放实际键控。v1 之所以
  只发明文并按接收方速度播放，正是因为缺这一层。

两者要的是同一件事：一个与某条文本消息关联的不透明 JSON，送到同一 peer 或群组，到达时
合并进那条消息，绝不单独渲染成一条消息。

## 2. 非目标

- 不是通用自定义消息类型：`kGenericCustom`（控制帧 `Type = 3`）已经存在，用于独立载荷，
  会渲染成自己的气泡。
- 不做分片：一条注解必须装进一个无损自定义包（头部之后载荷 ≤ 1.2 KB）。超限是调用方错误。
- 不改动文本消息本身；旧客户端照常收到文本并忽略注解（见 §5）。

## 3. 线路格式

复用现有控制帧（`source/Tim2ToxPacketIds.h`：包 id `kControl = 184`，magic `T2TC`，
`source/Tim2ToxControlPacket.h`），增加一个类型：

```cpp
enum class Type : uint8_t {
    kReceipt = 1,
    kReaction = 2,
    kGenericCustom = 3,
    kGroupIdentity = 4,
    kMessageAnnotation = 5,   // 新增
};
```

正文（UTF-8 JSON，单个对象）：

| 字段 | 类型 | 含义 |
|---|---|---|
| `v` | int | 注解 schema 版本，`1` |
| `h` | string | 关联键：被注解文本消息 `sha256(utf8(text))` 前 8 字节的十六进制 |
| `n` | int | 发送方的注解序号（区分短时间内两条相同文本；接收方按 `h` 配对并取最早未配对的一条） |
| `data` | object | 不透明的应用载荷；键按应用命名空间区分（`"toxee"`、`"ditmesh"` ……） |

为什么不用消息 id：今天两端的消息 id 都是**本地的**——发送方为自己的行造
`${ms}_${seq}_$selfId`（`ffi_chat_service.dart` 的 C2C 发送路径），接收方为入站行造自己的
`${ms}_${seq}_$from`；线上没有任何两端共享的 id，现有回执正是出于同样原因用文本派生的键
（`'dup:$text'.hashCode`）关联。摘要是两端都能从真正上线的字节算出来的东西。

示例（DitMesh）：

```json
{"v":1,"h":"9a3f0c1e77b2d4a0","n":17,"data":{"ditmesh":{"v":1,"wpm":15,"fw":8,"keyed":true,"t":"<base64 varint 时序>"}}}
```

大小规则：`Encode()` 对超过无损自定义包上限的正文返回 `nullopt`，与今天其它类型一致；
Dart 侧把它呈现为错误结果，而不是静默丢弃。

## 4. 发送方行为

- **C2C**：`sendTextWithResult(peerId, text, cloudCustomData: json)` **先**发一个
  `kMessageAnnotation` 帧（`h` = 文本摘要，`n` = 下一个序号），再照常发文本。帧走与回执相同的
  无损自定义包路径；接收方先看到哪个都无所谓（§5 对两种顺序都限时保留）。
- **群组（NGC）**：新增参数 `sendGroupTextWithResult(groupId, text, {cloudCustomData})`。
  群组自定义包带有种类标签（`V2TIMManagerImpl::HandleGroupCustomPacket` 里的
  `UnwrapTim2ToxGroupPacket(kTim2ToxGroupPacketCustomMessage, …)`），现有种类会被物化成可见的
  自定义消息。因此注解使用**新的种类** `kTim2ToxGroupPacketAnnotation`，处理函数在走自定义消息
  路径之前把它路由到注解路径；正文与 C2C 帧相同的 JSON。Conference 群无法承载自定义包：参数接受
  但忽略，结果里报告 `annotationDelivered: false`。
- **离线队列**：注解与其文本一起入队（一个队列条目同时持有两者），对端上线时按序重放。
  永远不会出现只有文本没有注解、或反之的情况。
- 本地 `ChatMessage` 的 `cloudCustomData` 保持今天的行为（发送方视图不变）。

## 5. 接收方行为

- 收到 `kMessageAnnotation`（C2C 帧或群组包种类）：放进一个以**发送者 + 摘要**为键的小表——C2C
  为（`peer`，`h`），NGC 为（`group`，`发送者 peer id`，`h`），发送者取 toxcore 交付时的
  `peer_id`，绝不取正文里的字段——限时限量（30 s / 64 条）。两个成员发同样的文本时，不会拿到
  对方的注解。该 peer 随后到达的文本若摘要匹配，就挂上最早未配对的注解：设置
  `cloudCustomData`（替换而非合并：一条消息一个注解）并从表中移除。若文本先到，入站路径保留每个
  peer 最近几条消息的摘要（同样的上限），晚到的注解仍能找到那一行并发出消息更新事件。未配对的
  条目到期后丢弃并记一条日志。
- 注解**永远不会**物化成 `ChatMessage`：没有气泡、不计未读、不发通知。
- 旧客户端（`Type` 未知）在 `Decode()` 中已经忽略未知控制类型——用现有的
  `Tim2ToxControlPacketTest` 验证，并加一个用例：没有本 RFC 的构建收到 `Type = 5` 时静默丢弃。
- 应用忽略不属于自己的 `data` 键。

## 6. API 面

Dart（`FfiChatService`）：

- `sendTextWithResult(..., {String? cloudCustomData})`——语义变化：现在会传输。结果新增
  `bool annotationDelivered`。
- `sendGroupTextWithResult(..., {String? cloudCustomData})`——新增参数。
- `Stream<ChatMessage> messageUpdates`（或现有的消息变更通道）在注解落到已显示消息上时触发。

FFI：新增一对导出，镜像回执路径（`tim2tox_ffi_send_message_annotation`，回调
`messageAnnotation`），或者扩展现有的发文本调用带上可选 blob；后者让 ABI 字节级匹配约束更简单
（一个调用、一个可选指针）。倾向扩展方案。

## 7. D 线的相关项（另起提案）

1. **Dart 侧自定义包 API**——把无损自定义包（`kLosslessCustomRangeStart..End`）暴露给 Dart，
   应用可以不碰 C++ 定义自己的包类型。
2. **有损包 API**——实时键控（方案 §5.5）必需：无损路径的队头阻塞让实时键控在 TCP relay
   上无法使用。
3. **`failed` 消息状态**——轮询路径分不清 `failed` 与 `sent`；今天 `MessageStatus.failed`
   从不出现。

## 8. 测试计划

- `Tim2ToxControlPacketTest`：`Type = 5` 的编解码往返、超限拒绝、未知类型丢弃。
- Headless 双实例测试（tim2tox `auto_tests` 风格）：A 向 B 发文本 + 注解；B 的 `ChatMessage`
  显示 `cloudCustomData`；处理到达顺序颠倒；发给离线 peer 的注解与文本一起重放。
- toxee：两个构建之间的回复引用往返。
- DitMesh：API 就位后 `ditmesh_chat/test/native_smoke_test.dart` 增加一次自注解发送。

## 变更记录

- **2026-09-30 v0.1** 首稿，依据 ditmesh 方案 §5.2 与 pin `9d4245a` 的 Tim2Tox 控制帧源码
  写成。尚未提交上游。
- **2026-09-30 v0.2** 审查修正：关联改用文本摘要 + 发送方序号而非 `clientMessageID`（两端的消息
  id 都是本地的）；注解帧先于文本发送、两种到达顺序都保留；NGC 需要自己的群组包种类，因为现有的
  自定义种类会被渲染成消息；群组配对同时以发送 peer 与摘要为键。

[English](./README.md)

# DitMesh Dart 补丁

Bootstrap 把固定的 `third_party/tim2tox/dart` 复制到被忽略的
`third_party/tim2tox_ditmesh`，依次应用编号补丁。来源与补丁均参与指纹计算；
修改补丁后运行 `dart run tool/bootstrap_deps.dart`，用
`--offline-check-only` 检查生成目录的指纹。固定子模块保持原样。

`0010-recorded-receive-durability.patch` 为回执增加历史存储会话及会话清空
状态约束。缓存中的重复消息须完成保存后才能确认；归档中的重复消息在同一
写入锁内检查，包括尚未写入归档的溢出行。失败的到达保留发布标记，恢复后
只发布一次。达到 128 项上限时，新接收在追加前被拒绝，保留未发布消息的
标记。独立的 Dart 会话代次也阻止已关闭或被替换的接收方发布和确认旧任务。
容量检查前会移除会话或清空约束已失效的项；其他会话中仍有效的未发布项
会保留，以便恢复。

`packages/ditmesh_chat/test/recorded_receive_durability_test.dart` 覆盖不可写
存储、重复重试、恢复可写、已保存重复消息保持安静、新实例读取磁盘、等待
写入期间退出和重开、清空历史，以及未发布状态的数量上限。

`0011-adaptive-default-instance-poll.patch` 让唯一聊天服务运行在默认原生实例上
的宿主退出上游 50 ms 的共享实例轮询。上游默认值不变；`DitmeshFfiChatService`
选择退出，并把空闲节奏设为 500 ms（任何事件或发送后 2 s 内为 200 ms，接收
文件期间或探测实例已注册时为 50 ms）。`tox_iterate` 运行在原生事件线程上，
因此这里只调整事件读取的节奏。发送消息和扩展数据包会标记活动，并立即重新
安排空闲计时器。发送文件（DitMesh 不发送文件，此路径不可达）在开始时和每个
进度事件上标记活动，因此以 200 ms 读取事件：发送端的传输记录在完成后不会
清除，不能用来触发 50 ms 规则。`packages/ditmesh_chat/test/poll_cadence_test.dart` 覆盖策略
与会话节奏；`native_two_peer_test.dart` 检查生产引擎构建的是自适应服务。

`0012-extension-refusal-keeps-queue.patch` 新增 `ExtensionSendRefused`：当原生
传输拒收某个分包时，`sendTextExtension` 的覆写实现抛出它。离线队列排空把它当作
原生文本发送被拒处理：条目留在队列中，对应行保持待发送，不会标记为失败。录制
信封以同一消息标识重试，接收端按该标识去重。
`packages/ditmesh_chat/test/recorded_resend_test.dart` 与 DitMesh 对未确认录制
消息的重放一起覆盖此行为。

`0013-legacy-row-reconcile.patch` 让冲刷在等待移除队列项之后，仍能找回没有 msgID
的旧版己方行：若期间回执替换了该行（`copyWith`），按内容和精确时间匹配，使该行退出
待发送状态并保留回执。带 msgID 的行使用上游的查找。它取代原
`0005-preserve-recorded-outbox-ack.patch`；上游 #31 已为带 msgID 的行实现了同样的处理。
`packages/ditmesh_chat/test/legacy_recorded_outbox_test.dart` 和
`recorded_outbox_ack_test.dart` 覆盖两种情况。

`0014-retry-failed-tombstone.patch` 让“重试”也能重新排队这样的行：其冲刷失败只记录在
已提交的 `failed` 墓碑项中（该行自身的写入在重启前丢失，重新加载的行不显示失败，而
DitMesh 显示为失败）。送达证据仍优先于失败。
`packages/ditmesh_chat/test/failed_tombstone_retry_test.dart` 覆盖此情况。

`0015-preserve-future-history.patch` 移植 Tim2Tox 提交
`5341e64ed62b81a94a311c768a73863a3cffcbb1`，不改变固定的 submodule。
读取与写入均先检查主文件和备份的 schema，向上传递
`HistorySchemaNewerThanAppException` 并原样保留新格式数据。补丁已适配
0010 的 receipt fence：录音消息仍须真正持久化才 ACK/发布。身份边界将异常
映射为本地化的升级提示。回归覆盖 `history_schema_downgrade_test.dart`、
`recorded_receive_durability_test.dart`、`recorded_resend_test.dart` 和
`identity_persistence_test.dart`。

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

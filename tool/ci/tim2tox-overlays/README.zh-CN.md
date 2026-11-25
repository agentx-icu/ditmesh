[English](./README.md)

# DitMesh 原生 overlay

原生构建器把固定版本的 Tim2Tox 源码复制到 `build/native/.sources/<target>/tim2tox`，再应用这些审阅过的补丁。
`third_party/tim2tox` 与上游 Dart 包都保持不变。源码内容、补丁和暂存辅助脚本都会生成指纹。上游源码变化后
仍必须能接受每一个补丁；不匹配时构建失败。必需与实验性 CI 的原生缓存键都包含补丁/辅助脚本的摘要。

`0001-enable-group-persistence.patch` 在 `tox_new` 加载 savedata 之前打开 Tox 的群组持久化选项。上游默认不保存
NGC 成员关系和对端状态，身份重启后群组就无法重新连接。DitMesh 需要把这些状态与身份一起保存，并通过加密档案存储
和备份流程保护 savedata。

`0002-report-group-member-connection.patch` 用 Tox 的对端连接查询结果填充已有的成员在线字段，并写入两个 JSON
成员序列化器。自身状态同时检查本地/群组连接。按照固定版本的 Tox API 约定，旧式 conference 的枚举只包含在线成员。
已有的结构和导出函数签名都不变。

`0003-isolate-private-node-probes.patch` 在已有的无界面创建函数 `tim2tox_ffi_create_bootstrap_instance` 上，
把有符号的 `udp_start_port = -1` 保留给私有可达性探测。它关闭本地发现并保留默认的 UDP 绑定范围，不注册全局
SDK/消息监听器，也不重放聊天监听器。因此探测实例的连接变化不会产生未限定作用域的 `conn:` 事件，不会改变正在
进行的聊天的连接状态。C 参数仍是 `int`，固定版本的 Dart 绑定仍是有符号 `Int32`；没有增加或删除导出。
普通局域网托管使用 `0` 或正数首选端口时，保留发现、IPv6 和原有端口范围。选项回归测试会编译打过补丁的创建函数，
并执行私有、默认、正数、最大值和非法输入；真实原生回归测试同时验证探测/聊天事件隔离以及普通局域网绑定与 DHT 应答。

必需的 Linux 与 macOS CI 任务运行两个相互隔离的真实 UDP 对端，覆盖私聊与群组消息、加密重启、持久队列和群组恢复。
公共 DHT 网络探测是单独的，需要显式设置 `DITMESH_PUBLIC_DHT_SMOKE=true`。

`0004-extract-profile-address.patch` 从档案读取完整 Tox 地址，读取时无需打开
在线会话。既有公钥 ABI 保持兼容。原生加密测试导入明文和密码保护的档案，并
核对完整地址。

`0005-isolate-friendship-sessions.patch` 在原生 SDK 会话结束时清除待处理好友申请、
黑名单和好友资料缓存，同时保留监听器注册。它定向回移 Tim2Tox #37 的相关修复。
Linux/macOS 同架构构建还会用相同 FFI/SDK 源码链接独立回归程序，验证
`init(A) -> 申请 -> uninit -> init(B)` 后 B 的申请为空。程序不进入制品目录，
发行库仍保持 `TIM2TOX_ENABLE_TEST_HOOKS=OFF`；交叉构建不执行目标架构程序。

[English](./TEST_PYRAMID.md)

# 测试

在仓库根目录运行：

```bash
bash tool/test_pyramid.sh --level gates
bash tool/test_pyramid.sh --level unit
bash tool/test_pyramid.sh --level widget
bash tool/test_pyramid.sh --level e2e --device macos
```

| 层级 | 覆盖范围 | 位置 |
|---|---|---|
| 门禁 | 严格分析、复杂度、导入及界面本地化 | `tool/` |
| 单元 | 电码引擎、音频 I/O、聊天契约、队列及传输服务 | `packages/*/test` |
| 控件与服务集成 | 启动、身份、单聊和群聊、网络设置、参考、通知、桌面服务及外观 | `apps/ditmesh/test` |
| 原生集成 | 加密资料、备份恢复、持久化、局域网节点及隔离探测 | `packages/ditmesh_chat/test` |
| 平台端到端 | 实际启动、插件初始化、导航、持久化及中英文 13 个场景 | `apps/ditmesh/integration_test` |

E2E 工作流通过 PR 的 `ci:e2e` 标签或手动执行，在 macOS、Linux 和 Windows 运行。界面走查使用 `DITMESH_FAKE_BACKEND=true` 与预置会话；持久化测试通过临时文件及键，重新打开真实应用支持目录存储和平台安全存储。

必需的 Linux 和两种 macOS 原生任务运行：

```bash
python3 packages/ditmesh_chat/test/helpers/run_real_peers.py --library <built-FFI-library>
```

两个原生进程交换本地 UDP 消息、重启加密资料、恰好投递一次离线消息并重新入群。带原生标签的测试还覆盖局域网托管、节点探测、取消和当前聊天实例保留。可通过 `DITMESH_PUBLIC_DHT_SMOKE=true` 启用公网 DHT 启动检查。

视觉工作流渲染 38 个配置、76 张 PNG，覆盖十种语言、五种风格、浅深色及手机/桌面布局。捕获命令见[截图指南](../../tool/screenshots/README.zh-CN.md)。

回归测试放在能观察行为的最低层级：界面行为用控件测试，生命周期及接线用服务集成，传输用原生测试，插件用平台端到端。最新数量和 CI 链接见[验证记录](../VALIDATION.zh-CN.md)，存储行为见[持久化审计](PERSISTENCE_AUDIT.zh-CN.md)。

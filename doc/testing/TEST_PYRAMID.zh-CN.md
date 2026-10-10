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
| 平台端到端 | 实际启动、插件初始化、导航、真实触摸与实体键盘事件拍发、建群、外观、删除身份、持久化及中英文 13 个场景 | `apps/ditmesh/integration_test` |

E2E 工作流通过 PR 的 `ci:e2e` 标签或手动执行，在 macOS、Linux、Windows、Android 模拟器（API 34，x86_64）和 iPhone 模拟器上运行全部集成测试；`tool/ci/run_integration_tests.sh <device>` 可在任意设备上运行同一组测试，每个文件单独启动一次应用。界面走查使用 `DITMESH_FAKE_BACKEND=true` 与预置会话；持久化测试通过临时文件及键，重新打开真实应用支持目录存储和平台安全存储。

必需的 Linux 和两种 macOS 原生任务运行：

```bash
python3 packages/ditmesh_chat/test/helpers/run_real_peers.py --library <built-FFI-library>
```

两个原生进程交换本地 UDP 消息、重启加密资料、恰好投递一次离线消息并重新入群。带原生标签的测试还覆盖局域网托管、节点探测、取消和当前聊天实例保留。可通过 `DITMESH_PUBLIC_DHT_SMOKE=true` 启用公网 DHT 启动检查。

视觉工作流渲染 38 个配置、76 张 PNG，覆盖十种语言、五种风格、浅深色及手机/桌面布局。捕获命令见[截图指南](../../tool/screenshots/README.zh-CN.md)。

Layout 工作流在每次推送到 `master` 及每个 pull request 时分四个分片运行 `apps/ditmesh/test/layout/layout_crawl_test.dart`：以截图演示数据启动应用，从外壳的四个标签页以及聊天打开的两个练习界面（抄收练习、群组练习）出发，逐一点开所有可达的界面、对话框和底部面板。覆盖 17 种窗口配置：小屏与常规手机（竖屏、横屏、横屏弹出键盘、2 倍字号、德语、俄语）、Android 分屏半屏、iPad 分屏 1/3、平板横竖屏，以及从 360 x 640 最小窗口到 3440 px 超宽屏的桌面窗口，设备像素比 1 到 3（含 1.25、1.5、2.625）。任何溢出或约束错误、落在刘海 / 状态栏 / 主屏指示条下的文字、被截断的界面文字（应用栏标题、输入框提示 / 标签、按钮 / 标签页文字）、宽于 1100 px 的列表行 / 输入框 / 按钮都会失败。它使用 Noto 字体测量（测试字体的方块字形会让拉丁文字宽得多）。本地运行请传入 `--dart-define=DITMESH_LAYOUT_CRAWL=true`，需要真实文字宽度时再传 `--dart-define=DITMESH_MATRIX_FONT=<字体>`；`DITMESH_CRAWL_ONLY=<配置,...>` 可缩小范围，`DITMESH_CRAWL_OUT=<目录>` 为每个配置写出问题清单。未传 `DITMESH_LAYOUT_CRAWL` 时该测试跳过。它发现的每个缺陷各有一个快速用例，在 `test/layout/layout_regressions_test.dart` 中随 widget 测试运行。

回归测试放在能观察行为的最低层级：界面行为用控件测试，生命周期及接线用服务集成，传输用原生测试，插件用平台端到端。最新数量和 CI 链接见[验证记录](../VALIDATION.zh-CN.md)，存储行为见[持久化审计](PERSISTENCE_AUDIT.zh-CN.md)。

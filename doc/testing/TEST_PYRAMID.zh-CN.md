[English](./TEST_PYRAMID.md)

# 测试

初始化并解析工作区依赖后，从仓库根目录执行。端到端测试的设备 ID 可用 `flutter devices` 查看。见[工作区准备](../operations/BUILD_AND_DEPLOY.zh-CN.md)。

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
| 控件与服务集成 | 启动、身份、单聊和群聊、网络设置、参考、无线电工具、通知、桌面服务及外观 | `apps/ditmesh/test` |
| 原生集成 | 加密资料、备份恢复、持久化、局域网节点及隔离探测 | `packages/ditmesh_chat/test` |
| 平台端到端 | 实际启动、插件初始化、导航、隐私和定位界面、无线电工具计算、真实触摸与实体键盘事件拍发、建群、外观、删除身份、持久化及中英文 13 个场景 | `apps/ditmesh/integration_test` |

## 平台端到端测试与设备探针

E2E 工作流使用内存后端，覆盖 macOS、Linux、Windows、Android 模拟器（API 34，x86_64）和 iPhone 模拟器。可通过 PR 的 `ci:e2e` 标签或手动触发，手动触发时也可选 `windows_only`。本地运行同一组界面测试时执行 `bash tool/ci/run_integration_tests.sh <device-id>`，每个文件单独启动一次应用。界面走查使用预置会话。持久化测试在真实应用支持目录和平台安全存储中使用临时文件及键。定位隐私界面测试使用可控的权限和位置数据。见 [E2E 工作流](../../.github/workflows/e2e.yml)。

真实环境探针需要单独启用。运行真实网络探针前先暂存对应原生库。Flutter 集成测试的安装和卸载可能影响现有应用数据，请使用独立的测试设备或模拟器。

| `apps/ditmesh/integration_test/` 中的探针 | 运行方式 |
|---|---|
| `network_device_test.dart` | 在对应 `flutter test` 命令中加 `--dart-define=DITMESH_NETWORK_DEVICE_TEST=true`。用临时身份检查原生冷启动和重启后的网络连接。 |
| `location_device_test.dart` | 在对应 `flutter test` 命令中加 `--dart-define=DITMESH_LOCATION_DEVICE_TEST=true`。检查真实系统权限和定位提供方，报告不记录坐标。见[定位探针与互通记录](NEARBY_INTEROP.zh-CN.md)。 |
| `device_matrix_test.dart` | 手动运行的真实后端探针，观察生命周期、连接和消息事件。见[模拟器与仿真器证据](../VALIDATION.zh-CN.md#模拟器--仿真器证据2026-10-10)。 |

## 原生节点集成测试

必需的 Linux 和 macOS 原生任务在暂存原生库后运行双进程测试。在 macOS 上可从仓库根目录使用本机架构的原生库运行同一测试。

```bash
python3 packages/ditmesh_chat/test/helpers/run_real_peers.py \
  --library "build/native/macos-$(uname -m)/libtim2tox_ffi.dylib"
```

在 Linux x86_64 上，给 `--library` 传入 `build/native/linux-x86_64/libtim2tox_ffi.so`。两个原生进程交换本地 UDP 消息，重启加密身份会话，验证离线消息恰好投递一次并重新入群。双节点测试也会在 Dart 层 DHT 状态设为离线时交换群消息。带原生标签的测试还覆盖局域网托管、节点探测、取消和当前聊天实例保留。运行原生冒烟测试时设置 `DITMESH_PUBLIC_DHT_SMOKE=true` 可加入公网 DHT 启动检查。

## 视觉与布局覆盖

视觉工作流渲染 34 个配置、68 张 PNG，覆盖十种语言、四种风格、浅深色及手机/桌面布局。捕获命令见[截图指南](../../tool/screenshots/README.zh-CN.md)。

Layout 工作流在每次推送到 `master` 及每个 pull request 时分四个分片运行 `apps/ditmesh/test/layout/layout_crawl_test.dart`：以截图演示数据启动应用，从外壳的四个标签页以及聊天打开的两个练习界面（抄收练习、群组练习）出发，有界遍历可达控件、界面及覆层：递归深度 2，每次界面遍历至多 60 次点击和 20 次长按，每个动作至多 12 次重开；不声称穷举全部产品路由。采用 17 个代表窗口配置：小屏与常规手机（竖屏、横屏、横屏弹出键盘、2 倍字号、德语、俄语）、Android 分屏半屏、iPad 分屏 1/3、平板横竖屏，以及从 360 x 640 最小窗口到 3440 px 超宽屏的桌面窗口，设备像素比 1 到 3（含 1.25、1.5、2.625）。任何溢出或约束错误、落在刘海 / 状态栏 / 主屏指示条下的文字、被截断的界面文字（应用栏标题、输入框提示 / 标签、按钮 / 标签页文字）、宽于 1100 px 的列表行 / 输入框 / 按钮都会失败。它使用 Noto 字体测量（测试字体的方块字形会让拉丁文字宽得多）。本地运行请传入 `--dart-define=DITMESH_LAYOUT_CRAWL=true`，需要真实文字宽度时再传 `--dart-define=DITMESH_MATRIX_FONT=<字体>`；`DITMESH_CRAWL_ONLY=<配置,...>` 可缩小范围，`DITMESH_CRAWL_OUT=<目录>` 为每个配置写出问题清单。未传 `DITMESH_LAYOUT_CRAWL` 时该测试跳过。它发现的每个缺陷各有一个快速用例，在 `test/layout/layout_regressions_test.dart` 中随 widget 测试运行。 下述 51 个明确目标断言仅覆盖扫码、WAV 导入和按键编辑三条路径；全部有界检查无异常也不表示所有产品或原生功能通过。

## 布局宿主覆盖补充（2026-10-26）

旧爬虫把非布局插件/异步错误记为 `OTHER` 后仍通过。PR36/PR39 基线中已知宿主缺口涉及 107 个配置×场景、141 条记录：扫码事件/方向流、WAV 文件选择和按键测试的原生音频；溢出数为零不能证明这些目标成功构建。爬虫现对每条非布局异常和可见 `ErrorWidget` 失败，保留场景/堆栈，并拒绝把失败点击计为成功；原布局检查和遍历预算均不变。

每个外壳配置明确从真实联系人入口打开扫码页并断言当前 camera-view 目标，通过真实平台选择器适配层导入有效 WAV 并断言 workbench 信息/波形，再打开真实按键配置编辑页并确认测试 sink 已准备。原 TXT 报告旁的 `destinations-<profile>.json` 记录这些成功断言。宿主卸载控件后恢复扫码/文件选择全局实例，提供内存 WAV 和每页面音频工厂，保留取消、有效/无效 QR、所有权与释放回归。显式传入的音频对象仍优先；没有注入工厂时生产继续使用原生默认实现。

这证明上述控件合约，不证明真实相机权限、系统文件对话框、物理声音或完整功能/截图矩阵。纯控件宿主中其他页面可能按产品设计捕获原生音频不可用错误，实际发声仍未验证，其诊断未被压制。负例证明坏页面、游离异步异常及必需目标未到达均不能获得通过。

严格的迟到错误门禁还发现了群组练习删除操作保存完成后通过过期 Navigator 返回的问题。`groups_practice_delete_lifecycle_test.dart` 使用以内存 `InMemoryTrainingDocStore` 为底层的受控延迟文档存储，验证文档删除结果，但不能关闭后来打开的页面或访问已销毁的 Navigator，也覆盖确认框仍打开时原路由被替换。当前页正常删除、写失败后重试继续受测；成功保存后只关闭原来且仍活动的路由：当前页正常返回，被新页面覆盖时精确移除原路由，避免返回时重开已删除练习的加载器。

回归测试放在能观察行为的最低层级：界面行为用控件测试，生命周期及接线用服务集成，传输用原生测试，插件用平台端到端。最新数量和 CI 链接见[验证记录](../VALIDATION.zh-CN.md)，存储行为见[持久化审计](PERSISTENCE_AUDIT.zh-CN.md)。

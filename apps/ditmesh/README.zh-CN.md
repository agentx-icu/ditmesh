[English](./README.md)

# DitMesh 应用

DitMesh 的 Flutter 应用外壳。功能逻辑在工作区的各个包里；本应用把它们组装成响应式 Material 3
界面，主导航为 聊天 / 群组 / 参考 / 我。

| 包 | 用途 |
|---|---|
| [`ditmesh_chat_api`](../../packages/ditmesh_chat_api/README.zh-CN.md) | UI 唯一依赖的聊天契约，以及内存假实现 |
| [`ditmesh_chat`](../../packages/ditmesh_chat/README.zh-CN.md) | Tim2Tox 后端，只在 `lib/di/real_backend_factory.dart` 中构建 |
| [`morse_core`](../../packages/morse_core/README.zh-CN.md) | 字母表、时序、编码器、手键译码器、中文电码 |
| [`morse_io`](../../packages/morse_io/README.zh-CN.md) | 侧音、振动、闪光、直键与自动键 |
| [`morse_dsp`](../../packages/morse_dsp/README.zh-CN.md) | 麦克风莫尔斯译码 |
| [`morse_trainer`](../../packages/morse_trainer/README.zh-CN.md) | 抄收练习、群组练习和听抄工作台用到的练习题、评分与进度 |
| [`radio_tools`](../../packages/radio_tools/README.zh-CN.md) | 从"参考"进入的无线电工具：网格、频段、功率、驻波比、馈线、L 型匹配、射频电路、链路预算、CW 速度、RST、日出、NCDXF 信标、UTC |

## 源码布局

| 路径 | 内容 |
|---|---|
| `lib/main.dart`、`lib/di/` | 启动、设置存储、后端选择（`DITMESH_FAKE_BACKEND`）、`AppScope` / `AppServices` |
| `lib/startup/` | 隐私同意、原生库检查、身份门禁、解锁与失败界面 |
| `lib/ui/` | 各界面：`chat/`、`groups/`、`contacts/`、`reference/`、`account/`（我、备份）、`network/`、`appearance/`、`listen/`、`learn/`、`tools/`、`shell/` |
| `lib/keying/`、`lib/training/` | 电键配置与设备按键绑定；练习会话与按身份保存的练习数据 |
| `lib/nearby/`、`lib/ui/nearby/` | 定位权限、位置分享和附近发现（[说明](../../doc/reference/LOCATION_AND_NEARBY.zh-CN.md)） |
| `lib/notifications/`、`lib/lifecycle/` | 系统通知、角标、后台时限与重连（[说明](lib/notifications/README.zh-CN.md)） |
| `lib/desktop/` | macOS、Windows、Linux 的窗口、托盘与快捷键（[说明](lib/desktop/README.zh-CN.md)） |
| `lib/l10n/`、`lib/i18n/` | 十种语言的 ARB 文件与语言解析（[说明](lib/l10n/README.zh-CN.md)） |
| `test/` | Widget 与服务测试，含 `test/layout/`（布局爬虫） |
| `integration_test/` | 平台端到端测试、截图采集和按需运行的设备探针（[测试指南](../../doc/testing/TEST_PYRAMID.zh-CN.md)） |

## 运行

运行应用前，先在仓库根目录完成依赖初始化与解析。见[构建与运行](../../README.zh-CN.md#构建与运行)。

### 真实 Tox 后端

先暂存目标平台的 Tim2Tox 库。以下以 macOS 为例，从仓库根目录执行。使用其他目标时，从 `flutter devices` 的输出选择设备 ID。见[原生构建命令](../../doc/operations/BUILD_AND_DEPLOY.zh-CN.md#本机构建)。

```bash
(cd apps/ditmesh && flutter run -d macos)
```

### 仅开发界面

原生打包阶段用 `DITMESH_ALLOW_MISSING_FFI=1` 允许缺少原生库，Dart 端用 `DITMESH_FAKE_BACKEND=true` 启用内存后端。内存后端启动时没有身份，聊天列表为空。截图工具会单独载入演示会话。见[截图采集指南](../../tool/screenshots/README.zh-CN.md)。

```bash
(cd apps/ditmesh && DITMESH_ALLOW_MISSING_FFI=1 \
  flutter run -d macos --dart-define=DITMESH_FAKE_BACKEND=true)
```

### 应用检查

```bash
flutter analyze apps/ditmesh
(cd apps/ditmesh && flutter test --exclude-tags=needs-native)
bash tool/test_pyramid.sh --level e2e --device macos
```

从仓库根目录运行这些检查。端到端测试会打开真实应用窗口，并使用内存后端。全工作区检查和真实节点传输测试见[维护指南](../../doc/HANDOVER.zh-CN.md)与[测试指南](../../doc/testing/TEST_PYRAMID.zh-CN.md)。

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
| `lib/startup/` | 原生库检查、身份门禁、解锁与失败界面 |
| `lib/ui/` | 各界面：`chat/`、`groups/`、`contacts/`、`reference/`、`account/`（我、备份）、`network/`、`appearance/`、`listen/`、`learn/`、`tools/`、`shell/` |
| `lib/keying/`、`lib/training/` | 电键配置与设备按键绑定；练习会话与按身份保存的练习数据 |
| `lib/notifications/`、`lib/lifecycle/` | 系统通知、角标、后台时限与重连（[说明](lib/notifications/README.zh-CN.md)） |
| `lib/desktop/` | macOS、Windows、Linux 的窗口、托盘与快捷键（[说明](lib/desktop/README.zh-CN.md)） |
| `lib/l10n/`、`lib/i18n/` | 十种语言的 ARB 文件与语言解析（[说明](lib/l10n/README.zh-CN.md)） |
| `test/` | Widget 与服务测试，含 `test/layout/`（布局爬虫） |
| `integration_test/` | 平台端到端测试与截图采集；`device_matrix_test.dart` 是手动运行的真实后端探针 |

## 运行

先按[根目录 README](../../README.zh-CN.md) 完成 bootstrap，然后在仓库根目录执行：

```bash
dart pub get                                   # 只在工作区根目录解析
flutter analyze apps/ditmesh
(cd apps/ditmesh && flutter test --exclude-tags=needs-native)
(cd apps/ditmesh && flutter run -d macos)      # 或 linux / windows / 设备
```

`flutter run` 需要当前目标平台的 Tim2Tox 原生库（见[构建与打包](../../doc/operations/BUILD_AND_DEPLOY.zh-CN.md)）。
只做界面工作时，可以使用内存假后端（启动时没有身份、聊天为空；`tool/screenshots/` 的截图工具会预置演示会话）。
macOS 的 Podfile 在缺少原生库时会拒绝构建，除非设置 `DITMESH_ALLOW_MISSING_FFI=1`：

```bash
(cd apps/ditmesh && DITMESH_ALLOW_MISSING_FFI=1 flutter run -d macos --dart-define=DITMESH_FAKE_BACKEND=true)
```

假后端只用于测试和演示；生产构建在原生后端缺失或失败时会显示错误，而不会改为启动演示会话。
贡献规则见 [`CLAUDE.md`](../../CLAUDE.md) 和[维护指南](../../doc/HANDOVER.zh-CN.md)。

[English](./HANDOVER.md)

# DitMesh 维护指南

先阅读 [README](../README.zh-CN.md)、[网络指南](operations/NETWORK.zh-CN.md)、[构建指南](operations/BUILD_AND_DEPLOY.zh-CN.md)和[测试金字塔](testing/TEST_PYRAMID.zh-CN.md)。贡献规则见 [`CLAUDE.md`](../CLAUDE.md)。已执行的检查和当前未解决的发现项记录在 [VALIDATION.zh-CN.md](VALIDATION.zh-CN.md)。

## 仓库地图

| 路径 | 内容 |
|---|---|
| `apps/ditmesh` | Flutter 应用（[布局](../apps/ditmesh/README.zh-CN.md)） |
| `packages/ditmesh_chat_api` | 纯 Dart 聊天契约与假实现（[README](../packages/ditmesh_chat_api/README.zh-CN.md)） |
| `packages/ditmesh_chat` | Tim2Tox 后端；唯一导入 Tim2Tox/腾讯代码的包（[README](../packages/ditmesh_chat/README.zh-CN.md)） |
| `packages/morse_core`、`morse_dsp`、`morse_io`、`morse_trainer`、`radio_tools` | 莫尔斯引擎、音频译码、拍发/侧音 I/O、练习逻辑与无线电计算 |
| `third_party/tim2tox` | 固定版本的上游子模块；从不原地修改 |
| `third_party/overlays`、`third_party/stubs` | 移除原生 IM 二进制的腾讯 SDK overlay；空的 `tencent_cloud_chat_common` 桩包 |
| `tool/` | bootstrap、源码守卫、测试金字塔、图标与电码表生成器 |
| `tool/ci/` | 原生构建、打包、发布检查、[原生 overlay](../tool/ci/tim2tox-overlays/README.zh-CN.md)与 [Dart overlay](../tool/ci/tim2tox-dart-overlays/README.zh-CN.md) |
| `tool/screenshots/` | 截图与视觉矩阵采集（[指南](../tool/screenshots/README.zh-CN.md)） |
| `site/` | 公开的隐私、条款与支持页面（[README](../site/README.zh-CN.md)） |
| `doc/` | 本文档（[索引](README.zh-CN.md)） |

## 提交改动之前

运行严格分析、包与应用测试以及源码守卫（`bash tool/test_pyramid.sh --level gates`、`--level unit` 与 `--level widget`，或 [README](../README.zh-CN.md) 中的循环）。修改聊天行为时，保持纯莫尔斯输入、私聊/群组投递、加密备份恢复和排队发送都有测试覆盖。网络测试覆盖已保存节点的选择、节点探测、局域网托管、重连和释放。外观检查覆盖十种语言、五种风格以及手机/桌面布局。面向用户的文档按英文 + zh-CN 成对维护。

## CI 工作流

| 工作流 | 触发 | 覆盖 |
|---|---|---|
| Analyze（`analyze.yml`） | 推送到 `main`/`master` 及以其为目标的 PR；手动触发 | 工作流/shell lint、严格分析、复杂度/导入/UI 字面量守卫、发布版本检查、打包与截图导入回归、非原生测试 |
| Layout（`layout.yml`） | 每次推送到 `master` 和每个 PR | 分四片运行的布局爬虫 |
| Native（`native.yml`） | 涉及代码、工具、工作流或固定版本的推送与 PR；所有 `v*` tag | 原生库、应用构建、真实节点测试、安装包与草稿 Release |
| E2E、Visual matrix（`e2e.yml`、`visual-matrix.yml`） | `ci:e2e` 标签或手动触发 | 平台集成测试与截图；38 个配置的视觉矩阵 |
| Native experimental（`native-experimental.yml`） | `ci:arm` 标签或手动触发 | 可选的 ARM 主机任务 |
| Pages（`pages.yml`） | 涉及 `site/` 或该工作流的 `main`/`master` 推送；手动触发 | 公开站点部署 |

## 原生传输

原生传输补丁通过[源码 overlay](../tool/ci/tim2tox-overlays/README.zh-CN.md) 应用，Dart 服务的改动通过 [Dart overlay](../tool/ci/tim2tox-dart-overlays/README.zh-CN.md) 应用。移动 Tim2Tox 固定版本时：更新 `third_party/tim2tox` 的 gitlink，重新运行 `dart run tool/bootstrap_deps.dart`，确认 `--offline-check-only` 通过且每个 overlay 仍能应用，并更新[原始拍发节奏 RFC](rfcs/2026-10-09-keyed-rhythm.zh-CN.md) 中记录的固定版本。属于上游的修复先合入 Tim2Tox；toxee 等其他 Tim2Tox 客户端也需要同样的版本提升。

## 设备测试

设备测试时检查触摸与键盘拍发、侧音、振动、二维码扫描、通知跳转和后台恢复。用处于不同网络的对端检查 NAT 连通性。仍欠的真机检查列在 [VALIDATION.zh-CN.md](VALIDATION.zh-CN.md) 中。打包与商店配置按[发布指南](release/APP_STORE.zh-CN.md)执行。

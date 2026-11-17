[English](./2026-11-17-ditmesh-full-audit.md)

# DitMesh 全量代码审核计划

**目标** 审核 DitMesh 的完整产品功能，修复所有确认的问题，复审最终改动，并在本 PR 的 CI 通过后合并到 `master`。

**审核基线** `origin/master` 的 `0fbc204768c0a5e7a86953ea5088e8e26a7740b7`。审核功能现状和仓库维护的原生集成。PR #46 已有独立的群聊重连修复和 E2E 改动，核对其差异；若它先合并，更新本分支基线并重新核验关联问题。

## 1. 两个子 agent 并行首审

- [x] **应用功能。** 从 `apps/ditmesh/lib/main.dart`、`startup/`、`di/`、`lifecycle/` 和 `ui/shell/` 跟踪入口。检查身份创建、解锁、密码、导入导出和删除；单聊、给自己发消息、联系人、扫码、群聊和成员管理；搜索、书签、未读、离线队列在界面中的状态和操作；参考、翻译、电键配置、无线电工具、抄收及群组练习；附近、隐私、通知、语言、外观、响应式布局、快捷键与窗口/托盘。结合 `apps/ditmesh/test/` 和 `integration_test/` 检查失败路径、异步页面退出与平台差异。
- [x] **核心功能与持久化。** 审核 `packages/ditmesh_chat_api/`、`packages/ditmesh_chat/` 和 `tool/ci/tim2tox*-overlays/` 的契约与 FFI 接线、连接与重连、消息标识、回执、重试、去重、删除和重启恢复。检查加密资料、备份、群状态、网络引导和局域网。审核 `packages/morse_{core,dsp,io,trainer}/` 和 `packages/radio_tools/` 的按键时序、编解码、音频、训练和计算边界，并追踪其 app 入口。
- [x] **主 agent 补审。** 按 README、`doc/VALIDATION.zh-CN.md`、`doc/testing/` 和测试清单核对产品覆盖。检查 Android、iOS、macOS、Linux、Windows 宿主配置与权限、发布脚本、GitHub Actions、依赖覆盖层及支持站点与实际行为的一致性。汇总每个确认问题的影响、文件与行号、触发条件及验证证据。

## 2. 修复与复审

- [x] 使用 Flutter 3.41.9 / Dart 3.11.5，在根目录执行 `dart run tool/bootstrap_deps.dart` 和 `dart pub get --enforce-lockfile`。运行测试金字塔的 `gates`、`unit`、`widget` 层，记录基线情况。
- [x] 逐个核实发现的问题。使用最贴近实际入口的测试复现可复现的问题，修复后重跑并验证原行为、历史数据、失败恢复和受影响平台。
- [x] 复用首审的两个子 agent 从各自领域检查最终 diff 与回归测试。主 agent 跟踪每个确认项并检查跨模块影响。继续修复、复审，直到确认问题全部关闭。
- [ ] 重跑本地门禁、单元测试、控件测试以及改动涉及的原生或打包测试。用 `git diff --check` 和 `git status --short` 核对提交内容。记录本地硬件、签名凭证或 CI 无法验证的场景。

## 3. PR、CI 与合并

- [ ] 创建独立的审核修复 PR，基线为 `master`。在说明中列出审核范围、实际修复与测试证据，并用 `ci:e2e` 标签触发五平台 E2E 和视觉矩阵。
- [ ] 用 `gh pr checks <编号>` 和对应的 `gh run view` 核对当前 PR head 的分析、布局、原生、平台构建、E2E 与视觉结果。诊断失败并重跑可恢复失败，代码变更后重新复审并等待新 head 的 CI。
- [ ] CI 成功后合并当前已审 head，通过 `gh pr view <编号> --json state,mergeCommit,mergedAt` 以及远端 `master` 验证结果。


## 记录

- 2026-11-17 首审由两位独立 Codex 子 agent 执行。主 agent 核对产品入口、Android 和 Apple 平台权限、五个平台宿主、打包与发布脚本、工作流触发条件及公开支持页面。
- PR #46 先合并后，审核分支快进到 `4036f61b0a803011aac4c76d7198bbc8a52b23ff`。原生验证使用该基线的群组重连 overlay。
- 本轮修复覆盖账户导航与备份、共享草稿、隐藏会话恢复、位置与通知权限、扫码回调、WAV 工作台与播放、无线电计算。硬件权限、实体音频/相机和商店签名保留设备及发行流程的验证边界。

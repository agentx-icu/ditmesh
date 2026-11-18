# DitMesh 全量代码审核计划

[English](./2026-11-18-ditmesh-code-audit.md)

**目标** 从应用入口追踪到底层服务，审核 DitMesh 已交付的各项功能。修复所有确认的问题，独立复审改动，在 PR 的 CI 通过后合并。

**基线** `origin/master` 的 `5e4cc5c57071c27af784f3acf627f20e2d59089c`，包含 PR #47 和 #48。以[上轮审核](./2026-11-17-ditmesh-full-audit.zh-CN.md)和 `doc/VALIDATION.zh-CN.md` 为历史证据，记录本轮实际验证的项目。

## 1. 首审完整功能

全程最多使用两名 Codex 审核代理。首审采用只读方式。

- [x] **应用与用户流程。** 从 `apps/ditmesh/lib/main.dart`、启动、路由和四个主页入口追踪身份、备份恢复、联系人和扫码、单聊群聊、历史与队列、电键输入与播放、练习、参考内容、位置、无线电工具、隐私、通知、外观、语言和桌面操作。对照控件与集成测试，核对异常及中断场景。
- [x] **服务与功能包。** 追踪 `packages/ditmesh_chat{,_api}`、Tim2Tox 接入和覆盖层、连接生命周期、联系人与群组状态、待发送队列、回执、持久化、加密、迁移和恢复。审核应用使用的莫尔斯编码、信号处理、输入输出、练习与无线电计算及其测试。
- [x] **集成与平台覆盖。** 主审核者核对 README 功能清单、两组之间的交互、Android、iOS/iPadOS、macOS、Linux、Windows 宿主、构建与打包、CI 工作流和公开文档。对照跨平台检查清单记录各平台证据与依赖硬件的验证项。

## 2. 确认、修复和复审

- [x] 使用 Flutter 3.41.9 / Dart 3.11.5，在根目录执行 `dart run tool/bootstrap_deps.dart` 与 `dart pub get --enforce-lockfile`，再分别运行 `bash tool/test_pyramid.sh --level <gates|unit|widget>`，记录基线失败项。
- [x] 按产品约定和当前实现确认每项发现，记录触发条件、影响、代码位置和验证方法。对现有测试未覆盖的确认问题补充回归测试，从最贴近正常使用的入口验证修复。
- [x] 复用首审的两名代理独立检查改动及测试。关闭所有确认问题，重新验证并检查最终 diff。
- 运行本地门禁、功能包及控件测试和与修复相关的原生或设备检查。发布前执行 `git diff --check` 与 `git status --short`，记录影响验证的硬件或签名环境缺口。

## 3. PR、CI 与合并

- 向 `master` 创建 PR，记录确认的问题、修复和测试证据，加上 `ci:e2e` 触发 E2E 和视觉矩阵。
- 通过 `gh pr checks` 和 `gh run view` 核对已审 PR head 的检查。排查失败，重试临时故障，对新增提交重新复审和验证。
- CI 通过后按已审 head 合并。核实 PR 的合并状态和远端 `master` 上的合并提交。

## 发现与回归验证

| 范围 | 问题与修复 | 证据 |
| --- | --- | --- |
| 异步导航 | 群组、好友、电键配置和节点操作只关闭各自发起的页面。创建群组仅在群组页可见时自动打开会话；电键配置写入失败时保留已保存的绑定。 | `chat_sheet_route_test.dart`、`key_setup_page_test.dart`、`key_profiles_test.dart`、`bootstrap_nodes_page_test.dart` |
| 聊天历史 | 屏蔽后隐藏的消息保留书签。清空或删除历史会刷新已打开的会话、搜索和待发送列表。磁盘删除失败会提示错误；有未处理的排队消息时保留历史和发送操作。 | `message_management_ui_test.dart`、`chat_service_test.dart` |
| 群组发件箱 | 传输接受排队的群消息时发布状态更新，对端未发回执也能更新界面。 | `group_dht_reconnect_test.dart` |
| 扫码 | 重试失败的启动时重新创建控制器，仅可见的扫码页面占用相机。 | `qr_scan_lifecycle_test.dart` |
| 音频和备份 | 停止实时收听时提交最后一个拍发信号。仅导出录音时随加密备份保存资料库索引，预览只统计录音。仅恢复练习数据时可看到笔记并重新关联缺失的录音。 | `listen_controller_test.dart`、`workbench_screen_test.dart`、`encrypted_backup_test.dart` |

各发行平台的覆盖包括宿主源码审核和 PR 的自动化平台矩阵。实体相机权限变更、有线和蓝牙音频路由、商店签名仍需对应设备或发行环境验证。

## 变更记录

- 2026-11-18 — 按当前默认分支和仓库验证矩阵创建计划。两名 Codex 审核代理分别首审应用与服务，随后交叉复审改动。

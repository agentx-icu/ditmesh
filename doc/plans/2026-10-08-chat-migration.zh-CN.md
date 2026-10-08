# DitMesh / MorseCQ 拆分实施方案

目标：DitMesh 承接完整 Morse-only Tox 单聊与群聊；MorseCQ 成为安装即用、没有账号或注册的离线学习应用。用户于 2026-10-08 批准此设计。完整文件分工与验收步骤见[英文实施方案](./2026-10-08-chat-migration.md)。

## 架构与产品边界

DitMesh 复用 MorseCQ 的 Morse 引擎、电键 I/O、聊天契约与 Tim2Tox 适配层。主导航为聊天、群组、参考、我的。移植联系人、二维码、好友请求、群组邀请与成员、历史搜索、书签、离线队列、重试与取消、通知、屏蔽、账号备份恢复。聊天只能通过触摸或键盘直键/双桨生成消息，草稿只读；保留现有纯文本 Tox 线路兼容性和聊天辅助练习。

MorseCQ 保留学习、听音、音频译码、参考、统计与无线电工具。删除聊天后端、身份服务、注册、聊天导航、Tim2Tox/Tencent 依赖和原生库绑定。学习数据使用本地目录，保证当前学习进度、设置和录音的持久化。两款应用均未发布，不实现旧版本数据迁移。

DitMesh 标识为 `icu.agentx.ditmesh`，MorseCQ 使用 `icu.agentx.morsecq`；两个应用不自动共用账号、通知或数据目录。

## 工作区

- DitMesh：`/Users/bin.gao/chat-uikit/ditmesh`，`codex/chat-migration`。
- MorseCQ：`/Users/bin.gao/chat-uikit/morsecq/.worktrees/offline-learning`，`codex/offline-learning`。
- 保留 MorseCQ 主目录两份未提交的学习评审文件和现有 pedagogy worktree。
- 不使用 RTK；不调用 Claude 或进行 Claude 评审。采用本地检查与独立 Codex 子代理评审。

## 实施与验收

1. 以 MorseCQ `3ce9597` 和 Tim2Tox `093730ce346cef186bfd3d71214343b38d6c5ca6` 为迁移基线，只复制受版本管理的源码，不复制构建产物。
2. 在独立 worktree 删除 MorseCQ 账号与网络依赖，先增加首次启动与当前学习持久化回归测试，再修改实现。
3. DitMesh 全面改名、隔离数据目录、保留完整聊天功能与电键输入；原生后端失败必须向用户显示，生产构建不能静默切换为演示聊天。
4. 完成 Android、iOS、macOS、Linux、Windows 原生及应用构建、安装包与 CI。发布前必须通过分析、测试与必要平台构建；tag 生成带校验和的 GitHub 草稿 Release。
5. 更新双方中英文 README、隐私与支持页面、应用职责/构建/发布文档、真实 UI 截图和产品设计图。无法本机运行的平台由 CI 捕获，不能把旧截图作为新产品截图。
6. 汇总独立评审，修复问题，运行最终分析、分层/本地化/复杂度检查、适用测试及本机构建，并准确记录验证结果。

## 同时处理的待办

应用标识、通知与存储隔离；无账号本地学习持久化；生产原生库失败提示；Release 前测试门禁；截图场景与文档链接；离线应用不需要的原生依赖与权限。

## 外部限制

真机延迟、触感和摄像头验证需要实体设备；Apple/Android 商店签名和 Apple 公证需要所有者凭据。实时 Tox 互通需要两个可达节点。实验性的 Windows ARM / Linux ARM 构建需要单独标明结果。不会自动合并 PR、创建发布 tag 或上架。

## 变更记录

- 2026-10-08：依据用户批准的双应用拆分方案创建；明确范围、工作区、发布门禁与验证边界。

## 2026-10-08 范围更新

用户明确两款应用均未发布，不需要历史版本兼容。旧学习目录/ZIP 导入、MorseCQ 旧备份兼容及对应测试与文档从实现中移除；保留当前 DitMesh 备份恢复和无账号本地学习持久化。此前计划中的历史迁移要求由本条替代。

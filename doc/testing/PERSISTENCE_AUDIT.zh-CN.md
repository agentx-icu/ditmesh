[English](./PERSISTENCE_AUDIT.md)

# 持久化审计 — 2026-10-01

在基于 `3972bc6` 的 `codex/persistence-audit` worktree 中进行。审计覆盖五个
发布平台共用的 Dart 实现，以及可运行平台的原生存储插件。测试使用独立账号、
临时目录和临时偏好键。

## 存储清单

`<support>` 表示 `path_provider` 返回的应用支持目录；`<identity>` 为
`<support>/ditmesh/identity`。用户数据不依赖进程当前目录，也不写入安装包内部。

| 需要保留的内容 | 生产存储 | 范围与重启行为 |
|---|---|---|
| Tox 身份、好友关系、原生群组成员关系与原生资料 | `<identity>/profile/tox_profile.tox` | 真实 Tox 引擎恢复 savedata。设置密码时，停止运行的资料加密；运行中的引擎需要解密后的 savedata。 |
| 昵称、状态、Tox ID、密码标志 | `<identity>/identity.json` 与原生自身资料 | 原子替换记录、串行修改原生资料与记录；损坏记录不会导致启动检查崩溃。 |
| 密码校验信息 | 按身份分键的 `flutter_secure_storage` | 使用原生 Keychain/Keystore/桌面安全存储；密码与资料事务失败回滚校验信息；中断换密码后由加密资料修复过期校验信息。 |
| 消息历史、已读标志及好友/群组未读数 | `<identity>/data/chat_history/` | 延迟保存支持显式 flush；群组未读数从持久化历史恢复。 |
| 好友/群组离线发送队列 | `<identity>/data/offline_message_queue.json` | 重启后保留队列，并据此恢复“待发送”，避免误报“已发送”。 |
| 待处理好友申请、拒绝记录 | 按账号隔离的 `shared_preferences` | 保留申请文本与时间；旧单账号全局拒绝列表迁移一次，删除/替换账号时清理。 |
| 群组邀请、名称/类型/chat ID、退群记录、联系人资料、已读回执及其他 Tim2Tox 偏好 | 按账号隔离的 `shared_preferences` | 连接时恢复原生与宿主元数据；清理包括后缀键、完整 Tox ID 的草稿及回执键。 |
| 会话草稿、置顶、隐藏会话 | 按账号隔离的 `shared_preferences` | 可离线修改；输入草稿在后台/退出前保存，已替换账号的旧编辑器不能写回。 |
| 课程进度、SRS 卡片、训练统计与历史 | `<identity>/training/training/progress.json` | 保留原有目录布局；新控制器加载已提交数据；无效文档恢复有效的上一次备份。 |
| 训练默认值、播放/教学参数 | `<identity>/training/training/settings.json` | 按账号隔离、校验、串行保存，包含在学习备份中。 |
| 外观风格和明暗模式 | `<support>/settings.json` 中的 `appearance.preferences` | 两者一起保存成功后才生效；失败时保留原选择。兼容旧 `app.theme`，后台和退出等待外观写入完成。 |
| 语言、通知隐私/声音、聊天速度/音调/训练模式/输入方式、参考播放、麦克风解码设置 | `<support>/settings.json` | 暴露 provider 前恢复；保存失败保留待保存快照，后续 flush 重试；其他键成功不能掩盖失败。 |
| 屏蔽通知的会话 | `settings.json` 中的 `notifications.muted.<完整公钥>` | 按账号隔离，仅在删除/替换成功后清除；恢复失败保留原屏蔽列表。 |
| 窗口位置/尺寸/最大化、关闭至托盘、托盘声音选择 | `settings.json` 中的桌面键 | 恢复时校验显示器范围；选择保存失败回退模型以允许重试；退出等待在途偏好写入。 |
| Bootstrap 与下载偏好 | 全局 `shared_preferences` | 删除/恢复账号时保留；可选文件传输、头像宿主数据位于 `<identity>/data/`，不属于 v1 界面功能。 |

当前音频播放、麦克风流与缓冲区、按键状态、网络在线状态、当前页签、翻译器临时
文本、未完成练习答案属于本次会话状态。已完成的训练及用户选择的解码/播放设置
需要持久化。普通偏好中不保存密码。

## 已验证并修复的问题

- 将原先仅在内存中的 App 设置接入已有设置文件，包括输入方式、参考播放、
  麦克风手动调频。
- 按文件路径串行执行 JSON 读写/删除，捕获不可变快照；重置及迟到保存不能复活
  旧进度；语法、结构、数值校验保留有效备份。
- 串行修改身份，导入时先完整写入暂存目录；资料/密码失败回滚；导入失败不会
  发布空身份，也不会提前清除原账号的通知屏蔽设置。
- 增加后台、导出、替换、删除的持久化屏障；替换前停止旧控制器/编辑器写入；
  失败时恢复旧账号。独立存储全部尝试 flush；桌面退出遇到未解决保存错误时中止。
- 保存待处理好友申请，修复账号清理/旧键迁移；真实重启后根据持久化离线队列
  正确恢复消息状态。
- 真实复现 macOS Keychain `-34018`，按插件支持方式改用适合当前无 provisioning
  分发方式的 legacy Keychain；iOS 保留数据保护 Keychain 并声明 Keychain Sharing。
- 将临时原生存储测试加入测试金字塔；Linux e2e CI 为 Secret Service 测试启动
  隔离 D-Bus 会话和已解锁的 GNOME Keyring。

## 验证结果与边界

最终检查：**477 项 App 测试**、**401 项包测试**（包括最终 71 项后端测试）、**2 项原生 Tox 测试**通过。三个可运行平台的原生存储测试各 **4 项**通过。七个包/应用分析器均为**零问题**；500 行复杂度、导入守卫、ARB 同步与 `git diff --check` 全部通过。

日志保存在本 worktree 的 `build/persistence-audit/`：`app.log`、`packages.log`、`chat.log`、`native-tox.log`、`macos.log`、`ios.log`、`android.log`、`gates.log` 及外部评审日志。可通过 `tool/test_pyramid.sh --level unit`、`--level widget`、`--level gates`、`--level e2e --device <id>` 重跑对应检查；原生 Tox 测试设置 `TIM2TOX_FFI_LIB` 后，在 `packages/ditmesh_chat` 执行 `flutter test --tags=needs-native`。

| 平台 | 已执行的验证 | 尚未执行的原生覆盖 |
|---|---|---|
| macOS arm64 | 4 项真实存储集成测试；真实 Tox 加密账号、好友、NGC 群组、队列、历史、草稿、置顶重启回归 | 未执行断电/强杀进程测试 |
| iOS 18.4，iPhone 16 Plus 模拟器 | 4 项真实文件存储、Keychain、原生偏好重读测试 | 未测试实体设备及真实 Tox 重启 |
| Android 16 / API 36 arm64 模拟器 | 4 项真实文件存储、安全存储、原生偏好重读测试 | 未测试实体设备及真实 Tox 重启 |
| Windows | 共用 Dart 回归；核查插件注册、可写支持目录和构建前提 | 当前无 Windows 主机，未运行原生测试 |
| Linux | 共用 Dart 回归；核查插件注册、XDG 目录、Secret Service 前提；CI YAML/shell 静态检查 | 当前无 Linux 主机，未运行原生测试及修改后的 CI job |

集成测试新建存储对象并重读原生偏好，避免仅靠进程缓存通过测试；不表示已验证
断电或强杀进程。JSON 备份处理损坏/不完整文件；跨多个文件与安全存储的账号更新
不是文件系统级 ACID 事务。Windows 安全存储插件需要 Visual Studio C++ ATL；
Linux 除 `libsecret` 构建头文件外，还需要运行中、可访问的 Secret Service/keyring。

现有身份导出格式包含身份记录、Tox 资料和学习文件，**不包含**聊天历史、离线
队列、账号偏好与全局设置；恢复会替换本地账号数据并清理旧账号偏好。这是身份与
学习备份，不是整台设备的完整备份。

操作系统应用支持目录不可用时，已有启动逻辑会回退到内存偏好并记录错误；
该回退不能保留重启后的设置。

已按要求请求只读 Claude Opus 方案评审，并使用相同参数重试，但评审账号达到
会话限额导致失败。实际最终 diff 评审及相同 Opus 参数重试也因
`You've hit your session limit` 失败（退出码 1，session-end hook cancelled）。
没有外部评审成功。上述本地检查全部完成；独立代码复核发现的问题已复现、修复并
补回归。两次实际 diff 评审输出见 `build/persistence-audit/diff-review.log`。

## 提交/合并验证

提交前重跑：App 使用 `--concurrency=1`，477 项通过；后端 71 项通过；两处
分析器零问题，项目门禁通过。默认并发 App 重跑在未修改的账号测试辅助代码中
出现两个计时失败：SnackBar 退场回调在测试清理后执行、真实 I/O 加载时
`pumpAndSettle` 超时。其 `settle()` 在 `runAsync` 内推进帧，Flutter 在该区域
使用真实定时器。引导页 6 项单独运行通过。并发测试辅助代码问题尚未修复；
单并发执行给出本次已验证的提交前结果，未改变产品行为。日志与其余审计证据
一起保留。


## GitHub master 整合

将 master `2042b63` 与持久化提交 `e750aeb` 整合，保留五种外观风格、
Modern Calm 默认样式和更新后的截图。新外观记录优先于旧 `app.theme`；
记录缺失或损坏时保留旧主题。App/账号生命周期 flush 等待外观写入完成；
外观写入失败时保留原选择，并可显式重试。

整合后重新验证：**512 项 App 测试**（`--concurrency=1`，另有 1 项原有
跳过测试）、**401 项包测试**、**12 项截图导入测试**、**2 项原生 Tox 测试**
和 **4 项 macOS 存储测试**全部通过。七个分析器及复杂度、导入、ARB、
diff/格式门禁通过。外观文件重启回归直接使用真实异步 I/O；界面覆盖和
等待未完成外观写入的退出屏障测试仍保留。前文 iOS/Android 证据来自原始
审计，本次合并未重新执行其原生套件；Windows/Linux 原生覆盖限制仍如前述。

Opus 整合方案评审及相同参数重试因评审账号会话限额失败。整合证据保留在
`build/persistence-audit/remote-merge-*.log`。原工作区 19 个未提交的安装包
文件已逐字节核对，内容未改变。

最后的整合实际 diff Opus 评审及相同参数重试也均因 `You've hit your session limit`
失败（退出码 1），未获得外部评审结果；上述本地验证均已通过。两次尝试记录
于 `build/persistence-audit/remote-merge-diff-review.log`。

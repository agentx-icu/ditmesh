[English](./CROSS_PLATFORM_AUDIT.md)

# 跨平台审计与修复 — 2026-10-22

接手会话 `2040fe6b-e1a5-4700-b27d-83749f68844b`，从 DitMesh `879d1d5` 的现有 `agentx/xplat-checklist-audit` worktree 继续。目标为 Android、iOS/iPadOS、macOS、Windows、Linux；工具链 Flutter 3.41.9 / Dart 3.11.5，Mac arm64，Xcode 26.4.1。

本报告区分源码判断、单元/widget 测试和真实设备行为。`verified` 只表示证据列明确列出的范围；`needs device` 仍需实机或对应系统；`to do` 是尚未完成的工作；`not applicable` 有具体不适用原因。历史证据保留在 [VALIDATION.zh-CN.md](../VALIDATION.zh-CN.md)，不改写旧版本的验证记录。下表保留标准 ID、英文状态和代码/检查名称，便于与英文报告及技能交叉检索。

商店后续审计（2026-10-23）：[当前渠道、P4/P8/P9/W4/X6 证据与负责人阻塞](../release/STORE_READINESS.zh-CN.md)。此记录不覆盖下方历史验证。

## I2 后续：活跃外壳快捷键（2026-10-23）

`desktop/shell_shortcuts_test.dart` 在使用假后端的完整 `DitmeshApp` 中发送真实 Flutter
按下/抬起/重复事件，覆盖 macOS、Windows、Linux 平台变体：正确/错误修饰键、按住只请求一次、
现有搜索与筛选词焦点、从其他页选中聊天、复用联系人路由/返回，以及文本编辑、IME、对话框保护。
既有纯映射测试仅作补充。当前外壳只安装 K/N，Shift+M 因无共享侧音所有者继续未绑定；本地化
提示展示 K/N。Widget 平台变体不等于实体键盘/触控板、非美式布局、iPad 全键盘控制和 iPadOS 26
原生菜单栏验证。

## 已确认并实施

- 桌面启动先锁定整个应用支持目录，再打开设置、迁移和后端；第二进程请求激活原窗口，锁文件不删除，锁持有到进程结束。使用独立子进程验证争用、激活和崩溃释放。
- Linux 隐藏窗口前确认实际托盘宿主；默认关闭时退出，可在“我”页设置关闭到托盘；没有声音控制回调时不显示无效菜单。分别保存正常窗口尺寸，框架退出等待同一会话保存屏障，补充 Mac Dock 重开通道。
- 扫码页使用插件自己管理的 controller，恢复自动暂停/恢复相机；平台假实现测试明确观察到 inactive 停止、resumed 重启，真实相机隐私指示仍待验证。
- 从解码、文件写入和训练 controller 加载三层拒绝未来版本的身份、训练进度/设置、音频资料和群练习数据；替换前分别检查主文件和备份。历史 overlay 保留新格式数据并保持 receipt 持久化顺序；身份与学习错误均有十种语言的升级提示。
- 把全屏闪烁改为小范围灯号并遵循减少动态效果；探测振动硬件；解释 Linux 录音工具缺失；移除默认未使用的手电筒插件，保留显式 TorchApi 注入。
- 备份、诊断、待处理消息、群练习使用系统 12/24 小时时间格式；静音快捷键避开 Cmd+M；生成更大的托盘位图。
- 补齐 Linux 实际启动的录音和宿主探测工具依赖；Android tag 构建缺少正式签名输入时拒绝构建，分支验证仍可运行。
- 修正已有重传测试的时序：等 ACK 真正发出和队列真正排空后再断线，不能用可见消息或 500ms 安静推断持久化完成。

## 验证边界

最终本地验证（已完成交叉复查）：

- 七个 package 完整测试 **1,250 通过**，两个既有 DSP 可选测试跳过。
- 应用完整测试 **1,500 通过**，36 个可选布局/截图测试跳过。包含独立进程锁/激活/崩溃释放、扫码暂停恢复、未来 schema/备份、退出失败重试和系统时间格式回归。
- 所有 package、app、tool 静态分析零问题；复杂度、import、UI literal 门禁通过。移除测试中的多余 import 后再次确认 app 分析通过，之后没有生产代码变化。
- Android 签名输入、发布配置与 macOS runtime 检查 **19 通过**。打包 fixture 使用命令级 Xcode `SDKROOT`，因为宿主默认 CommandLineTools SDK 27 与 Xcode 26.4 链接器不兼容。
- 最终 Mac release UI 构建通过，**32.8 MB**；overlay 离线 stamp 检查和 `git diff --check` 通过。

交叉复查实际复现了“当前主文件 + 未来版本备份被覆盖”和“Android 显式 12 小时制搭配 24 小时语言”的问题，现均有通过的回归；训练与历史升级错误也已映射为可操作的 UI 提示。

Mac release UI 构建使用 `DITMESH_FAKE_BACKEND=true` 和 `DITMESH_ALLOW_MISSING_FFI=1`，用于编译 Dart、插件和 AppDelegate，不代表真实 Tox 后端或已签名发布包通过。上游 Tim2Tox 子模块保持只读，兼容补丁通过可重复的应用 overlay 应用。

| ID | 状态 | 证据 / 待验证项（对应英文报告） |
| --- | --- | --- |
| L1 | verified | Widget layout regressions cover phone/window stress sizes; native matrix remains separate. |
| L2 | verified | ui/responsive.dart and chat/chat_layout.dart use current window width; resize widget tests. |
| L3 | needs device | Real OS rotation/fold/display changes across breakpoints; existing simulator evidence is in VALIDATION.md. |
| L4 | needs device | Widget safe-area tests pass; inspect real cutouts, system/caption bars and iPad windows. |
| L5 | needs device | Keyboard widget profiles pass; floating/split iPad keyboards still need hardware. |
| L6 | needs device | Android/iOS orientation declarations inspected; OS-imposed rotation and resizable-window checks owed. |
| L7 | verified | Layout regression suite exercises bounded dialogs, sheets and scrollable content. |
| L8 | needs device | Separating fold/occluding hinge and posture preservation require a foldable profile. |
| D1 | verified | Existing text-scale layout regression coverage; largest OS accessibility categories still need device checks. |
| D2 | verified | Ten ARBs, translator metadata and generated messages validated by arb_consistency_test.dart. |
| D3 | needs device | 36px macOS template and 64px Linux tray rasters generated; mixed fractional-scale inspection owed. |
| D4 | needs device | Move the installed window between mixed-DPI monitors and change scale while running. |
| D5 | needs device | Platform asset tests and new raster sizes cover declarations; inspect actual installed tray/icons. |
| D6 | needs device | Light/dark source and widget cases reviewed; measured contrast and OS color filters remain owed. |
| D7 | verified | morse_io flash_overlay_test.dart: bounded lamp, reduced-motion steady indicator and input passthrough. |
| I1 | needs device | Touch/focus widgets reviewed; measure every essential control on smallest supported device. |
| I2 | needs device | `desktop/shell_shortcuts_test.dart` 已以 macOS/Windows/Linux 变体的键盘事件、路由和 IME 回归验证活跃 K/N；Shift+M 未绑定，原生输入与 iPad 菜单仍待完成。 |
| I3 | not applicable | Morse composer is read-only and sends keyed input; ordinary text fields do not use Enter-to-send. |
| I4 | needs device | PopScope/source and prior Android back evidence reviewed; release predictive-back/iOS gestures owed. |
| I5 | needs device | Semantics/keying tests pass; VoiceOver, TalkBack, Narrator and Orca end-to-end flows remain owed. |
| I6 | verified | i18n/system_date_time_test.dart verifies locale date order plus system 12/24-hour behavior. |
| I7 | verified | morse_io key cancellation, held-key and focus/semantics regressions run in package tests. |
| I8 | not applicable | No verified HTTPS deep-link entry point is advertised; Tox IDs are copied/scanned in-app. |
| I9 | needs device | Backup gateway consumes picker bytes immediately and bounds reads; real share/provider grant lifetime owed. |
| B1 | verified | qr_scan_lifecycle_test.dart exercises camera stop/resume; Listen and training lifecycle policy tests. |
| B2 | verified | Application preference, outbox, training and receipt write barriers covered by service/filesystem tests. |
| B3 | needs device | Cold notification taps, OS process kill and interrupted picker recreation need installed-device checks. |
| B4 | to do | No guaranteed mobile background delivery. Existing Android budget estimate needs conservative policy/device confirmation. |
| B5 | needs device | Desktop independent-process contention/activation/crash-release passes; Android multi-engine/iPad scenes owed. |
| B6 | verified | Durable outbox/receive/ownership tests, including waiting for actual ACK transmission before simulating loss. |
| B7 | verified | Future identity, owned training documents and history reject incompatible reads/writes; primary plus future-backup regressions preserve both files (overlay 0015). |
| B8 | verified | Offline durable queue, send intents, identity isolation and replacement tests; no central server conflict model. |
| P1 | needs device | Optional camera/microphone and Apple purpose strings/entitlements inspected; merged release declarations owed. |
| P2 | needs device | QR/Listen/notification denial tests cover UI policy; native denial/revoke/recovery flows owed. |
| P3 | verified | QR error and notification/channel fallback regressions plus unavailable-haptics hardware probe tests. |
| P4 | to do | Privacy manifests exist; owner must reconcile final SDK manifests, store privacy answers and release identity. |
| P5 | needs device | Encrypted backup/secure-store tests run; Android auto backup remains intentionally disabled for Tox identities. |
| P6 | needs device | Picker is consumed immediately; cloud/removable providers and restart/revoked-grant paths still need testing. |
| P7 | to do | No universal capture-prevention claim. Define and validate chat/app-switcher snapshot policy per platform. |
| P8 | not applicable | No purchases, subscriptions or paid entitlements. |
| P9 | to do | Persistent blocking/terms/support links exist; no actionable moderator report pipeline or verified store-console answers. |
| M1 | needs device | Audio session/source behavior and leases tested; physical silent switch/focus/interruption checks owed. |
| M2 | needs device | Real wired/Bluetooth/speaker route changes and disconnections. |
| M3 | needs device | Mocked QR lifecycle regression passes; confirm OS privacy indicator stops on real devices. |
| M4 | verified | App sends Morse/text and encrypted backup bytes; cross-platform backup/format unit coverage. |
| M5 | verified | Backup reads bounded by maxBackupFileBytes; microphone PCM is streamed; no full-size chat photo/video decode. |
| M6 | needs device | All five OS notification backends configured; source/service tests do not prove installed toast/tap behavior. |
| M7 | needs device | Optional hardware declarations and haptics probe; camera-less/Chromebook/XR native paths require devices. |
| M8 | not applicable | No screen/system-audio/remote-input capture feature. |
| W1 | needs device | Pure work-area and normal/maximized/fullscreen/minimized persistence tests; native mixed-DPI/Wayland checks owed. |
| W2 | needs device | Tray-host capability, default close-to-tray off and awaited quit tested; native close/reopen/logout checks separated. |
| W3 | verified | Application-support/temp paths, atomic file writes and desktop root ownership; no writes next to executable. |
| W4 | to do | Formal Apple/Windows signing/notarization and clean installer lifecycle checks require owner configuration/platform hosts. |
| F1 | to do | Measure release frame pacing at actual refresh rates and realistic conversation sizes. |
| F2 | to do | Record per-platform startup/install/download budgets and actual release measurements; macOS UI build size is only one sample. |
| F3 | needs device | Adaptive Tox event polling and audio/wake leases reviewed/tested; battery/thermal behavior requires hardware. |
| X1 | needs device | All five shipping targets reviewed; real phone/tablet/foldable/desktop device matrix is incomplete. |
| X2 | verified | Application layout regressions run; opt-in 17-profile crawl/visual matrix has separate CI evidence. |
| X3 | needs device | Widget resizing is not an OS rotation/fold/display test. |
| X4 | verified | This report explicitly separates mocked/widget/source evidence from installed/device behavior. |
| X5 | verified | Shared schema/flash/haptics fixes reach mobile and desktop; MorseCQ-only backup changes are not copied to chat. |
| X6 | to do | macOS release UI build compiles native changes; real-backend packaging/install/upgrade matrix still owed. |
| X7 | needs device | Interrupted OS UI, permission revocation and background process death still need a device campaign. |
| X8 | needs device | Existing network/DHT tests and VALIDATION.md retained; carrier NAT64/VPN/captive portal/device handover owed. |
| X9 | to do | Connection diagnostics exist; production application/native crash collection and readable archived-symbol process incomplete. |

## 仍需完成

以上表格同时是待办清单。正式签名/公证、Windows/Linux 安装运行、手机和平板实机、商店后台问卷、举报接收和响应机制，都不能用本地测试假称完成。屏幕捕获和后台消息保证需要明确产品策略。DitMesh 继续采用 Tox 身份的加密导出迁移方案，不照搬 MorseCQ 的离线学习数据自动备份配置。

2026-10-22 核对的一手资料：[Dart 文件锁语义](https://api.dart.dev/dart-io/RandomAccessFile/lock.html)、[Android 应用签名](https://developer.android.com/studio/publish/app-signing)、[Apple UGC 要求](https://developer.apple.com/app-store/review/guidelines/#user-generated-content)。已安装 mobile_scanner 7.4.2 源码明确说明，只有 widget 自己拥有 controller 时才自动观察生命周期；record_linux 1.3.1 会启动 parecord/pactl 进程，ELF 依赖扫描无法发现这些工具。

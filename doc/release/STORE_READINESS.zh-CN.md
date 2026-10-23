[English](./STORE_READINESS.md)

# 发行渠道与商店审计 — 2026-10-23

范围：基于 `7d45e048fd786b1779d98d6a78bec4b658a8ea60` 的现有发行链和本 PR 预检修复。[此前 65 项审计](../testing/CROSS_PLATFORM_AUDIT.zh-CN.md)仍记录其他 UI/生命周期工作。本轮没有提交商店、确认账号归属、购买证书、上传公证或取得上架批准。PR 绿色只能证明仓库与所构建制品的检查通过，不能宣称 DitMesh 已具备上架条件。

## 渠道矩阵

“阻塞”表示发布负责人须补证据或决定产品范围；未来渠道不等于当前发行承诺。

| 渠道 | 现有制品 / 适用范围 | 负责人仍需完成的门禁 |
|---|---|---|
| GitHub draft Release | 既有路径：Linux x86_64 DEB/RPM/tar；Windows x64 MSI/ZIP；macOS ARM64/Intel PKG/ZIP；Android APK/AAB；未签名 iOS IPA。校验和证明字节，不证明发布者身份。 | 人工发布前核各 Native CI、干净安装/升级/卸载与真机证据。macOS 为 ad-hoc 签名，Windows 未签名，分支 Android 可用 debug key，iOS 需要签名。 |
| App Store：iOS/iPadOS | 源码 App ID 为 `icu.agentx.ditmesh`；未签名 IPA **不是** App Store archive。 | 确认 team/应用归属、分发描述文件、设备 archive、当前 SDK 要求、TestFlight、隐私/年龄/出口问卷、审核访问以及下述 UGC/删除阻塞。iPad 截图、方向/多任务/popover 需设备证据。 |
| Mac App Store | 独立未来路径；已有沙盒/相机/音频/网络/文件 entitlements，没有商店 archive/签名链。 | 商店身份/描述文件、沙盒下 peer/bootstrap/文件选择测试、隐私与 SDK 清单、审核访问和素材。Developer ID 证书/公证不能替代此路径。 |
| macOS 站外 Developer ID | 当前 PKG/ZIP 为 ad-hoc 验证包；检查最终 bundle 完整性与 Release 权限。 | Developer ID Application/Installer 身份、hardened runtime/library validation 评估、最终由内到外签名、PKG 签名、公证/staple、干净 Mac 上隔离属性下的 Gatekeeper 安装。本 PR 不上传 Apple 公证服务。 |
| Google Play | 已构建 AAB；tag/distribution 强制核负责人提供的**上传**证书 SHA-256，并与 APK 签名匹配。 | Play 账号/应用/密钥归属、Play App Signing 独立的**交付**证书与升级链、内容/target/device 要求、当前账号适用的测试前置条件、Data safety、UGC/删除与审核访问。此处 APK/AAB 相同证书仅是 CI 合约，不表示 Play 交付 APK 使用上传密钥。 |
| Microsoft Store HTTPS MSI/EXE | 现有 x64 MSI 可评估非游戏托管安装器路径；尚无商店提交配置。 | Partner Center 身份、不可变版本化 HTTPS 安装器、离线/静默安装、MSI 和**所有内嵌 PE 文件**的受信 CA 签名、隐私/年龄/审核材料、干净安装/更新/卸载。实际 MSI 元数据门禁检查 x64。 |
| Microsoft Store MSIX | 未选择，无 MSIX manifest/packager；对当前 MSI 路径不适用。 | 选择后需预留 package identity/publisher、capabilities、架构、WACK、升级/数据迁移及 Store 签名流程。不能把托管 MSI 的签名要求替代 Store-signed MSIX 规则。 |
| Linux 直接软件包 | 已有 DEB/RPM/tar，不是沙盒商店应用。 | 逐发行版核依赖/desktop 文件/图标、升级/数据保留，并记录真实架构元数据和来源；不宣称 Linux 全渠道统一要求发布者签名。 |
| Flathub | 未来选项；没有生成 Flatpak/Flathub manifest 或提交。 | 人工维护者按当前政策编写、核验实际提交；评估强制 app ID/license/metadata/runtime/权限与网络/音频/相机/文件 portal，分开记录可选质量徽章。沙盒安装/更新和 peer 联网仍未验证。 |
| Snap Store | 未来选项；没有 snapcraft 配置或账号证据。 | 名称归属、confinement/interfaces、特权连接审核、桌面集成、商店安装后运行和 refresh/channel 测试。DEB/RPM 检查不覆盖 snap 沙盒。 |
| 国内 Android：华为 AppGallery / 小米 | 仅为代表性未来候选；未确认控制台、账号或地区选择。 | 人工发布者先选择渠道/地区，再核官方控制台的签名/升级身份、隐私/SDK/权限、内容/支付/删除及适用备案/资质要求。不能由界面语言推断法律适用性，也不要求进入每个国内渠道。本次未完整读取动态官方页面；登录后的政策核验仍 **to do**。 |

## Checklist 状态与仓库证据

沿用 checklist 状态词；某个自动子检查通过不会解除商店阻塞。

| ID | 状态 | 证据 / 边界 |
|---|---|---|
| P4 | to do | iOS 与新增 macOS app manifest、原生插件 manifest、`site/` 公共政策源码。应用自己的偏好经 `SharedPreferencesStore` 保存（`packages/ditmesh_chat/lib/src/adapters/key_value_store.dart`，CA92.1）；备份稳定性检查读取应用容器 `File.lastModified()`（`identity_backup_v2.dart`，C617.1）。macOS Runner 资源阶段包含 manifest，打包检查真实 bundle 资源。负责人仍须逐 SDK/原生库核实并对齐商店表单，包括 bootstrap HTTP/IP 暴露与 P2P 接收者。app collection 空数组不证明第三方行为。 |
| P8 | not applicable | 当前无购买、订阅、广告或付费数字权益。增加变现前重开，按所选商店/地区核支付规则。 |
| P9 | to do | 已有条款接受、本地身份删除、持久屏蔽与支持链接；没有可实证的举报处理/响应/移除运营流程或商店控制台分类。P2P 不会自动豁免聊天的 UGC/账号删除政策。 |
| W4 | to do | `package_artifacts.sh` 核五平台 staging payload 的真实原生头；`native_payload.py` 覆盖 app/engine/plugin/FFI；CPack 拒绝未经支持的 Windows 标签，检查实际 MSI template。新增 macOS 最终 ad-hoc seal/strict 签名/get-task-allow 门禁。正式渠道签名/公证和干净安装生命周期仍待补证据。 |
| X6 | to do | Analyze 跑真实 JAR 签名/篡改/未签 entry、错误 engine/plugin/ELF/PE/Mach-O、CPack 元数据和 distribution 拒绝负例；Native 跑真实 payload/签名门禁，macOS 跑实际 codesign 篡改 fixture。packager 核最终 APK ZIP 对齐、APK/AAB 全部原生 ELF 头、每 ABI 的 app/engine/FFI 清单及最终 APK ID/version/build 与发布源码一致。商店交付 APK、AAB 生成 APK 的对齐、16 KB 运行、沙盒/安装器升级与设备/审核矩阵仍需发布证据。 |

此前本地 macOS UI 构建的签名完整，但最终 entitlements 含 `get-task-allow=true`。Release 现设 `CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO`，最终签名门禁逐代码对象拒绝该权限。本地源码/fixture/build 与 CI 结果须分别报告；合成二进制头或 CMake fixture 不是 ARM 应用或 MSI 安装成功。

## 运行门禁

```bash
# 在对应平台主机上完成真实后端构建后执行：
bash tool/ci/package_artifacts.sh --target macos --arch arm64 --mode validation
# 另有 linux、windows、android、ios；默认 validation。

# 仅 Android：提供所选签名身份，禁止 debug 回退。
# 在安全环境配置四项 DITMESH_ANDROID_* 密钥输入，以及负责人独立取得的
# DITMESH_ANDROID_CERT_SHA256 证书指纹。
bash tool/ci/package_artifacts.sh --target android --mode distribution
```

Android tag 即使没传 `--mode distribution` 也强制正式签名门禁。CI 使用四项 secrets（`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`）和仓库变量 `DITMESH_ANDROID_CERT_SHA256`。部分签名配置会失败，不能静默选择其他密钥。APK 用 `apksigner` 验证密码学完整性；AAB 用 JDK `JarFile` verifier：每个 payload 读到 EOF，必须有唯一、已验证且当前有效的叶子签名证书，再与 APK 及负责人指纹比对。Android 自签证书属正常情况，但拒绝禁用算法、篡改/未签条目、APK/AAB 不同密钥、debug 身份、缺失/错误预期身份。普通 `META-INF/services` 资源不属于豁免的签名元数据。当前单 signer 合约遇多个上传身份或密钥轮换须显式评审更新。

其他平台尚未实现正式渠道签名，`--mode distribution` 在打包前直接失败。这是明确的阻塞状态，不是商店提交命令；这些平台普通 tag 的 draft 包仍是验证制品。

`native_payload.py` 读取真实 PE/ELF/Mach-O 头；Linux/Windows 仍为 x64，macOS 用显式目标。runner CPU、模拟运行的工具 ABI、编译目标、engine 可用性、包元数据、商店目标须分开记录。改目录或包名不会产生目标支持。macOS 最后修改后先签内层代码再签父 bundle，并逐代码对象核 Release 权限。ad-hoc 验证不证明 Developer ID、公证或 Mac App Store 接受。

Android ELF PT_LOAD 对齐适用于每个打包的 64 位原生库；ZIP 16 KB 放置适用于**未压缩** `.so`。上传 Play 前另用 bundletool 核 AAB 的 `PAGE_ALIGNMENT_16K` 和所生成 APK，再将商店/测试轨道构建安装到 16 KB 设备。NDK 源码版本或单个 APK ZIP 通过不足以证明 AAB 交付链。

Windows Flutter Release 还包含 CPU 专用的 **ELF** Dart AOT 快照 `data/app.so`，固定版本的 [Flutter AOT compiler](https://github.com/flutter/flutter/blob/3.41.9/packages/flutter_tools/lib/src/base/build.dart) 与 [Windows bundle target](https://github.com/flutter/flutter/blob/3.41.9/packages/flutter_tools/lib/src/build_system/targets/windows.dart)有直接依据。packager 显式启用 `--flutter-windows-aot`，仅此路径允许 ELF，并继续核 ELF CPU 与 PE app/engine 目标一致；其他异格式插件、缺失/错误 CPU 快照仍失败。首轮 Windows CI 构建暴露此格式差异，下载的真实 runner 共 **17** 个运行时文件在本地通过修复后的检查。实际 MSI 生成/元数据仍由 Windows CI 验证。Android signer 解析也分开已验证 scheme/SDK-range 标签与 source stamp，强制只有一个当前 signer 身份。

[2563e68 的真实 Gradle AAB 任务](https://github.com/agentx-icu/ditmesh/actions/runs/39884174843/job/120189735884)构建了 75.3 MB bundle，原生对齐检查通过，随后暴露文本解析误判：jarsigner 对 manifest-last 输出流式 warning，所列资源含 `common_google_signin_btn_*_disabled.xml`，旧检查器把路径中的 `disabled` 当作禁用算法。改为 [JDK JarFile API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/jar/JarFile.html)逐 entry 验密码学完整性，不解析人读 warning 或套用流式 manifest 顺序假设。已签名 manifest-last fixture 包含同类资源名；篡改、追加未签条目和普通 META-INF service 仍失败。失败任务未上传 AAB，回归 fixture 仅复现其顺序/命名条件，不冒充该真实应用 bundle。

## 请求商店审核前的负责人动作

1. **发布者：**记录所选商店、国家/地区、法律主体/team/app identity、角色权限、归属、证书指纹/续期/轮换负责人。不提交密钥，不编造控制台 ID。实际确认 `icu.agentx.ditmesh` 已预留/归属，对齐 tag/version/build 和上次已发布版本的商店递增编号。
2. **隐私/发布负责人：**逐 app/SDK/网络行为核 manifest、公开隐私/条款/支持页面、App Privacy/Data safety/权限表单。隐私 URL 于 2026-10-23 返回 HTTP 200；这不证明政策准确、删除请求可处理或审核网络可达。说明相机 QR、本地麦克风解码、本地通知、bootstrap 服务和 peer IP 可见性。按 Apple 问卷核出口分类，不能仅据 libsodium 存在判断豁免。
3. **产品/安全负责人：**确定适用的 UGC 管理/举报响应、年龄/儿童安全，以及本地 Tox 身份的账号删除分类。本地删除不能清除 peer 已保留消息。如 Play 账号删除要求适用，提供并测试应用内和站外请求入口，泛化支持链接不能证明完成。不要添加虚假举报按钮或承诺无人值守的后端。
4. **发布/审核负责人：**提供真实审核说明和可达测试 peer/QR 联系人，说明离线/屏蔽与 bootstrap 依赖，不把 fake-backend 截图当成真实聊天证据。完成截图/图标/年龄/内容/本地化/无障碍材料并从审核网络核公开 URL，分开核 iPhone/iPad/Mac 素材。
5. **QA/发布负责人：**关联确切构建 SHA/工具链/header/安装器/签名报告和测试轨道或签名后干净主机安装/升级/卸载证据。覆盖旧数据、沙盒权限、拒绝/恢复、重启/离线/握手、备份恢复和 16 KB 运行。灰度发布指定停止负责人；通常通过更高版本修复，不能假定商店版本可降级或数据 schema 向下兼容。保留先前签名制品与迁移兼容恢复方案。

## Windows 已安装包增量验证 — 2026-10-23

本次增量从已合并 PR #34（`909ad76a4bc67d01aed8a10029a6b290ba36d885`）开始。Windows job 现在把最终 MSI 安装到含空格路径，将全部已装文件与配对最终 ZIP 逐个核 SHA-256（包括 Flutter 资源和 ELF AOT snapshot），并对安装后的 payload 运行原生头校验。它等待所启动 PID 的真实主窗口，确认该 PID 从安装目录加载 Flutter engine 和 Tox bridge，再发送正常关闭请求并要求零退出；随后删除已装 Flutter engine、执行 MSI repair、重复 payload/窗口校验、卸载并拒绝残留安装文件或进程。即使失败，也上传 MSI 日志、准确 MSI/ZIP SHA-256、payload 报告、数据路径与各阶段结果。失败清场不能把测试改成通过。

另一个产物级缺口已在 [PR #34 的最终 Windows artifact](https://github.com/agentx-icu/ditmesh/actions/runs/39886381714) 复现：ZIP 含 15 个 DLL，却没有 `msvcp140.dll`、`vcruntime140.dll`、`vcruntime140_1.dll`，而真实 `ditmesh.exe`、`tim2tox_ffi.dll` 的导入表均需要这三项。hosted runner 预装 Visual Studio 会掩盖干净机器失败。Windows CMake install 现通过 `InstallRequiredSystemLibraries` 从所选 MSVC 工具链获取 release CRT，要求三项 x64 依赖并拒绝 debug runtime，携带 `licenses/MSVC-runtime.txt` 来源/条款说明。打包检查 runtime 清单和所有原生架构；MSI 安装测试要求 CRT 具有有效 Microsoft Authenticode 签名，并确认同一启动 PID 加载的是三个 app-local DLL。Microsoft CRT 的签名不会替 DitMesh 自身 EXE、插件或 MSI 签名。

2026-10-23 重核：[Flutter app-local 分发](https://docs.flutter.dev/platform-integration/windows/building#building-your-own-zip-file-for-windows)、[CMake runtime 发现](https://cmake.org/cmake/help/latest/module/InstallRequiredSystemLibraries.html)、[Microsoft 再分发条件](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files)。发布负责人仍须归档实际 Visual Studio 许可/再分发依据，并随应用更新维护 app-local runtime。notice 只记来源，不表示应用 GPL 许可重新授权 Microsoft 组件，也不代表本任务接受任何协议。

`test_windows_installer.ps1` 只允许 GitHub-hosted Windows Actions runner，在安装前拒绝既有 DitMesh 进程、由 KnownFolder 派生的应用数据或已注册 MSI ProductCode。应用使用一次性 hosted 账号的真实 Roaming/Local AppData；改变 `APPDATA` 不能重定向 `path_provider_windows`，所以本测试不声称有临时 app-data 根，不覆盖 KnownFolder/profile 注册表设置或改已有用户数据；Windows Installer 按测试产品管理自身注册态。禁止在普通用户机器执行。全新 profile 默认关闭即退出；测试不启用 close-to-tray，也不把强杀当作优雅退出。

严格关闭检查在修复前真实复现 `0xC000041D`。[344251c 的受限 GDB 执行](https://github.com/agentx-icu/ditmesh/actions/runs/39904141214/job/120254413827)在 `flutter_windows.dll` RVA `0x1cda0` 捕获故障：`FlutterDesktopViewControllerDestroy` 销毁子 HWND 时重入 `FlutterDesktopViewControllerHandleTopLevelWindowProc`，锁定 SDK 的原生 view 已清空；`window_manager` 只发 `WM_QUIT`，未先销毁父窗口。runner 现于 COM 反初始化前显式走既有 `window.Destroy()`，让 `OnDestroy` 先清空客户端 controller，避免原生销毁期间重入；无 controller 时也不再重载字体。不屏蔽其他消息或异常。工作流已移除取证 opt-in；最终 [PR checks](https://github.com/agentx-icu/ditmesh/pull/35/checks)须在**无调试器**下证明安装/repair 两次启动均正常零退出，MSI evidence 记录 `debugger_requested=false`。可选 hosted-only 取证不等于生产 crash 收集或最终资格。

| ID | 状态 | 证据／仍存边界 |
|---|---|---|
| W4、X6 | to do | 必需 Windows release-build CI 现执行最终 MSI 安装、payload、启动/关闭、删除文件后 repair、卸载；具体执行证据看最终 PR head 的 Windows job。本地 macOS 测试不执行 MSI、不证明 Windows 运行行为。签名、上一版本升级、Store 交付和普通用户资格仍由负责人完成。 |
| X5 | verified | 复用 Toxee 已建立的 MSI 安装生命周期方法，适配 DitMesh 自己的安装器、真实 backend、应用身份和存储。其他目标保留自己的门禁；Ubuntu 与 iOS 增量见后文。 |
| P4、P9 | to do | 下方材料表明确账号/证书/资料来源与阻塞决定；不编造隐私/出口答案，也不虚构 UGC/删除运营服务。 |

macOS 本地验证：初始化锁定 Tim2Tox 子模块并仅对该命令设置已安装 macOS 26.4 SDK 的 `SDKROOT` 后，全部 **111** 个 `tool/ci/*test.py` 测试通过。首次未满足前置条件的运行因子模块源码缺失、宿主默认 SDK 27/链接器不匹配而失败。新增八个 payload 测试覆盖资源变化、已装文件丢失或额外增加、目录伪装 executable、不安全/冲突 ZIP 路径和已装 symlink 越界、CRT/notice 缺失和 debug CRT 拒绝。四个 CMake fixture 真实执行 Release/Debug 安装规则、必需文件与 debug runtime 拒绝，仅替换发现过程，不证明实际 Microsoft DLL 或许可；`actionlint`、`git diff --check` 通过。PowerShell/MSI 的执行证据由 Windows job 提供，不从本地结果推断。

## 干净 Ubuntu 已安装包增量验证 — 2026-10-23

必需 Linux release job 现把准确最终 DEB 交给 `linux_installed_smoke.py`。全新的官方 Ubuntu 24.04 容器先只安装 DEB 及其声明依赖，核 ELF 未解析依赖与运行工具并记录，再安装 X11 测试工具，避免构建 runner 的 SDK/依赖掩盖包依赖缺失。容器不用 privileged 模式、不挂载宿主桌面/用户数据；以既有非特权 `nobody` 用户和私有 XDG 目录运行已装 launcher，将安装文件字节/模式及 desktop/icon/launcher 与最终 DEB 对照，等待该 PID 的可见窗口和已装 Flutter/Tox mapped modules，发送正常 `WM_DELETE_WINDOW` 关闭请求，再卸包并拒绝包文件、注册态或进程残留。失败清场不能算优雅退出。

共享 helper 的首次真实 CI 暴露并修复了加载器上下文与失败证据问题：入口 ELF 在清除 `LD_LIBRARY_PATH` 后先严格检查；单独检查 DSO 时只为该命令提供包内 `/opt/<app>/lib`，不向 GUI 导出环境、不放过系统依赖或 GLIBC 缺失，随后仍核实际 PID maps。证据逐文件复制，不更改宿主挂载目录的属主/权限，并预留宿主可写结果文件；记录失败不会遮蔽原始错误。18 个 helper 回归覆盖 loader 存在/架构/闭包与该边界、容器 stdin/超时清场及文件/架构负例，均不是实际安装证据。

[DitMesh 在 344251c 首次真实 clean-DEB 执行](https://github.com/agentx-icu/ditmesh/actions/runs/39904141214/job/120254414014)已过已装文件、loader 闭包、可见窗口与实际 engine/FFI maps，随后正常关闭时 abort：插件同步销毁 GTK/GL，早于 Flutter view/compositor 完成清理。Linux 最终退出现于既有偏好/会话保存/cleanup 屏障与 tray 销毁之后，走 Flutter 标准 `SystemNavigator.pop` GApplication 路径；close-to-tray 仍 hide，Windows/macOS 保留各自插件入口。4 个真实 MethodChannel/controller 回归覆盖保存完成顺序、tray 状态和平台分支，包含红→绿复现；相关桌面测试本地共 42 项通过。最终 DEB 仍须在 CI 完成可见启动、正常零退出与卸载。

运行时加载的 GL/EGL/GLES 调度库现为显式 DEB 依赖（`libegl1`、`libgl1`、`libgles2`），RPM 补对应 SONAME Requires。干净检查在安装测试工具前解析每个准确 loader SONAME，核原生 ELF 头，再清除 `LD_LIBRARY_PATH` 检查其完整 `ldd` 闭包；Mesa DRI 软件驱动仍只是测试设施。宿主偶有的 JDK 也不能改变桌面 bundle：仅 Android 使用的 `path_provider_android` 带来可选 `jni` desktop CMake，但 DitMesh 无桌面 Java 调用；Linux/Windows 在 generated plugins 前关闭该可选发现，不改 Android。回归真实执行锁定上游 JNI CMake，通过可发现的合成 JDK 复现旧的 `libdartjni` 捆绑，再证明新策略排除它且仍能构建/安装另一原生库；fixture 不替代最终包执行。

`linux-installer-evidence` 保留 DEB 哈希、拉取镜像 digest、OS/架构/包/依赖清单、已装文件哈希、实际 PID/maps/窗口和卸载结果，失败也保留日志。范围仅为 **Ubuntu 24.04 x86_64 DEB／X11／1280×800／scale 1／软件渲染**；不证明 RPM/Fedora、Wayland、硬件/音频/摄像头、真实 peer 会话、上一版升级或商店批准。W4/X6 在这些更大边界仍为 **to do**，新子检查的真实执行证据须看最终 PR head 的 Linux job；其他目标保留自己的门禁。

## 受控 iOS archive/export 增量 — 2026-10-23

`bash tool/build_ios_store.sh --unsigned-archive` 现可在禁用签名、强制真实 Tox 后端且不访问账号的条件下生成 device archive。iOS job 保留既有 unsigned IPA，另建 archive，核唯一 App 及其可执行主程序、arm64 原生库存、版本/构建号、源码声明用途文案、App/SDK privacy manifests、嵌入 Tim2Tox framework 和无测试 hooks，并强制主程序/dSYM UUID 一致。独立 `ios-store-readiness-archive` tar artifact 保留符号、symlink 和 executable mode，不进入十二资产公开发行契约；[344251c 首次真实 CI 执行](https://github.com/agentx-icu/ditmesh/actions/runs/39904141214/job/120254413764)已通过：20 个 arm64 原生对象、15 份 privacy manifest、主程序/dSYM UUID 匹配，使用 Xcode 26.6／iPhoneOS 26.5 SDK。这是 unsigned archive 证据，最终 PR head 仍重跑。

按 [Apple SDK 最低要求](https://developer.apple.com/news/upcoming-requirements/)，2026-04-28 起上传 App Store Connect 的 iOS/iPadOS 构建须使用 Xcode 26 或更新版本和 iOS/iPadOS 26 SDK。受控入口现在对 archive 及最终 IPA 的实际 `Info.plist` 共用检查：`DTSDKName` 须为完整 `iphoneos` 版本且 major ≥ 26，`DTXcode` 须为有效四位版本且 ≥ 2600；缺失、畸形、模拟器或任一独立旧值均失败，不以部署最低版本或 runner 选择替代实际产物。unsigned archive 同样执行，避免误标兼容性；每次发布仍须重查政策，门槛不是商店接受证明。

有既有负责人材料后，同一入口只接受 `--team-id`、`--certificate-sha1`、`--export-options` 和全新 `--output`。负责人本地 plist 必须明确 `method=app-store-connect`、`destination=export`、manual 签名、所选 team/证书 SHA-1，以及仅用于 `icu.agentx.ditmesh` 的既有 profile；构建前快照已验证政策。直接调用 `xcodebuild archive` 和本地 `-exportArchive`，不带自动 provisioning/设备注册参数，不上传，也不接受任意 Flutter/Xcode 参数。最终 IPA 必须通过递归签名完整性、distribution authority、实际 signer 指纹、离线证书链、profile 的 team/app/证书/到期和 release entitlements 对照，才写入 `distribution.json`。没有负责人既有 Keychain identity/profile，本轮**不执行**签名导出；不得把这些文件或私钥交到工单/artifact。通用 `package_artifacts.sh --mode distribution` 在 Android 外仍显式拒绝；这是独立的显式 iOS 入口。

负责人受控 Mac 的本地导出命令：

```sh
bash tool/build_ios_store.sh --team-id "$DITMESH_APPLE_TEAM_ID" \
  --certificate-sha1 "$DITMESH_IOS_CERT_SHA1" \
  --export-options /owner-controlled/ExportOptions.plist
```

W4/X6/P4 在实际分发、业务/SDK reason audit 和签名真机资格上仍为 **to do**；X9 现保留 UUID 匹配的 iOS 主程序符号，但不实现生产 crash 收集，也不证明真机 crash 已符号化。27 个 store-export 加 5 个 Apple metadata 回归覆盖命令/政策边界、无效 profile/signer/entitlements、缺失或越界主程序、archive 结构、隐私/签名检查和失败传播；合成 fixture 不证明真实 archive/签名。本地 Python 共 116 项通过，shell 语法、ShellCheck、actionlint 通过。JNI fixture 使用本隔离 checkout 已 resolve 的 lock 配置，执行真正的上游插件源码；另有 5 组 PowerShell schema 回归覆盖准确身份、无关/空事件数据忽略、offset 边界和字段脱敏，不冒充实际 Windows event API 证据。

## Release 安全应用诊断

设置、通知、生命周期、偏好、聊天和音频适配器中既有的原始异常控制台输出现仅在
debug 构建运行；共享 `morse_io` 的音频会话和 wakelock 适配器采用相同策略。
桌面 shell 未提供日志 sink 时保持静默，包括 release `main()` 的配置。
NotificationCenter 失败始终只记录固定事件与允许列表内的错误类别，不记录 payload、
账号／联系人 ID、异常值或堆栈。未知启动错误使用既有本地化通用文案；已知聊天错误码
仍使用本地化契约文案。

binding／启动之前安装 framework 与未处理异步错误入口，release/profile 只输出固定
来源和安全错误类别。不渲染传入的 stack、Flutter context 或 information collector，
因为它们可能包含应用数据。debug 保留此前错误处理器和开发细节。本次不新增日志文件、
支持导出、上传、权限或留存政策。这是隐私修复和最小安全控制台错误入口，不是原生
crash reporter，也不宣称生产堆栈已可读。

三个 marker 回归先复现桌面 fallback、通知 payload／异常泄漏与启动页原文展示，再于
修复后通过。另有诊断边界单测用 `debugMode: false` 验证 release 分支，覆盖恶意
`toString`、stack／context marker 和 debug 处理器保留。独立 CI 调用设置
`dart.vm.product=true`，断言实际 release 常量，并执行真正的偏好保存与共享音频／
wake 失败 catch。诊断 writer 失败会被隔离，不递归 fallback，也不改变原业务失败。
这些是隔离单测，不冒充已安装 release／真机证据。

| Checklist | 状态 | 证据／剩余工作 |
|---|---|---|
| X9 既有原始日志与启动错误泄漏 | 自动回归 verified | `application_diagnostics_test.dart`、`notification_center_test.dart`、`native_backend_startup_test.dart`、`startup_gate_test.dart`、`desktop_shell_controller_test.dart`；各平台编译 release marker 检查仍待做。 |
| X5 共享代码一致性 | 源码与隔离测试 verified | 共享 Dart 策略覆盖 Android／iOS／macOS／Windows／Linux；两处 `morse_io` guard 与 MorseCQ 一致；原生／系统日志仍需已安装真机审计。 |
| X9 原生捕获、可读且准确匹配构建的堆栈与符号清单 | to do | 独立工程项；保存已有构建符号无需先选择遥测服务。 |
| P4／P7 支持数据披露与屏幕采集 | to do／needs device | 未新增收集或上传；本次不能证明商店隐私获批或屏幕采集保护。 |

## 剩余工程与决定

负责人材料表不是全部 backlog。安装检查通过，不能被表述为所有可通过代码解决的 checklist 项已经完成。

| 剩余工程 | 前提／阻塞 |
|---|---|
| X9 逐构建原生符号归档、二进制／符号身份检查及符号化 | 已有编译输出仍需代码接入，包括 PDB GUID／age、ELF build ID／debuglink、逐 Apple binary／dSYM UUID；不以前置远端服务或账号阻塞。缺失 vendor 符号需准确构建／revision 来源。 |
| X9 完整原生 crash 捕获，以及任何持久化／支持诊断 | 按实际范围选择 reporter、数据／留存／支持政策与隐私披露，仍需已安装 release crash 和 marker 验证；本任务不虚构遥测服务或账号。 |
| P7 app-switcher／屏幕采集保护 | 产品负责人先确定每平台聊天/身份内容显示策略，之后仍需实现与已安装真机验证。 |
| B4 保证移动后台送达 | 当前产品不作此承诺；新保证需要平台预算/传输架构和产品决定，不能从现有后台估算推导。 |
| 最终签名 iOS export/真机资格；可选 Mac App Store、Developer ID/公证、Windows 代码签名或 MSIX 渠道实现 | iOS 已有受控 archive/export 入口，仍需既有负责人签名材料与真实签名设备证据；其他渠道先选择真实身份并安全提供签名配置；Android 之外 `--mode distribution` 仍显式拒绝。剩余既含代码也含验证，不只是凭据。 |
| F1/F2 帧时序/启动/体积预算，以及完整 X1/X4/X6 设备/升级矩阵 | 先定支持硬件和预算，再测已安装 release 与旧版升级路径；容器/窗口检查不能替代测量。 |

## 负责人材料交接表

这是待提供材料的请求清单，不代表账号或应用记录已经存在。公开 ID、证书指纹和脱敏证据可记录到发布工单；秘密值由账号持有人直接配置进已批准的秘密存储。不要在聊天、PR 或仓库发送密码、私钥、keystore、provisioning profile 或 API token。本任务不创建账号/凭据、不改角色、不接受协议，也不发布。

| 平台／渠道 | 材料与用途 | 获取或核实位置 | 当前阻塞 |
|---|---|---|---|
| 所选渠道通用 | 明确渠道/地区、发行主体、应用归属、公开应用/包 ID、上一版版本/构建号与签名指纹，建立不可随意改变的升级身份。 | 所选商店应用记录及上一版已签名发布档案；与 `icu.agentx.ditmesh`、`apps/ditmesh/pubspec.yaml` 对照。 | 未确定渠道或核实归属/上一版记录；不得编造 ID，也不能假设首次发布。 |
| iOS／iPadOS App Store | Apple team ID、bundle/app 记录、既有 Distribution 证书公开 SHA-1/到期及绑定此 app/证书的 App Store profile 名称/UUID、签名负责人、设备范围、archive/TestFlight 记录，用于受控签名导出与审核构建。 | [Apple Developer 账号](https://developer.apple.com/account/) → Membership / Certificates, Identifiers & Profiles → Profiles；负责人 Mac Keychain Access → My Certificates；[App Store Connect](https://appstoreconnect.apple.com/) → My Apps → 应用记录 / TestFlight / Pricing and Availability。私有签名材料由持有人保存在 Keychain 或批准的 CI 秘密存储。 | 缺已确认的 app/team、distribution 签名或可接受的正式 archive；unsigned IPA 和 macOS ad-hoc 签名不能替代。 |
| Mac App Store（若选） | 独立 macOS 平台/app 身份、distribution provisioning、沙盒能力评估和签名 archive，验证 Store 路径。 | Apple Developer → Identifiers / Profiles；App Store Connect → 应用 → macOS 平台和构建。 | 现有 PKG/ZIP 只验证站外包路径；Store 签名及沙盒网络/文件/设备测试未完成。 |
| macOS 站外 Developer ID | Developer ID Application/Installer 的公开证书主体、到期/指纹，以及安全签名/公证配置负责人，用于最终 bundle/PKG 签名与公证证据。 | Apple Developer → Certificates；macOS Keychain Access → My Certificates；持有人的 `notarytool` 配置。只交接公证 submission ID/状态及 stapling/Gatekeeper 报告，不交接私钥、密码或 profile 内容。 | 当前 ad-hoc 只证明完整性；正式签名、公证/stapling 和隔离下载后的干净 Mac 安装待做。 |
| Google Play／Android | Play 开发者/app 记录、上传证书 SHA-256、独立 Play app-signing 交付证书/lineage、递增 versionCode、适用测试及 production-access 证据，确保上传和安装升级身份。 | [Play Console](https://play.google.com/console/) → 应用 → Setup / App integrity 核证书/签名；Test and release 核轨道/资格。持有人直接在仓库 Settings → Secrets and variables → Actions 配置四个 `ANDROID_KEYSTORE_*` / `ANDROID_KEY_*` secret，以及公开变量 `DITMESH_ANDROID_CERT_SHA256`。 | 缺已核上传 key/指纹或归属；交付身份、账号特定发布资格、生成 APK/16 KB 运行及升级证据仍需补齐。 |
| Microsoft Store 托管 MSI/EXE（若选） | Partner Center 产品身份、可信代码签名证书的公开身份、固定版本 HTTPS 安装器 URL/哈希、静默参数与认证说明，建立发行者和托管包信任。 | [Partner Center](https://partner.microsoft.com/dashboard/) → Apps and games → 产品 / submission；现有证书提供方后台；发行者所选的内容不可变下载托管。私有签名访问仅配置到批准的安全环境。 | 安装器及全部内嵌 PE 仍需可信签名、固定 HTTPS 托管及上一版本升级证据。本任务不购买证书、不部署托管、不提审。 |
| Windows Visual C++ runtime | 实际 MSVC/toolset 版本、适用 Visual Studio 许可/再分发证据及 app-local 维护负责人，建立 Microsoft 组件的权利和维护路径。 | Visual Studio Help → About → License Terms、[Visual Studio 许可目录](https://visualstudio.microsoft.com/license-terms/)和所用工具链的 redistributable list；与 `licenses/MSVC-runtime.txt`、CI 证书/哈希报告核对。 | Microsoft DLL 有效签名或 CI 成功不证明发行者拥有再分发权，也不接受协议；分发前由负责人归档依据。 |
| Microsoft Store MSIX（若选） | 预留包 identity/publisher、能力清单、WACK/升级证据及签名包记录。 | Partner Center → 产品 → Product identity / packages。 | 尚未实现 MSIX 打包路径；Store 重签是不同路径，不能为满足托管 MSI 行而要求购买证书。 |
| Linux 站外／可选商店 | 支持的发行版/架构矩阵、上一版包及维护者归属；若选择，补 Flathub app-ID 权利或 Snap publisher/name/confinement 批准。 | 旧版已签名发布档案；[Flathub 文档](https://docs.flathub.org/docs/for-app-authors/submission)及 [Snapcraft dashboard](https://dashboard.snapcraft.io/)。 | 干净安装/升级/桌面集成/portal 尚无证据。实际 Flathub manifest/提交按现行 AI 政策交由人处理；不假设已选择任何可选商店。 |
| 中国大陆 Android（若选） | 明确具体商店、地区/包类型、已验证主体/app 身份，以及该渠道实际要求的资质/备案、隐私/SDK 审核证据。 | 发行者的 Huawei AppGallery Connect、小米或其他所选官方开发者后台，按当前渠道细则核实。 | 尚未选渠道/地区；后台专属规则及适用性仍由负责人确认，不从中文界面推导统一备案义务。 |
| 所选渠道的隐私／安全／审核资料 | 准确的隐私/SDK 清单，privacy/terms/support URL，加密出口分类，年龄/受众/内容回答，分语言/设备截图图标，真实 peer 审核指引，以及适用的删除/举报/响应流程。 | App Store Connect → App Information / App Privacy / App Review / 加密问题；Play Console → App content / Store listing；Partner Center → submission properties / age ratings / certification notes；公共 `site/` 源码与实际产品/运营负责人。审核专用访问只填各后台受保护审核字段。 | 产品负责人尚未建立 UGC 响应与删除请求流程，亦未签核披露/出口问卷；有源码链接不能替代。 |
| QA／发布证据 | 准确产物哈希、CI head/run/job 链接、签名安装/旧版升级/卸载结果及设备矩阵，区分仓库验证和渠道可发布性。 | GitHub Actions artifacts 和负责人真机/干净机器报告，绑定同一最终字节及签名身份。 | 硬件、商店交付版本、上一版升级及审核网络可达性仍须执行；同版本 MSI repair 不是升级资格验证。 |

## 已执行的本地验证

2026-10-23，Flutter 3.41.9 / Dart 3.11.5、Xcode 26.4 SDK：`tool/ci/*test.py` 共 **49** 项回归全通过，包含实际临时 keytool/jarsigner/apksigner/aapt2 与 codesign fixture。按固定源码和仓库 overlays 重建 Tim2Tox release 并 stage，真实后端 macOS ARM64 Release 构建通过（**39.0 MB**）。应用 **22** 个原生代码对象通过架构、最低 OS、strict 签名和最终权限门禁。生成 PKG/ZIP 后分别解包，其 22 个代码对象再次通过，app/FFI/privacy-manifest 哈希与构建一致。ShellCheck、actionlint、源码 guards、`git diff --check` 通过。

这些结果不包含 GUI/聊天 smoke、安装到 `/Applications`、Apple 公证、本地移动/Windows/Linux 构建、商店交付或审核。CI 平台构建作为 PR 独立证据；阻塞/未执行目标不能标成功。

## 官方政策与来源索引

除上面明确标记未读完整者外，核验日期均为 **2026-10-23**。每次发布重开动态来源，构建检查器按已生效的 SDK 最低版本检查实际产物，不使用未来截止日期触发逻辑。

- Apple：[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)（UGC 1.2、审核访问 2.1、隐私/删除 5.1.1）；[privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)、[required API reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)、[出口合规](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)、[签名](https://developer.apple.com/library/archive/technotes/tn2206/_index.html)、[公证](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)。针对移动及其他列明平台的 required-reason 执行规则不能直接泛化到所有 macOS 渠道。
- Android/Play：[应用签名](https://developer.android.com/studio/publish/app-signing)、[apksigner](https://developer.android.com/tools/apksigner)、[JAR 验证](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/jar/JarFile.html)、[16 KB](https://developer.android.com/guide/practices/page-sizes)、[target API](https://support.google.com/googleplay/android-developer/answer/11926878)、[User Data](https://support.google.com/googleplay/android-developer/answer/10144311)、[账号删除](https://support.google.com/googleplay/android-developer/answer/13327111)、[UGC](https://support.google.com/googleplay/android-developer/answer/9876937)。本日普通手机/平板新应用和更新要求 API 36；16 KB 指引称自 2027-02-01 阻止不支持的更新。发布时核实际适用性及控制台账号测试例外。
- Microsoft：[Store 政策](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies) 7.20，于 2026-10-22 生效；10.2.9 针对非游戏 HTTPS MSI/EXE。[MSI/EXE](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-package-requirements)、[MSIX](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements)、[MSI 架构 template](https://learn.microsoft.com/en-us/windows/win32/msi/template-summary)。旧支持文案与生效政策冲突时按适用现行政策处理，不将 MSI 要求泛化为 Store-signed MSIX。
- Linux：[Flathub 强制要求](https://docs.flathub.org/docs/for-app-authors/requirements)（含当前 AI 材料/提交交互限制）、[质量指南](https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines/quality-guidelines)、[Snap 沙盒](https://documentation.ubuntu.com/security/security-features/privilege-restriction/snap-confinement/)、[Snap 渠道](https://documentation.ubuntu.com/snapcraft/stable/reference/channels/)。本次仓库改动不生成 Flathub manifest，不提交或参与 Flathub 审核交互。
- 国内候选：[华为审核要求](https://developer.huawei.com/consumer/cn/doc/app/50104)、[小米审核入口](https://dev.mi.com/distribute/doc/details?pId=1139)。本次未能完整读取动态/登录内容，选定渠道后由负责人核控制台最新要求。

## I2 后续：接入既有外壳命令

活跃外壳现已绑定已有搜索/新消息定义：macOS Cmd+K/N，Windows/Linux Ctrl+K/N。
搜索选中聊天并聚焦现有筛选框；新消息复用联系人入口，不堆叠路由。忽略按键重复，并将已聚焦
编辑器/IME、覆盖对话框和路由的按键留给各自处理。提示文本展示已支持快捷键。完整 App 的假后端
键盘事件回归覆盖三个桌面平台变体；这属于软件行为证据，不是实体键盘或安装后的正式包证明。

| ID | Status | 证据／剩余门槛 |
|---|---|---|
| I2 | needs device | `test/desktop/shell_shortcuts_test.dart` 覆盖三桌面变体的 K/N 修饰键、重复、搜索焦点/筛选词、路由和编辑器/IME；实体键盘/触控板、非美式布局和全键盘控制仍待设备检查。 |
| I3 | verified | 快捷键回归验证编辑器命令所有权及 IME 组字值保持；不等于真实 IME/设备互通验证。 |
| X5 | verified | 一个共享外壳 handler 与同组键盘事件用例覆盖三个桌面修饰键策略；未改平台插件或协议。 |
| X6 | to do | 最终 head 的 CI release 构建仍必须通过；widget 按键不证明已安装签名包/商店行为。 |

Cmd/Ctrl+Shift+M 因没有共享音频所有者继续未绑定。下方原生菜单增量通过 UIKit 接入这两个动作；Flutter `Shortcuts` 本身不实现原生菜单，也不关闭 I2 设备矩阵缺口。
这项有界代码修复无需新增账号、证书、原生权限或商店操作。

## I2 iPad 原生菜单桥

iPadOS 26+ 现已为既有搜索/联系人动作添加真实 UIKit 菜单代码：`AppDelegate.buildMenu` 中的
本地化 `UICommand`、`SceneDelegate` 的唯一活跃场景校验，以及连接现有外壳动作的 Flutter 通道。
原生命令不带按键，Cmd+K/N 仍仅由 Flutter 一个 handler 处理。身份/条款未就绪、其他路由覆盖、
文本/IME 输入、应用非活跃、销毁后或场景归属不明确时，命令保留可见但禁用。Dart 在派发时重查，
owner 票据拒绝旧会话排队请求，原生回复版本检查防止迟到失败覆盖新状态；
原生端也拒绝缺失/隐藏窗口、原生编辑器/覆盖页面和非活跃/断开场景。iOS <26 和单场景策略保持
兼容，无新增权限或签名材料。

| ID | Status | 证据／剩余门槛 |
|---|---|---|
| I2 | needs device | 原先缺少的原生桥代码已实现，8 个桥接回归加 20 个键盘用例通过，真实 Swift/FFI archive 编译通过；iPadOS 26+ 实际菜单显示、触摸/指针/键盘调用、灰显和场景行为仍需 OS/设备证据。 |
| I3 | verified | 假后端通道回归验证编辑器/IME 所有权、旧 owner 拒绝和 ready→onboarding 过渡；真实 IME/键盘互通仍待设备验证。 |
| X5 | verified | 复用同一现有外壳动作和 S 文案，其他平台仍走 Flutter 快捷键；Swift 状态回归覆盖当前/迟到 false/error 回复及 owner，未注册重复原生按键，未增加多场景或共享声音行为。 |
| X6 | to do | 本机 Xcode 26.4.1 / iPhoneOS 26.4 已以真实 FFI unsigned archive 验证 Swift 编译、20 个 arm64 Mach-O、15 个 privacy manifest 及匹配的 Runner 符号；最终 head CI、已安装签名设备资格另计。 |

2026-10-23 已核 [Apple UIKit 菜单指引](https://developer.apple.com/videos/play/wwdc2025/243/)
（代码生成菜单、无按键命令、不可用项可见灰显）、本机 UIKit 26.4 headers 和
[Flutter UIScene/通道生命周期指引](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)。
通道仍在 `didInitializeImplicitFlutterEngine` 注册，`FlutterSceneDelegate` 仍负责 scene 生命周期。
这是有界的两个既有动作接线，不宣称每个工具栏动作都已原生菜单化，也不等于 App Review 批准。

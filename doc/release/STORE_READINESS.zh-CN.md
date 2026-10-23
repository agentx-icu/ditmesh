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

本次增量从已合并 PR #34（`909ad76a4bc67d01aed8a10029a6b290ba36d885`）开始。Windows job 现在把最终 MSI 安装到含空格路径，将全部已装文件与配对最终 ZIP 逐个核 SHA-256（包括 Flutter 资源和 ELF AOT snapshot），并对安装后的 payload 运行原生头校验。它等待所启动 PID 的真实主窗口，发送正常关闭请求并要求零退出；随后删除已装 Flutter engine、执行 MSI repair、重复 payload/窗口校验、卸载并拒绝残留安装文件或进程。即使失败，也上传 MSI 日志、准确 MSI/ZIP SHA-256、payload 报告、数据路径与各阶段结果。失败清场不能把测试改成通过。

`test_windows_installer.ps1` 只允许 GitHub-hosted Windows Actions runner，在安装前拒绝既有 DitMesh 进程、由 KnownFolder 派生的应用数据或已注册 MSI ProductCode。应用使用一次性 hosted 账号的真实 Roaming/Local AppData；改变 `APPDATA` 不能重定向 `path_provider_windows`，所以本测试不声称有临时 app-data 根，也不改 registry 或已有用户数据。禁止在普通用户机器执行。全新 profile 默认关闭即退出；测试不启用 close-to-tray，也不把强杀当作优雅退出。

| ID | 状态 | 证据／仍存边界 |
|---|---|---|
| W4、X6 | to do | 必需 Windows release-build CI 现执行最终 MSI 安装、payload、启动/关闭、删除文件后 repair、卸载；具体执行证据看最终 PR head 的 Windows job。本地 macOS 测试不执行 MSI、不证明 Windows 运行行为。签名、上一版本升级、Store 交付和普通用户资格仍由负责人完成。 |
| X5 | verified | 复用 Toxee 已建立的 MSI 安装生命周期方法，适配 DitMesh 自己的安装器、真实 backend、应用身份和存储。Linux/macOS/mobile 包流程不变，既有真机/签名缺项继续保留。 |
| P4、P9 | to do | 下方材料表明确账号/证书/资料来源与阻塞决定；不编造隐私/出口答案，也不虚构 UGC/删除运营服务。 |

macOS 本地验证：初始化锁定 Tim2Tox 子模块并仅对该命令设置已安装 macOS 26.4 SDK 的 `SDKROOT` 后，全部 **53** 个 `tool/ci/*test.py` 测试通过。首次未满足前置条件的运行因子模块源码缺失、宿主默认 SDK 27/链接器不匹配而失败。新增四个 payload 测试覆盖资源变化、文件丢失、不安全/冲突 ZIP 路径和已装 symlink 越界；`actionlint`、`git diff --check` 通过。PowerShell/MSI 的执行证据由 Windows job 提供，不从本地结果推断。

## 负责人材料交接表

这是待提供材料的请求清单，不代表账号或应用记录已经存在。公开 ID、证书指纹和脱敏证据可记录到发布工单；秘密值由账号持有人直接配置进已批准的秘密存储。不要在聊天、PR 或仓库发送密码、私钥、keystore、provisioning profile 或 API token。本任务不创建账号/凭据、不改角色、不接受协议，也不发布。

| 平台／渠道 | 材料与用途 | 获取或核实位置 | 当前阻塞 |
|---|---|---|---|
| 所选渠道通用 | 明确渠道/地区、发行主体、应用归属、公开应用/包 ID、上一版版本/构建号与签名指纹，建立不可随意改变的升级身份。 | 所选商店应用记录及上一版已签名发布档案；与 `icu.agentx.ditmesh`、`apps/ditmesh/pubspec.yaml` 对照。 | 未确定渠道或核实归属/上一版记录；不得编造 ID，也不能假设首次发布。 |
| iOS／iPadOS App Store | Apple team ID、bundle/app 记录、签名/provisioning 负责人、设备可用范围、当前 SDK 接受证据、archive/TestFlight 记录，用于正式签名审核构建。 | [Apple Developer 账号](https://developer.apple.com/account/) → Certificates, Identifiers & Profiles；[App Store Connect](https://appstoreconnect.apple.com/) → My Apps → 应用记录 / TestFlight / Pricing and Availability。私有签名材料由持有人保存在 Keychain 或批准的 CI 秘密存储。 | 缺已确认的 app/team、distribution 签名或可接受的正式 archive；unsigned IPA 和 macOS ad-hoc 签名不能替代。 |
| Mac App Store（若选） | 独立 macOS 平台/app 身份、distribution provisioning、沙盒能力评估和签名 archive，验证 Store 路径。 | Apple Developer → Identifiers / Profiles；App Store Connect → 应用 → macOS 平台和构建。 | 现有 PKG/ZIP 只验证站外包路径；Store 签名及沙盒网络/文件/设备测试未完成。 |
| macOS 站外 Developer ID | Developer ID Application/Installer 的公开证书主体、到期/指纹，以及安全签名/公证配置负责人，用于最终 bundle/PKG 签名与公证证据。 | Apple Developer → Certificates；macOS Keychain Access → My Certificates；持有人的 `notarytool` 配置。只交接公证 submission ID/状态及 stapling/Gatekeeper 报告，不交接私钥、密码或 profile 内容。 | 当前 ad-hoc 只证明完整性；正式签名、公证/stapling 和隔离下载后的干净 Mac 安装待做。 |
| Google Play／Android | Play 开发者/app 记录、上传证书 SHA-256、独立 Play app-signing 交付证书/lineage、递增 versionCode、适用测试及 production-access 证据，确保上传和安装升级身份。 | [Play Console](https://play.google.com/console/) → 应用 → Setup / App integrity 核证书/签名；Test and release 核轨道/资格。持有人直接在仓库 Settings → Secrets and variables → Actions 配置四个 `ANDROID_KEYSTORE_*` / `ANDROID_KEY_*` secret，以及公开变量 `DITMESH_ANDROID_CERT_SHA256`。 | 缺已核上传 key/指纹或归属；交付身份、账号特定发布资格、生成 APK/16 KB 运行及升级证据仍需补齐。 |
| Microsoft Store 托管 MSI/EXE（若选） | Partner Center 产品身份、可信代码签名证书的公开身份、固定版本 HTTPS 安装器 URL/哈希、静默参数与认证说明，建立发行者和托管包信任。 | [Partner Center](https://partner.microsoft.com/dashboard/) → Apps and games → 产品 / submission；现有证书提供方后台；发行者所选的内容不可变下载托管。私有签名访问仅配置到批准的安全环境。 | 安装器及全部内嵌 PE 仍需可信签名、固定 HTTPS 托管及上一版本升级证据。本任务不购买证书、不部署托管、不提审。 |
| Microsoft Store MSIX（若选） | 预留包 identity/publisher、能力清单、WACK/升级证据及签名包记录。 | Partner Center → 产品 → Product identity / packages。 | 尚未实现 MSIX 打包路径；Store 重签是不同路径，不能为满足托管 MSI 行而要求购买证书。 |
| Linux 站外／可选商店 | 支持的发行版/架构矩阵、上一版包及维护者归属；若选择，补 Flathub app-ID 权利或 Snap publisher/name/confinement 批准。 | 旧版已签名发布档案；[Flathub 文档](https://docs.flathub.org/docs/for-app-authors/submission)及 [Snapcraft dashboard](https://dashboard.snapcraft.io/)。 | 干净安装/升级/桌面集成/portal 尚无证据。实际 Flathub manifest/提交按现行 AI 政策交由人处理；不假设已选择任何可选商店。 |
| 中国大陆 Android（若选） | 明确具体商店、地区/包类型、已验证主体/app 身份，以及该渠道实际要求的资质/备案、隐私/SDK 审核证据。 | 发行者的 Huawei AppGallery Connect、小米或其他所选官方开发者后台，按当前渠道细则核实。 | 尚未选渠道/地区；后台专属规则及适用性仍由负责人确认，不从中文界面推导统一备案义务。 |
| 所选渠道的隐私／安全／审核资料 | 准确的隐私/SDK 清单，privacy/terms/support URL，加密出口分类，年龄/受众/内容回答，分语言/设备截图图标，真实 peer 审核指引，以及适用的删除/举报/响应流程。 | App Store Connect → App Information / App Privacy / App Review / 加密问题；Play Console → App content / Store listing；Partner Center → submission properties / age ratings / certification notes；公共 `site/` 源码与实际产品/运营负责人。审核专用访问只填各后台受保护审核字段。 | 产品负责人尚未建立 UGC 响应与删除请求流程，亦未签核披露/出口问卷；有源码链接不能替代。 |
| QA／发布证据 | 准确产物哈希、CI head/run/job 链接、签名安装/旧版升级/卸载结果及设备矩阵，区分仓库验证和渠道可发布性。 | GitHub Actions artifacts 和负责人真机/干净机器报告，绑定同一最终字节及签名身份。 | 硬件、商店交付版本、上一版升级及审核网络可达性仍须执行；同版本 MSI repair 不是升级资格验证。 |

## 已执行的本地验证

2026-10-23，Flutter 3.41.9 / Dart 3.11.5、Xcode 26.4 SDK：`tool/ci/*test.py` 共 **49** 项回归全通过，包含实际临时 keytool/jarsigner/apksigner/aapt2 与 codesign fixture。按固定源码和仓库 overlays 重建 Tim2Tox release 并 stage，真实后端 macOS ARM64 Release 构建通过（**39.0 MB**）。应用 **22** 个原生代码对象通过架构、最低 OS、strict 签名和最终权限门禁。生成 PKG/ZIP 后分别解包，其 22 个代码对象再次通过，app/FFI/privacy-manifest 哈希与构建一致。ShellCheck、actionlint、源码 guards、`git diff --check` 通过。

这些结果不包含 GUI/聊天 smoke、安装到 `/Applications`、Apple 公证、本地移动/Windows/Linux 构建、商店交付或审核。CI 平台构建作为 PR 独立证据；阻塞/未执行目标不能标成功。

## 官方政策与来源索引

除上面明确标记未读完整者外，核验日期均为 **2026-10-23**。每次发布重开动态来源，构建检查器不硬编码政策截止日期。

- Apple：[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)（UGC 1.2、审核访问 2.1、隐私/删除 5.1.1）；[privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)、[required API reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)、[出口合规](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)、[签名](https://developer.apple.com/library/archive/technotes/tn2206/_index.html)、[公证](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)。针对移动及其他列明平台的 required-reason 执行规则不能直接泛化到所有 macOS 渠道。
- Android/Play：[应用签名](https://developer.android.com/studio/publish/app-signing)、[apksigner](https://developer.android.com/tools/apksigner)、[JAR 验证](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/jar/JarFile.html)、[16 KB](https://developer.android.com/guide/practices/page-sizes)、[target API](https://support.google.com/googleplay/android-developer/answer/11926878)、[User Data](https://support.google.com/googleplay/android-developer/answer/10144311)、[账号删除](https://support.google.com/googleplay/android-developer/answer/13327111)、[UGC](https://support.google.com/googleplay/android-developer/answer/9876937)。本日普通手机/平板新应用和更新要求 API 36；16 KB 指引称自 2027-02-01 阻止不支持的更新。发布时核实际适用性及控制台账号测试例外。
- Microsoft：[Store 政策](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies) 7.20，于 2026-10-22 生效；10.2.9 针对非游戏 HTTPS MSI/EXE。[MSI/EXE](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-package-requirements)、[MSIX](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements)、[MSI 架构 template](https://learn.microsoft.com/en-us/windows/win32/msi/template-summary)。旧支持文案与生效政策冲突时按适用现行政策处理，不将 MSI 要求泛化为 Store-signed MSIX。
- Linux：[Flathub 强制要求](https://docs.flathub.org/docs/for-app-authors/requirements)（含当前 AI 材料/提交交互限制）、[质量指南](https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines/quality-guidelines)、[Snap 沙盒](https://documentation.ubuntu.com/security/security-features/privilege-restriction/snap-confinement/)、[Snap 渠道](https://documentation.ubuntu.com/snapcraft/stable/reference/channels/)。本次仓库改动不生成 Flathub manifest，不提交或参与 Flathub 审核交互。
- 国内候选：[华为审核要求](https://developer.huawei.com/consumer/cn/doc/app/50104)、[小米审核入口](https://dev.mi.com/distribute/doc/details?pId=1139)。本次未能完整读取动态/登录内容，选定渠道后由负责人核控制台最新要求。

[English](./APP_STORE.md)

# DitMesh 发布与商店配置

## 安装包与发布信息

- 核对 tag、版本和构建号，运行分析、测试及平台构建。
- 检查内嵌原生库和运行时依赖，验证 SHA256SUMS。
- 审阅 GitHub 草稿 Release 和当前中英文截图。
- 检查备份恢复、离线发送、联系人、群组、屏蔽及数据删除。

## 分发配置

| 平台 | 配置 |
|---|---|
| iOS | App Store Connect 记录、Apple Team、分发证书、描述文件及归档上传 |
| macOS | Developer ID 签名与公证 |
| Android | 发布/上传密钥、商店账号及 APK/AAB 签名 |
| Windows / Linux | 安装包运行检查及适用的发行者签名 |

签名凭据保存在 CI secrets 或本地签名配置中。

## 产品与隐私信息

商店介绍说明 Morse 单聊和群聊、Tox 身份及点对点联网。根据应用和原生库的实际行为填写加密及隐私问卷。

摄像头用于添加二维码联系人，麦克风用于本地电码解码，通知用于消息提醒。填写公开的[隐私政策](../../site/zh-CN/privacy.md)、[条款](../../site/zh-CN/terms.md)和[支持页面](../../site/zh-CN/support.md)。

内容管理说明涵盖联系人屏蔽及点对点内容处理方式。

## Android：SDK 级别与 16 KB 页

| 设置 | 值 | 位置 |
|---|---|---|
| `compileSdk` | 36 | `apps/ditmesh/android/app/build.gradle.kts`，显式固定（不从 Flutter Gradle 插件继承） |
| `minSdk` | 24 | 同上；Flutter 3.41 的下限，也是 `NetworkPathChannel` 需要的级别 |
| `targetSdk` | 36 | 同上；Google Play 自 2026-08-31 起要求新应用和更新使用 API 36 |
| 插件代码使用的 NDK | `flutter.ndkVersion`（Flutter 3.41.9 为 28.2） | r28 及以上默认按 16 KB 页对齐链接；不要固定到 r28 以下 |
| `libtim2tox_ffi.so`、`libc++_shared.so` | 以 `-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384` 和 `ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON` 链接；`tool/ci/build_tim2tox.sh` 拒绝未对齐的结果，包括 r27 之前 NDK 自带的 4 KB `libc++_shared.so` | `tool/build_android_ffi.sh` → `tool/ci/build_tim2tox.sh` |

`test/platform/mobile_platform_config_test.dart` 固定了这三个级别和链接标志。三个级别要一起提高并同步更新本表。

Google Play 要求面向 Android 15+ 的应用中每个 64 位原生库都支持 16 KB 页（每次发布前到 Play 的"16 KB page size"政策页核对强制日期；撰写时为 2027-02-01）。上传 Play 前要检查最终的 APK/AAB，而不只是本仓库构建的库，因为插件库（`libflutter.so`、`libapp.so`、`mobile_scanner` 的 ML Kit 条码库）来自各自的工具链：

```bash
zipalign -c -P 16 -v 4 app-release.apk          # build-tools 35+
unzip -o app-release.apk 'lib/arm64-v8a/*' 'lib/x86_64/*' -d apk
for so in apk/lib/*/*.so; do echo "$so"; llvm-readelf -lW "$so" | grep -E '^\s+LOAD'; done   # 每个 Align 都应 >= 0x4000
```

然后在 16 KB 设备或模拟器镜像上运行（Pixel 8 及以上的开发者选项"Boot with 16KB page size"，或 `16k` 系统镜像）并打开一个会话：只支持 4 KB 的库会在 `DynamicLibrary.open` 时失败。

预测性返回已启用（`android:enableOnBackInvokedCallback="true"`）；Android 16 对 targetSdk 36 本来就默认启用，该属性让 Android 13–15 行为一致。

## iOS：出口合规（`ITSAppUsesNonExemptEncryption`）

`Info.plist` 声明 `ITSAppUsesNonExemptEncryption = true`：每个构建都包含 libsodium（Tox）。本仓库不对这一用途做分类；由所有者在 App Store Connect 中决定分类，并把结果记录在此。

1. 首次上传时，在 App Store Connect 回答出口合规问题（App Information › App Encryption Documentation，或在 TestFlight › Manage Compliance 按构建回答）。若该用途符合豁免（例如加密仅用于身份验证，或仅使用公开标准做数据传输），记录是哪一项；否则获取 ERN / CCATS 或自分类报告，并按要求提交年度自分类。
2. App Store Connect 为已批准的分类签发出口合规代码后，把它作为 `ITSEncryptionExportComplianceCode`（非空字符串）加入 `apps/ditmesh/ios/Runner/Info.plist`。此后每个上传的构建都会自动回答这些问题，TestFlight 构建不再因"Missing Compliance"被扣住。
3. 在下方记录决定（类别或文档编号、日期、决定人）。

不要为了跳过问题而把 `ITSAppUsesNonExemptEncryption` 改成 `false`：对本应用而言那是虚假声明。MorseCQ（无联网、无 libsodium）声明的是 `false`，不要把它的 plist 值复制过来。`test/platform/mobile_platform_config_test.dart` 检查该标志，并拒绝空的合规代码。

决定记录：暂无（待所有者处理）。

## 设备上的静态数据

- Android：身份（Tox 配置、历史、设置）位于应用私有的 files 目录（`getApplicationSupportDirectory()` → `files/`）。`allowBackup="false"`、`fullBackupContent="false"` 和 `data_extraction_rules.xml` 把所有域排除在云备份和设备间迁移之外。不写外部存储；分享时只把一份副本放进应用临时目录交给分享面板，用后删除。
- iOS：`<Application Support>/ditmesh` 被标记为 `isExcludedFromBackup`（通道 `icu.agentx.ditmesh/backup_exclusion`）。数据保护为平台默认的 `NSFileProtectionCompleteUntilFirstUserAuthentication`（没有 `com.apple.developer.default-data-protection` 权限）：文件在开机后首次解锁前加密，之后在后台可读，这是持久化刷写所需要的。
- 设有密码的身份还由原生代码在磁盘上额外加密——创建时、在线时、持久化后和在线改密后都是（`packages/ditmesh_chat/test/native_encryption_test.dart`，标签 `needs-native`）。

## iPad 多任务与分享面板

iPhone 支持竖屏和两个横屏方向；iPad 支持全部四个方向且未设置 `UIRequiresFullScreen`，因此 Split View、Slide Over 和 Stage Manager 都适用，最窄到 320 pt。每个分享动作（备份导出、局域网节点信息、学习素材导出）都通过 `sharePositionOrigin` 把弹出框锚定到被点击的控件；`test/platform/share_origin_guard_test.dart` 会让没有锚点的分享调用失败。

## Android 通知渠道

三个渠道（`ditmesh_messages`、`ditmesh_friend_requests`、`ditmesh_group_invites`）。"我"页面上的应用内开关是用户偏好，不是系统状态：用户在系统设置里屏蔽某个渠道后，`areNotificationsEnabled()` 仍为 true，发到该渠道的通知会被系统丢弃；应用目前不反映被屏蔽的渠道（移动设备评审的待办项）。

## 设备检查

检查侧音、静音键播放、触觉反馈、触摸和键盘控制、摄像头扫描、通知跳转、群组持久化、后台恢复及备份操作。已执行的自动化检查见[验证记录](../VALIDATION.zh-CN.md)。

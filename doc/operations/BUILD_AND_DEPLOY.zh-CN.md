[English](./BUILD_AND_DEPLOY.md)

# 构建、CI 与打包

使用 Flutter 3.41.9 / Dart 3.11.5。从仓库根目录初始化子模块，按已提交的锁文件解析工作区依赖。

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get --enforce-lockfile
```

bootstrap 固定并补丁化 Dart 兼容 SDK，通过 overlay 移除腾讯原生 IM 插件，写入不提交的依赖 overrides。Tim2Tox 在 Linux、macOS、Android、iOS 上链接 c-toxcore 与固定版本静态 libsodium；Windows 使用 vcpkg 的 libsodium 与 pthreads，以 DLL 形式放在 `tim2tox_ffi.dll` 旁一起打包。不启用 ToxAV。

它也把固定 Tim2Tox 的 Dart 包复制到忽略目录 `third_party/tim2tox_ditmesh`，应用 `tool/ci/tim2tox-dart-overlays` 中的原始节奏传输补丁。根 overrides 和 lock 指向该副本。可用 `dart run tool/bootstrap_deps.dart --offline-check-only` 按上游源码和评审补丁验证；两者有变化时重新运行 bootstrap，保持上游子模块干净。

macOS 应用要求 **13.0 及以上**，Intel/ARM 一致，以满足内嵌 Objective-C 框架。生成 ZIP/PKG 前，打包器逐个核对实际 Mach-O 各架构要求与主应用声明，依赖要求更高时直接阻止打包。传输库本身可以支持更低系统版本，不会降低应用要求。

## 本机构建

在仓库根目录执行对应平台的命令，构建并暂存 Tim2Tox。

| 目标 | 主机工具 | 原生构建命令 |
|---|---|---|
| macOS（Apple 芯片或 Intel） | Xcode、CocoaPods、CMake | `bash tool/ci/build_tim2tox.sh --target macos` |
| Linux x86_64 | C/C++ 工具链、CMake、Ninja 或 Make、pkg-config、Flutter Linux 桌面依赖 | `bash tool/ci/build_tim2tox.sh --target linux-x86_64` |
| Windows x64 | MSVC C++ 工具链、CMake、vcpkg 依赖和 `VCPKG_ROOT`。在已配置 MSVC 的环境中使用 Git Bash。 | `bash tool/ci/build_tim2tox.sh --target windows-x64` |
| Android | Android SDK 和 NDK `28.2.13676358`、JDK 17 | `ABIS=arm64-v8a,armeabi-v7a,x86_64 bash tool/build_android_ffi.sh` |
| iOS / iPadOS 真机或模拟器 | macOS、含 iOS 26 SDK 的 Xcode 26、CocoaPods、CMake | `bash tool/build_ios_ffi.sh` |

用 `bash tool/ci/build_tim2tox.sh --help` 查看原生构建的依赖和选项。macOS 可用 `macos-arm64` 或 `macos-x86_64` 显式选择库架构。Android 统一用 `android` 目标和 `--android-abis` 选项，辅助脚本会传入 `ABIS`。iOS 辅助脚本把 `ios-device` 和 `ios-simulator` 的产物合成 XCFramework。单独构建一个目标时，可传入 `--device-only` 或 `--simulator-only`。

随后进入 `apps/ditmesh`，只运行对应目标的 Flutter 命令。需要交互调试时，用 `flutter devices` 查看设备，并在对应原生库已暂存的情况下执行 `flutter run -d <device-id>`。iOS 真机还需要开发签名。

| 目标 | 在 `apps/ditmesh` 下运行 |
|---|---|
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |
| Windows | `flutter build windows --release` |
| Android APK | `flutter build apk --release` |
| Android App Bundle | `flutter build appbundle --release` |
| iOS | `flutter build ios --release --no-codesign` |

原生产物位于仓库根目录下的 `build/native/<target>/`。构建脚本会把 macOS 原生库暂存到 `apps/ditmesh/macos/Frameworks/`。Android 从 `apps/ditmesh/android/app/src/main/jniLibs/` 读取原生库，iOS 从 `apps/ditmesh/ios/Frameworks/tim2tox_ffi.xcframework` 读取。Linux 和 Windows 构建应用时使用对应目标的目录。

暂存原生库后，用 `flutter build apk --release -PstoreRelease` 或 `flutter build appbundle --release -PstoreRelease` 构建商店产物。请提供完整的四项 `DITMESH_ANDROID_*` 密钥库配置，或设置 `apps/ditmesh/android/key.properties`。Gradle 会验证签名后的 AAB 和每个 APK（含 ABI 拆分包），并拒绝 Android Debug 证书。标签构建通过 `DITMESH_DISTRIBUTION=1` 启用这些检查，并按负责人提供的上传证书校验最终 APK 和 AAB。

Android SDK 级别在 `apps/ditmesh/android/app/build.gradle.kts` 中显式钉住（`compileSdk` 36、`minSdk` 24、`targetSdk` 36），不再从 Flutter Gradle 插件继承，Flutter 升级不会悄悄改动它们；`ndkVersion` 跟随 Flutter，但不得低于 r28。CI 钉住同一个 NDK（`.github/workflows/native.yml` 中的 `ANDROID_NDK_VERSION`，Flutter 3.41.9 对应 28.2.13676358），不使用 runner 镜像的最新版；`tool/ci/install_android_ndk.sh` 负责安装，并在它与 Flutter SDK 的 `ndkVersion` 不一致时失败，因此两者须一起升级。Android 原生构建对每个库都加 16 KB 页对齐链接标志，`libtim2tox_ffi.so` 或 `libc++_shared.so` 的 `PT_LOAD` 段若未按 16 KB 对齐则拒绝放入 jniLibs（Google Play 对面向 Android 15+ 应用的要求）。CI 会对发布 APK 再查一遍，包括 Flutter 与插件的库，并用 `zipalign -c -P 16` 校验 APK 的 zip 对齐。

应用构建后回到根目录运行：

```bash
bash tool/ci/package_artifacts.sh --target macos
# linux、windows、android 和 ios 在各自的构建主机上运行。
```

`./build_all.sh --platform macos --mode release --package` 可依次完成依赖初始化、原生库和应用构建及打包，并输出 `dist/macos/ditmesh-<version>-macos-<arch>.{pkg,zip}`。版本取自 `apps/ditmesh/pubspec.yaml`，架构取自当前 Mac。各平台的安装包都输出到 `dist/` 下。

## CI 与发布

Analyze 执行严格分析、复杂度/分层/本地化 guard、截图导入检查与非原生测试。Native 包含必要原生库和应用安装包，Dart、共享包、pubspec 修改均覆盖触发。必要目标涵盖 Linux x86_64、Windows x64、macOS ARM/Intel、Android ARM64/ARMv7/x86_64 和 iOS 设备/模拟器；实验性 ARM 主机任务单独选择运行。

tag 发布等待验证和必要应用构建；`vX.Y.Z` tag 必须与 `apps/ditmesh/pubspec.yaml` 中的 `X.Y.Z` 一致（`tool/ci/release_version.sh`，Analyze 也会运行），因此打 tag 前先提升版本号。随后核对预期安装包、生成 SHA256SUMS，创建或更新 GitHub 草稿 Release。截图/E2E 使用预置聊天数据并按需运行；原生集成测试使用真实 Tox 节点。

工作流语义见 [GitHub 官方文档](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)；实际执行证据见[验证记录](../VALIDATION.zh-CN.md)。

打包现逐 app/engine/plugin 核真实 PE/ELF/Mach-O 架构，并检查实际 Windows MSI 目标元数据。Android 核 APK/AAB 全部原生库和最终签名；tag/distribution 需要负责人在 `DITMESH_ANDROID_CERT_SHA256` 提供预期证书 SHA-256。APK ZIP 16 KB 放置适用于未压缩 `.so`，AAB 生成 APK/设备证据仍须补齐。macOS 在 staging 后由内到外签验证包，逐最终代码签名/权限核验并禁止 `get-task-allow`。默认 `--mode validation`；未实现的正式 `--mode distribution` 直接失败，不回退未签/ad-hoc 替代包。参见[渠道矩阵与命令](../release/STORE_READINESS.zh-CN.md)。

## 签名

iOS 配置 Apple 分发证书和描述文件，macOS 配置 Developer ID 签名及公证，Android 配置发布/上传密钥。凭据保存在 CI secrets 或本地签名配置中。见[发布要求](../release/APP_STORE.zh-CN.md)与 [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)。

## 故障排查

| 现象 | 检查方法 |
|---|---|
| 工作区无法解析 `tim2tox_dart` 或兼容 SDK | 从根目录运行 `dart run tool/bootstrap_deps.dart --offline-check-only`。若暂存的依赖缺失或过期，重新执行 bootstrap，再运行 `dart pub get --enforce-lockfile`。 |
| 构建或启动时提示缺少 Tim2Tox | 先为目标系统和 CPU 暂存原生库，再运行 Flutter。Android 要包含设备 ABI，iOS 的 XCFramework 要包含所选的真机或模拟器切片。 |
| 应用能启动，但聊天持续离线 | 在应用中测试所选节点。网络指南涵盖公网节点故障、UDP 限制与局域网权限。见[引导节点与局域网托管](NETWORK.zh-CN.md)。 |

仅运行界面时可使用内存后端。截图工具自带演示数据。见[应用开发指南](../../apps/ditmesh/README.zh-CN.md#运行)与[截图采集指南](../../tool/screenshots/README.zh-CN.md)。

## 可复现性

构建结果应记录源码提交、Tim2Tox SHA、固定的 Flutter/Dart 版本和架构。`assert_no_test_hooks.sh` 检查发布用 FFI 库。

原生构建在源码副本上应用[源码 overlay](../../tool/ci/tim2tox-overlays/README.zh-CN.md)（群组持久化、成员连接状态、隔离的节点探测），上游检出保持干净。Linux、两种 macOS 架构的 CI 都运行本机真实 UDP 节点测试；公网 DHT 探测单独按需启用。发布前应核对并更新[官方 Tox 节点列表](https://nodes.tox.chat/)中的内置引导节点。

[English](./BUILD_AND_DEPLOY.md)

# 构建、CI 与打包

使用 Flutter 3.41.9 / Dart 3.11.5，递归克隆子模块，只在根目录解析依赖。

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get
```

bootstrap 固定并补丁化 Dart 兼容 SDK，通过 overlay 移除腾讯原生 IM 插件，写入不提交的依赖 overrides。Tim2Tox 在 Linux、macOS、Android、iOS 上链接 c-toxcore 与固定版本静态 libsodium；Windows 使用 vcpkg 的 libsodium 与 pthreads，以 DLL 形式放在 `tim2tox_ffi.dll` 旁一起打包。不启用 ToxAV。

它也把固定 Tim2Tox 的 Dart 包复制到忽略目录 `third_party/tim2tox_ditmesh`，应用 `tool/ci/tim2tox-dart-overlays` 中的原始节奏传输补丁。根 overrides 和 lock 指向该副本。可用 `dart run tool/bootstrap_deps.dart --offline-check-only` 按上游源码和评审补丁验证；两者有变化时重新运行 bootstrap，保持上游子模块干净。

macOS 应用要求 **13.0 及以上**，Intel/ARM 一致，以满足内嵌 Objective-C 框架。生成 ZIP/PKG 前，打包器逐个核对实际 Mach-O 各架构要求与主应用声明，依赖要求更高时直接阻止打包。传输库本身可以支持更低系统版本，不会降低应用要求。

## 本机目标命令

```bash
# 在兼容的目标主机/工具链上运行：
bash tool/ci/build_tim2tox.sh --target macos-arm64
# 其他目标：macos-x86_64、linux-x86_64、windows-x64、
# android-arm64、android-armv7、android-x86_64、ios-device、ios-simulator

# 用辅助脚本暂存移动端库：
bash tool/build_android_ffi.sh
bash tool/build_ios_ffi.sh
cd apps/ditmesh
flutter build macos --release
# 在对应主机上：
flutter build linux --release
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
```

新主机构建前先查脚本 `--help` 的目标名与选项。桌面在 `build/native/` 查找库，Android 放入 jniLibs，iOS 放入 XCFramework。应用构建前需放置对应的原生库。

Android SDK 级别在 `apps/ditmesh/android/app/build.gradle.kts` 中显式钉住（`compileSdk` 36、`minSdk` 24、`targetSdk` 36），不再从 Flutter Gradle 插件继承，Flutter 升级不会悄悄改动它们；`ndkVersion` 跟随 Flutter，但不得低于 r28。CI 钉住同一个 NDK（`.github/workflows/native.yml` 中的 `ANDROID_NDK_VERSION`，Flutter 3.41.9 对应 28.2.13676358），不使用 runner 镜像的最新版；`tool/ci/install_android_ndk.sh` 负责安装，并在它与 Flutter SDK 的 `ndkVersion` 不一致时失败，因此两者须一起升级。Android 原生构建对每个库都加 16 KB 页对齐链接标志，`libtim2tox_ffi.so` 或 `libc++_shared.so` 的 `PT_LOAD` 段若未按 16 KB 对齐则拒绝放入 jniLibs（Google Play 对面向 Android 15+ 应用的要求）。CI 会对发布 APK 再查一遍，包括 Flutter 与插件的库，并用 `zipalign -c -P 16` 校验 APK 的 zip 对齐。

应用构建后回到根目录运行：

```bash
bash tool/ci/package_artifacts.sh --target macos
# linux、windows、android 和 ios 在各自的构建主机上运行。
```

`./build_all.sh --platform macos --mode release --package` 可统筹并输出 `dist/macos/ditmesh-<version>-macos-arm64.{pkg,zip}`（`<version>` 取自 `apps/ditmesh/pubspec.yaml`）。安装包输出到 `dist/`。

## CI 与发布

Analyze 执行严格分析、复杂度/分层/本地化 guard、截图导入检查与非原生测试。Native 包含必要原生库和应用安装包，Dart、共享包、pubspec 修改均覆盖触发。必要目标涵盖 Linux x86_64、Windows x64、macOS ARM/Intel、Android ARM64/ARMv7/x86_64 和 iOS 设备/模拟器；实验性 ARM 主机任务单独选择运行。

tag 发布等待验证和必要应用构建；`vX.Y.Z` tag 必须与 `apps/ditmesh/pubspec.yaml` 中的 `X.Y.Z` 一致（`tool/ci/release_version.sh`，Analyze 也会运行），因此打 tag 前先提升版本号。随后核对预期安装包、生成 SHA256SUMS，创建或更新 GitHub 草稿 Release。截图/E2E 使用预置聊天数据并按需运行；原生集成测试使用真实 Tox 节点。

工作流语义见 [GitHub 官方文档](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)；实际执行证据见[验证记录](../VALIDATION.zh-CN.md)。

打包现逐 app/engine/plugin 核真实 PE/ELF/Mach-O 架构，并检查实际 Windows MSI 目标元数据。Android 核 APK/AAB 全部原生库和最终签名；tag/distribution 需要负责人在 `DITMESH_ANDROID_CERT_SHA256` 提供预期证书 SHA-256。APK ZIP 16 KB 放置适用于未压缩 `.so`，AAB 生成 APK/设备证据仍须补齐。macOS 在 staging 后由内到外签验证包，逐最终代码签名/权限核验并禁止 `get-task-allow`。默认 `--mode validation`；未实现的正式 `--mode distribution` 直接失败，不回退未签/ad-hoc 替代包。参见[渠道矩阵与命令](../release/STORE_READINESS.zh-CN.md)。

## 签名

iOS 配置 Apple 分发证书和描述文件，macOS 配置 Developer ID 签名及公证，Android 配置发布/上传密钥。凭据保存在 CI secrets 或本地签名配置中。见[发布要求](../release/APP_STORE.zh-CN.md)与 [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)。

## 可复现性与诊断

构建结果记录源码、Tim2Tox SHA、Flutter/Dart 和架构；发布 FFI 用 `assert_no_test_hooks.sh` 检查。使用预置会话开发界面时，可启用 `DITMESH_FAKE_BACKEND=true` 及构建脚本中说明的缺 FFI 选项。

原生构建在源码副本上应用[源码 overlay](../../tool/ci/tim2tox-overlays/README.zh-CN.md)（群组持久化、成员连接状态、隔离的节点探测），上游检出保持干净。Linux、两种 macOS 架构的 CI 都运行本机真实 UDP 节点测试；公网 DHT 探测单独按需启用。发布前应核对并更新[官方 Tox 节点列表](https://nodes.tox.chat/)中的内置引导节点。

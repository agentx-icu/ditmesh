[English](./BUILD_AND_DEPLOY.md)

# 构建、CI 与打包

使用 Flutter 3.41.9 / Dart 3.11.5，递归克隆子模块，只在根目录解析依赖。

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get
bash tool/ci/build_tim2tox.sh --target macos-arm64
```

bootstrap 固定并补丁化 Dart 兼容 SDK，通过 overlay 移除腾讯原生 IM 插件，写入不提交的依赖 overrides。Tim2Tox 链接 c-toxcore 与固定版本静态 libsodium，不启用 ToxAV。

macOS 应用要求 **13.0 及以上**，Intel/ARM 一致，以满足内嵌 Objective-C 框架。生成 ZIP/PKG 前，打包器逐个核对实际 Mach-O 各架构要求与主应用声明，依赖要求更高时直接阻止打包。传输库本身可以支持更低系统版本，不会降低应用要求。

## 本机构建

在相应主机/工具链运行原生 target；新主机先查脚本 `--help` 的目标名与选项。

```bash
bash tool/build_android_ffi.sh
bash tool/build_ios_ffi.sh
cd apps/ditmesh
flutter build macos --release
flutter build linux --release
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
```

桌面在 `build/native/` 查找库，Android 放入 jniLibs，iOS 放入 XCFramework。应用构建前需放置对应的原生库。

Android SDK 级别在 `apps/ditmesh/android/app/build.gradle.kts` 中显式钉住（`compileSdk` 36、`minSdk` 24、`targetSdk` 36），不再从 Flutter Gradle 插件继承，Flutter 升级不会悄悄改动它们；`ndkVersion` 跟随 Flutter，但不得低于 r28。Android 原生构建对每个库都加 16 KB 页对齐链接标志，`libtim2tox_ffi.so` 或 `libc++_shared.so` 的 `PT_LOAD` 段若未按 16 KB 对齐则拒绝放入 jniLibs（Google Play 对面向 Android 15+ 应用的要求）。CI 会对发布 APK 再查一遍，包括 Flutter 与插件的库，并用 `zipalign -c -P 16` 校验 APK 的 zip 对齐。

应用构建后回到根目录运行：

```bash
bash tool/ci/package_artifacts.sh --target macos
```

linux/windows/android/ios 在对应主机构建和打包；`./build_all.sh --platform macos --mode release --package` 可统筹并输出 `dist/macos/ditmesh-1.0.0-macos-arm64.{pkg,zip}`。安装包输出到 `dist/`。

## CI 与发布

Analyze 执行严格分析、复杂度/分层/本地化 guard、截图导入检查与非原生测试。Native 包含必要原生库和应用安装包，Dart、共享包、pubspec 修改均覆盖触发。必要目标涵盖 Linux x86_64、Windows x64、macOS ARM/Intel、Android ARM64/ARMv7/x86_64 和 iOS 设备/模拟器；实验性 ARM 主机任务单独选择运行。

tag 发布等待验证和必要应用构建，核对预期安装包、生成 SHA256SUMS，创建或更新 GitHub 草稿 Release。截图/E2E 使用预置聊天数据并按需运行；原生集成测试使用真实 Tox 节点。

工作流语义见 [GitHub 官方文档](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)；实际执行证据见[验证记录](../VALIDATION.zh-CN.md)。

## 签名与复现

iOS 配置 Apple 分发证书和描述文件，macOS 配置 Developer ID 签名及公证，Android 配置发布/上传密钥。凭据保存在 CI secrets 或本地签名配置中。见[发布要求](../release/APP_STORE.zh-CN.md)与 [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)。

构建结果记录源码、Tim2Tox SHA、Flutter/Dart 和架构；发布 FFI 用 `assert_no_test_hooks.sh` 检查。使用预置会话开发界面时，可启用 `DITMESH_FAKE_BACKEND=true` 及构建脚本中说明的缺 FFI 选项。

原生构建在源码副本上应用[群状态持久化补丁](../../tool/ci/tim2tox-overlays/README.md)，上游检出保持干净。Linux、两种 macOS 架构的 CI 都运行本机真实 UDP 节点测试；公网 DHT 探测单独按需启用。发布前应核对并更新[官方 Tox 节点列表](https://nodes.tox.chat/)中的内置引导节点。

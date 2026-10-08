[English](./BUILD_AND_DEPLOY.md)

# 构建、CI 与打包

使用 Flutter 3.41.9 / Dart 3.11.5，递归克隆子模块，只在根目录解析依赖。

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get
bash tool/ci/build_tim2tox.sh --target macos-arm64
```

bootstrap 固定并补丁化 Dart 兼容 SDK，通过 overlay 移除腾讯原生 IM 插件，写入不提交的依赖 overrides。聊天不是腾讯服务器实现；Tim2Tox 链接 c-toxcore 与固定版本静态 libsodium，不启用 ToxAV。

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

桌面在 `build/native/` 查找库，Android 放入 jniLibs，iOS 放入 XCFramework。缺必要库必须失败，完整发布不能静默成为演示界面。

应用构建后回到根目录运行：

```bash
bash tool/ci/package_artifacts.sh --target macos
```

linux/windows/android/ios 在对应主机构建和打包；`./build_all.sh --platform macos --mode release --package` 可统筹并输出 `dist/macos/ditmesh-1.0.0-macos-arm64.{pkg,zip}`。安装包使用 DitMesh 独立产品与升级标识，输出位于不提交的 `dist/`。

## CI 与发布

Analyze 执行严格分析、复杂度/分层/本地化 guard、截图导入检查与非原生测试。Native 包含必要原生库和应用安装包，Dart、共享包、pubspec 修改均覆盖触发。必要目标涵盖 Linux x86_64、Windows x64、macOS ARM/Intel、Android ARM64/ARMv7/x86_64 和 iOS 设备/模拟器；实验性 ARM 主机任务单独选择运行。

tag 发布等待验证和必要应用构建，核对预期安装包、生成 SHA256SUMS，创建或更新 GitHub 草稿 Release。截图/E2E 使用显式演示后端；演示截图不能代替真实传输验证。

工作流语义见 [GitHub 官方文档](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)；实际执行证据见[验证记录](../VALIDATION.zh-CN.md)。

## 签名与复现

源码/CI iOS IPA 未签名，macOS 未配置所有者凭据时不公证，Android 商店上传需要发布/上传密钥。秘密只放 CI 凭据存储，不进入 Git。见[发布要求](../release/APP_STORE.zh-CN.md)与 [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)。

构建结果记录源码、Tim2Tox SHA、Flutter/Dart 和架构；发布 FFI 用 `assert_no_test_hooks.sh` 检查。校验和不能代替代码签名。缺 FFI 的放行只用于显式演示构建，不能作为可聊天产品发布。

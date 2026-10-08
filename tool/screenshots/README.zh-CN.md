[English](./README.md)

# 产品截图与视觉矩阵

默认命令驱动真实 ditmesh 应用，维护英文 / 简体中文、Modern Calm、浅色主题的标准图库。支持 macos、linux、windows、ios（iPhone）、ipad 和 android 六个目标；桌面使用对应主机，移动端使用设备或模拟器。iPhone/iPad 截图会验证 App Store 尺寸及无透明通道的 RGB PNG。

```bash
tool/screenshots/capture.sh --platforms macos
tool/screenshots/capture.sh --platforms android --device emulator-5554
tool/screenshots/capture.sh --locales zh_Hant,ja,ko --style paper --theme dark --out build/visual-paper
tool/screenshots/capture.sh --locales en,zh,zh_Hant,ja,ko,de,fr,es,pt,ru --style all --out build/visual-all
```

语言标签为 `en,zh,zh_Hant,ja,ko,de,fr,es,pt,ru`，样式为 `classic,modern,radio,paper,cartoon`。`--style all` 将五种样式分别输出到 `<out>/<style>/<平台>/<语言>/<场景>.png`；单一样式输出到 `<out>/<平台>/<语言>/<场景>.png`。主题支持 `light,dark,system`；`DITMESH_SHOT_STYLE` 和 `DITMESH_SHOT_THEME` 提供环境默认值，显式参数优先。捕获器会实际应用所选样式，并将繁体中文解析为 Hant 脚本。

任意非默认语言集合、样式或主题都必须显式指定 `--out`，且位于 `doc/screenshots` 之外；别名及标准图库内部路径同样被拒绝。其他主机完成的截图可用 `--from /path/to/screenshots` 导入，保留相同语言/样式/主题参数，输出必须与源目录分离。`--style all` 的源包含五个样式目录。选中的源目录及 PNG 不允许符号链接。完整性、尺寸或重复帧检查失败会保留该配置原有图库；不同平台 / 样式配置独立发布。

`--keep` 保留暂存；`DITMESH_SHOT_STAGING` 指定暂存目录，全部样式使用各自的子目录。`DITMESH_SHOT_WINDOW` 指定桌面逻辑尺寸（默认 1280x800），`DITMESH_SHOT_PIXEL_RATIO` 覆盖截图比例。应用通过 RepaintBoundary 捕获自身 Flutter 图层，再由集成测试报告将 PNG 传到主机驱动。导航使用本地化文案与稳定键，截图前检查实际场景。没有翻译种子文案的语言可使用英文演示参与者及消息。

按需运行的 **Visual matrix** 流水线通过手动触发或 PR 的 `ci:e2e` 标签启用。它加载真实 Noto CJK、等宽及衬线字体，生成 **38 个配置 / 76 张 PNG**：十种语言的手机 / 桌面 Modern 浅色界面，以及五种样式的手机 / 桌面浅色 / 深色英文界面；重复配置合并。代表场景为 `conversation / group_conversation`，分别覆盖各维度，避免把全部语言、样式、主题、平台相乘。产物包含 `manifest.json`，现有 E2E 仍在三种真实桌面主机上捕获完整产品场景。

常规 Flutter 测试 `test/screenshots/shot_config_test.dart` 覆盖参数解析和实际样式应用；`python3 tool/screenshots/capture_import_test.py` 使用私有 PNG 验证导入和发布边界。实际矩阵导出按需开启（`DITMESH_RENDER_MATRIX=true`、`DITMESH_MATRIX_DIR`、`DITMESH_MATRIX_FONT`，可另设等宽 / 衬线字体路径），常规应用测试不导出视觉资产。

截图要求包含 13 个场景，每个平台 26 张英文 / 简体中文图片；`network_bootstrap` 通过“我”的网络设置入口展示配置好的自动 bootstrap 节点。导入时缺失该页面会保留已有图库并报错。macOS、iPhone、iPad、Android 已更新，Linux、Windows 等待本次 CI 截图导入，实际状态记于图库索引。

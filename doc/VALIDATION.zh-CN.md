[English](./VALIDATION.md)

# 验证记录 — 2026-10-08

已验证源码：`21224e60ddfe03a90db298b1ba82360e0b0d844e`。工具链：Flutter 3.41.9 / Dart 3.11.5。

## 自动化检查

| 检查 | 结果 |
|---|---|
| [Analyze](https://github.com/agentx-icu/ditmesh/actions/runs/37737114668) | 严格分析、源码守卫、包和应用测试通过。 |
| 应用测试 | 1344 通过；跳过 2 个按需图片导出测试。 |
| 包测试 | 聊天 269、API 79、核心 92、DSP 107、音频 I/O 124、训练 212、无线电工具 18 通过；DSP 跳过 2 个已有的首块噪声底测试。 |
| [原生库与平台构建](https://github.com/agentx-icu/ditmesh/actions/runs/37737115108) | 13 个必需任务全部通过：六个原生目标、六个应用构建和质量检查。 |
| 原生集成 | Linux 和两种 macOS 架构各 11 通过，跳过 1 个单独节点工作入口；三个目标的独立双进程测试均通过。 |
| 真实节点投递 | 双向单聊和群聊、加密资料重启、离线队列恰好投递一次、自动重新入群通过。 |
| 网络行为 | 局域网端口及双客户端连接、节点公钥校验、取消、探测隔离和实例保留通过。 |
| 打包回归 | macOS 运行时 9、打包/overlay/缓存 8、截图导入 19 项检查通过。 |
| [桌面 E2E](https://github.com/agentx-icu/ditmesh/actions/runs/37737114750) | macOS、Linux、Windows 的界面导航、持久化和全部 13 个场景的中英文截图通过。 |
| [视觉矩阵](https://github.com/agentx-icu/ditmesh/actions/runs/37737114693) | 38 个配置、76 张 PNG，覆盖十种语言、五种风格、浅深色及手机/桌面布局。 |

DSP 跳过项涉及极低音量首块噪声可能产生多余起始符号的问题。应用中的按需图片导出测试由截图及视觉工作流执行。

## 截图与安装包

[图库](screenshots/README.zh-CN.md)包含 **156 张截图**：13 个场景 × 中英文 × macOS/iPhone/iPad/Android/Linux/Windows。

| 目标 | 已验证安装包 |
|---|---|
| Android | APK、AAB |
| iOS | IPA |
| macOS | ARM64、Intel 各一组 PKG/ZIP |
| Linux | x86_64 DEB、RPM、tar.gz |
| Windows | x64 MSI、ZIP |

平台构建输出的 **12 个安装包**均已下载并检查产物完整性、SHA-256、归档完整性及内嵌原生库。两种 macOS 架构中的全部 Mach-O 均符合应用要求的最低版本 **13.0**。安装包检查还覆盖信号塔图标及十种语言的 Apple 权限说明。

复现命令见[测试指南](testing/TEST_PYRAMID.zh-CN.md)、[构建指南](operations/BUILD_AND_DEPLOY.zh-CN.md)和[截图指南](../tool/screenshots/README.zh-CN.md)。

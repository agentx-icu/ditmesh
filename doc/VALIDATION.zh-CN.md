[English](./VALIDATION.md)

# 验证记录 — 2026-10-08

实现位于 `codex/chat-migration`。两款应用均未发布，用户已明确移除历史兼容与数据迁移范围。以下记录已执行的验证，并明确区分最终原生修复前的构建；最终远程平台 CI 随修复后执行。

| 检查 | 已执行结果 |
|---|---|
| 原 MorseCQ 基线 | 七个包测试通过；应用 1253 通过、1 跳过 |
| DitMesh 应用 | 早前完整运行 1259 通过、1 跳过；随后删除一项历史兼容回归，最终完整运行由 CI 检查 |
| 聊天 / API 包 | 最终聊天 236 通过、4 跳过 / API 79 通过；备份/容器/.tox 检查 39 通过，默认聊天/身份检查 33 通过；七项数值节点/选择策略测试全部通过 |
| 原生集成 | 四套 needs-native 测试通过：加密/换密、备份/篡改、持久化、身份/网络/离线队列/群组冒烟 |
| 严格分析与源码守卫 | 指定目录分析与三项守卫通过 |
| CI 和打包检查 | actionlint 1.7.12、ShellCheck 0.11、Bash/Podfile 语法、六项打包/补丁回归通过，ShellCheck 0.10/0.11 两版本均通过 |
| 截图导入安全 | 12 项回归通过，使用独立 PNG 测试数据 |
| 原生平台库 | macOS ARM64、Android 三 ABI、iOS 真机与 ARM64/x86_64 模拟器的无测试钩子原生库构建通过 |
| 首轮 macOS ARM64 包 | 最终原生修复前，真实后端 Release 应用、PKG、ZIP 通过；签名完整性、安装路径与禁止 relocation 已检查 |
| 首轮 Android 包 | 最终原生修复前，真实后端 APK/AAB 通过；三 ABI 原生库及运行库已检查；本机包使用调试签名 |
| 首轮 iOS 包 | 最终原生修复前，真实后端未签名 Release 应用/IPA 通过；应用标识、版本、原生隐私清单已检查 |
| 真实截图 | macOS、iPhone、iPad、Android、Linux、Windows 各 12 场景 × 中英文通过，共 144 张 |
| 真实节点传输 | 两个真实 Tox 进程完成双向单聊/群聊、加密身份/偏好重启、队列消息只接收一次、群组自动重入与重启后双向群消息；送达前自身/远端成员在线，断开后远端离线或移除，均通过 |
| 原生源码修复 | 群持久化与成员连接状态补丁仅应用于固定源码副本，上游子模块干净、366 个公开 FFI 导出不变；旧库在线状态回归失败，修复后的库通过 |
| 全新身份公网启动 | 数值默认节点的可选公网 DHT 探测 10 秒通过；必需 CI 使用两个本机真实节点保证确定性 |
| 桌面 E2E CI | [macOS/Linux/Windows 界面与截图 CI 通过](https://github.com/agentx-icu/ditmesh/actions/runs/37719469365) |
| 远程 CI | [草稿 PR #1](https://github.com/agentx-icu/ditmesh/pull/1) 执行 Native/Analyze/E2E；首轮六个原生目标与 Linux/Windows/Android/iOS 应用包通过；脚本检查已修复，必需网络 CI 改为两个本机真实 UDP 节点；最终 CI 待执行 |

来源 MorseCQ `3ce9597`；Tim2Tox 固定为 `093730ce346cef186bfd3d71214343b38d6c5ca6`。本机：Apple Silicon macOS、Xcode 26.4.1、Flutter 3.41.9、Dart 3.11.5。临时日志为 `/tmp/ditmesh-source-baseline.log`、`/tmp/ditmesh-chat-final-full-tests.log`。

最终群持久化/引导节点修复前，忽略的 `dist/` 中已生成过：macOS PKG 25,876,884 字节、ZIP 26,109,945 字节；Android APK 107,613,474 字节、AAB 73,469,570 字节；iOS 未签名 IPA 12,820,577 字节。Release 门禁要求十二个平台资产及 SHA256SUMS 完整，才更新 GitHub 草稿 Release。

原生源码下载有固定摘要；代理失效时只对单条 GitHub 命令停用继承代理，不修改全局设置。已补充独立安装器标识、下载原子替换/错误传播、macOS 主应用安装路径与禁止 relocation 的修复。

真机行为及正式签名/公证另行验证。本次没有创建发布 tag、合并或提交商店。

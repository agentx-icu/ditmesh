[English](./VALIDATION.md)

# 验证记录 — 2026-10-08

实现位于 `codex/chat-migration`。以下是已执行的本机验证；远程平台 CI 是下一道检查。

| 检查 | 已执行结果 |
|---|---|
| 原 MorseCQ 基线 | 七个包测试通过；应用 1253 通过、1 跳过 |
| DitMesh 应用 | 1259 通过、1 跳过 |
| 聊天 / API 包 | 230 通过、3 个原生测试跳过 / 79 通过 |
| 原生集成 | 四套 needs-native 测试通过：加密/换密、备份/篡改、持久化、身份/网络/离线队列/群组冒烟 |
| 严格分析与源码守卫 | 指定目录分析与三项守卫通过 |
| CI 和打包检查 | actionlint 1.7.12、ShellCheck 0.11、Bash/Podfile 语法、五项打包回归通过 |
| 截图导入安全 | 12 项回归通过，使用独立 PNG 测试数据 |
| 原生平台库 | macOS ARM64、Android 三 ABI、iOS 真机与 ARM64/x86_64 模拟器的无测试钩子原生库构建通过 |
| macOS ARM64 | 真实后端 Release 应用、PKG、ZIP 通过；签名完整性、安装路径与禁止 relocation 的元数据已检查 |
| Android | 真实后端 APK/AAB 通过；三 ABI 原生库及运行库已检查；本机包使用调试签名 |
| iOS | 真实后端未签名 Release 应用/IPA 通过；应用标识、版本、原生隐私清单已检查 |
| 真实截图 | macOS、iPhone 各 12 场景 × 中英文通过；iPad/Android 采集中 |
| 远程 CI | 待创建草稿 PR；尚不声称 Linux、Windows、macOS Intel 已构建通过 |

来源 MorseCQ `3ce9597`；Tim2Tox 固定为 `093730ce346cef186bfd3d71214343b38d6c5ca6`。本机：Apple Silicon macOS、Xcode 26.4.1、Flutter 3.41.9、Dart 3.11.5。临时日志为 `/tmp/ditmesh-source-baseline.log`、`/tmp/ditmesh-chat-final-full-tests.log`。

忽略的 `dist/` 中已生成：macOS PKG 25,876,884 字节、ZIP 26,109,945 字节；Android APK 107,613,474 字节、AAB 73,469,570 字节；iOS 未签名 IPA 12,820,577 字节。Release 门禁要求十二个平台资产及 SHA256SUMS 完整，才更新 GitHub 草稿 Release。

原生源码下载有固定摘要；代理失效时只对单条 GitHub 命令停用继承代理，不修改全局设置。已补充独立安装器标识、下载原子替换/错误传播、macOS 主应用安装路径与禁止 relocation 的修复。

真机行为、正式签名/公证、两个真实节点之间的单聊/群聊另行验证。本次没有创建发布 tag、合并或提交商店。

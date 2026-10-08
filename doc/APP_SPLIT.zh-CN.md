[English](./APP_SPLIT.md)

# 两个应用的职责

DitMesh 和 MorseCQ 是独立应用，均在准备首次发布。

| 应用 | 产品 | 身份与存储 |
|---|---|---|
| DitMesh | Tox Morse 单聊、群聊；聊天 / 群组 / 参考 / 我的 | 本地 Tox 身份、联系人、加密备份、聊天历史；`icu.agentx.ditmesh` |
| MorseCQ | 无账号离线学习；学习 / 参考 / 我的 | 本地学习进度、设置、录音；`icu.agentx.morsecq` |

两者复用纯 Morse 引擎和电键组件。DitMesh 负责 Tim2Tox 传输；MorseCQ 不依赖聊天传输、Tox 身份或注册。两个应用不会隐式读取对方数据。

DitMesh 的当前加密备份支持身份、聊天组件和恢复预览。`.tox` 文件用于 Tox 身份互通导入，不是完整聊天档案。需要妥善保管备份口令。MorseCQ 的学习数据无账号本地保存。

源码移植自 MorseCQ `3ce9597`；DitMesh Tim2Tox 子模块固定为 `093730ce346cef186bfd3d71214343b38d6c5ca6`。保留 GPL-3.0 与第三方声明。

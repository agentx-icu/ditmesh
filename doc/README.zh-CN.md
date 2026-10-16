[English](./README.md)

# DitMesh 文档

## 使用与运维

- [应用职责](APP_SPLIT.zh-CN.md)——DitMesh 聊天与 MorseCQ 训练器的分工
- [Bootstrap 节点与局域网托管](operations/NETWORK.zh-CN.md)
- [公开站点：隐私、条款、支持](../site/README.zh-CN.md)

## 构建、测试与发布

- [构建、CI 与打包](operations/BUILD_AND_DEPLOY.zh-CN.md)
- [发布与商店要求](release/APP_STORE.zh-CN.md)
- [测试金字塔](testing/TEST_PYRAMID.zh-CN.md)
- [当前持久化清单](testing/PERSISTENCE_AUDIT.zh-CN.md)
- [验证证据与未解决的发现项](VALIDATION.zh-CN.md)
- [维护指南](HANDOVER.zh-CN.md)

## 代码指南

- [应用布局](../apps/ditmesh/README.zh-CN.md)
- [聊天契约](../packages/ditmesh_chat_api/README.zh-CN.md)与 [Tim2Tox 后端](../packages/ditmesh_chat/README.zh-CN.md)
- [原生源码 overlay](../tool/ci/tim2tox-overlays/README.zh-CN.md)与 [Dart overlay](../tool/ci/tim2tox-dart-overlays/README.zh-CN.md)
- 莫尔斯相关包：[核心](../packages/morse_core/README.zh-CN.md)、[音频译码](../packages/morse_dsp/README.zh-CN.md)、[拍发与侧音 I/O](../packages/morse_io/README.zh-CN.md)、[练习逻辑](../packages/morse_trainer/README.zh-CN.md)、[无线电工具](../packages/radio_tools/README.zh-CN.md)
- 应用模块：[通知与后台](../apps/ditmesh/lib/notifications/README.zh-CN.md)、[桌面外壳](../apps/ditmesh/lib/desktop/README.zh-CN.md)、[本地化](../apps/ditmesh/lib/l10n/README.zh-CN.md)
- [添加界面语言](i18n/ADDING_A_LANGUAGE.zh-CN.md)

## 协议

- [已实现的原始拍发节奏协议](rfcs/2026-10-09-keyed-rhythm.zh-CN.md)
- [早期的消息注解提案](rfcs/2026-09-30-tim2tox-message-annotation.zh-CN.md)（已被取代，保留作历史记录）

## 设计与截图

- [产品设计概念](designs/product-2026-10-08/README.zh-CN.md)
- [信号塔图标设计](designs/icon-2026-10-08/README.zh-CN.md)
- [真实界面截图](screenshots/README.zh-CN.md)与[采集流程](../tool/screenshots/README.zh-CN.md)

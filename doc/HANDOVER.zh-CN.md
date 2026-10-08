[English](./HANDOVER.md)

# DitMesh 维护指南

从 [README](../README.zh-CN.md)、[网络指南](operations/NETWORK.zh-CN.md)、[构建指南](operations/BUILD_AND_DEPLOY.zh-CN.md)和[测试金字塔](testing/TEST_PYRAMID.zh-CN.md)开始。已执行的检查见[验证记录](VALIDATION.zh-CN.md)。

修改聊天行为时，覆盖 Morse 输入限制、单聊和群聊投递、加密备份恢复及离线队列。网络测试覆盖保存的节点选择、节点探测、局域网托管、重连和资源释放。外观检查覆盖十种语言、五种风格及手机和桌面布局。

设备测试检查触摸与键盘键控、侧音、触觉反馈、二维码扫描、通知跳转和后台恢复。使用不同网络的节点检查 NAT 连接。安装包和商店配置见[发布指南](release/APP_STORE.zh-CN.md)。

提交改动前运行严格分析、包和应用测试及源码守卫。原生传输补丁通过[源码 overlay](../tool/ci/tim2tox-overlays/README.md)应用。

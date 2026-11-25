# 首次通联体验验证 — 2026-11-25

[English](FIRST_CONTACT_ACTIVATION_2026_11_25.md)

基线为 DitMesh master `0365267902`，Tim2Tox `1b1d51bcc7241ee117fd3ad7241799c44ea8ba26`。既有引导/自聊用例 19 项通过；两个新增联系人入口测试在实现前因缺少入口失败。隔离工作区依赖已引导，并按提交的 lockfile 解析。

实现：实际存在一条自聊消息后，显示有高度限制、可滚动的下一步卡片，打开既有联系人。用户明确选择好友后进入真实的只读电码编辑器，不预填草稿或自动发送。引导增加 CQ/回复、原始节奏和排队/发送/送达含义，覆盖十种语言。既有编辑器布局提取为 `ConversationComposer`，保留草稿恢复和逐会话 key，并维持 500 行门禁。

本轮实际检查：

- `flutter test --no-pub test/chat/first_chat_guide_test.dart test/chat/self_conversation_test.dart test/chat/message_input_draft_test.dart test/chat/message_input_send_draft_test.dart test/chat/shared_draft_commit_test.dart test/chat/message_input_persistence_test.dart test/chat/contacts_page_test.dart test/chat/message_playback_panel_test.dart --reporter compact`：67 项通过。覆盖手机/桌面选择好友、无自动发送、草稿持久化、原始时序控制及 320×568、3 倍字体。
- `flutter analyze --no-pub`：无问题。
- 复杂度、导入和 UI 字面量三项门禁通过。
- `flutter gen-l10n`：十种语言已生成，没有新增缺失翻译。

跨平台检查：共享 widget 已验证布局/字体缩放及原生可访问按钮，五平台共用本次 Dart 路径。未改变协议、权限、后台模式或原生插件。实体手机键盘/触控、跨 NAT/蜂窝、锁屏接收和同签名渠道升级仍需设备/渠道证据。三对搭档任务和空白本地记录见 `FIRST_CONTACT_TRIAL.zh-CN.md`，未声称或联系真实参与者。

另行使用同 revision 的既有 macOS 原生库运行双端测试；只有记录真实结果与制品身份后才算该项完成。该测试不能证明物理设备或公网表现。

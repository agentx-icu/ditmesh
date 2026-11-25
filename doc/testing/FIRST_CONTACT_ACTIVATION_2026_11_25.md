# First-contact activation verification — 2026-11-25

[简体中文](FIRST_CONTACT_ACTIVATION_2026_11_25.zh-CN.md)

Baseline: DitMesh master `0365267902` with Tim2Tox `1b1d51bcc7241ee117fd3ad7241799c44ea8ba26`. Existing first-guide/self-conversation suite passed 19 tests; the two new next-contact tests failed before the CTA existed. Dependencies were bootstrapped in the isolated worktree and resolved with the committed lockfile.

Implemented: after an actual self message, a bounded, scrollable card opens existing Contacts. An explicitly selected friend opens the real read-only keyed composer without prefilled text or an automatic send. The existing guide now describes CQ/reply, original rhythm and queued/sent/delivered semantics in all ten locales. The existing composer presentation was extracted into `ConversationComposer` to retain the 500-line ceiling; draft restoration and per-conversation keys remain unchanged.

Fresh checks:

- `flutter test --no-pub test/chat/first_chat_guide_test.dart test/chat/self_conversation_test.dart test/chat/message_input_draft_test.dart test/chat/message_input_send_draft_test.dart test/chat/shared_draft_commit_test.dart test/chat/message_input_persistence_test.dart test/chat/contacts_page_test.dart test/chat/message_playback_panel_test.dart --reporter compact`: 67 passed. Covers phone/desktop friend selection, no automatic send, draft durability, original timing controls and 320×568 at 3× text.
- `flutter analyze --no-pub`: no issues.
- `dart run tool/check_complexity.dart`, `dart run tool/import_guard.dart`, `dart run tool/ui_literal_guard.dart`: passed.
- `flutter gen-l10n`: regenerated all ten locales; no missing translations added.

Cross-platform checklist: layout/text scaling and accessible native buttons verified by shared-widget regression; Android/iOS/macOS/Linux/Windows share the same Dart path. No protocol, permissions, background mode or native plugin changed. Physical phone keyboard/touch, cross-NAT/cellular, locked-phone reception and signed upgrade remain needs-device/channel. Three-pair trial tasks and blank local observation records are in `FIRST_CONTACT_TRIAL.md`; no participants have been claimed or contacted.

Native two-peer validation is being run separately using the existing same-revision macOS library. Its actual result and artifact identity must be recorded before treating it as completed evidence. It does not prove physical-device or public-network behavior.

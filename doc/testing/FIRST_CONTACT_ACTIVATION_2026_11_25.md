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

Native two-peer check completed with exit 0: `python3 packages/ditmesh_chat/test/helpers/run_real_peers.py --library /Users/bin.gao/.codex/worktrees/ditmesh-full-audit/ditmesh/build/native/macos-arm64/libtim2tox_ffi.dylib --timeout 780`. It verified real DM, repeated original rhythms, NGC delivery, encrypted identity restart, durable queued delivery, rejoin during online/DHT loss/away recovery and refused-join slot safety. Both independent workers completed and exited successfully. Retained evidence: `/var/folders/cz/1y3n3_k12g5d1jmk7m425kr00000gn/T/ditmesh_real_peers_56gp1v6c`. FFI SHA-256: `9599f8666cbefa14651a26ed436fcbea543bd05d2998ae126a29a9a560731891`. This reused a previously built library from the checkout at the same Tim2Tox revision, rather than rebuilding it in this worktree. It uses localhost native UDP, not physical devices or a public cross-NAT network.

Independent Codex review reproduced a narrow-layout issue: separately reserving24% for guidance plus75% for the composer left only5.12px of history at320×568/3×text. Guidance now shares the existing bounded composer scroll surface and history retains its prior25% allocation. The regression failed before the fix and now checks a usable history viewport, actually starts self-message playback, and then reaches Contacts. The final67-test targeted suite and analyzer passed again after this fix.

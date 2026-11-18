# DitMesh Full Code Audit Plan

[简体中文](./2026-11-18-ditmesh-code-audit.zh-CN.md)

**Goal** Review every shipped DitMesh feature from its entry point to the underlying services. Fix confirmed defects, review the resulting changes independently, and merge the PR after its CI passes.

**Baseline** `origin/master` at `5e4cc5c57071c27af784f3acf627f20e2d59089c`, which includes PRs #47 and #48. Use the [previous audit](./2026-11-17-ditmesh-full-audit.md) and `doc/VALIDATION.md` as prior evidence. Record which checks run against this revision.

## 1. Review the product

Use at most two Codex review agents for the entire audit. Both start with a read-only review.

- [x] **Application and user workflows.** Trace `apps/ditmesh/lib/main.dart`, startup, routing and the four primary tabs. Review identity lifecycle, backup and restore UI, contact and QR workflows, chats, groups, history and queues, Morse keying and playback, practice, reference material, location, radio tools, privacy, notifications, appearance, language and desktop controls. Cross-check widget and integration tests.
- [x] **Services and packages.** Trace `packages/ditmesh_chat{,_api}`, the Tim2Tox integration and overlays, connection lifecycle, contact and group state, outbox, receipts, storage, encryption, migrations and restore. Review the app-facing Morse core, DSP, I/O, practice and radio calculations with their package tests.
- [x] **Integration and platform coverage.** The lead reviewer checks the README feature inventory, interactions between the two review areas, Android, iOS/iPadOS, macOS, Linux and Windows hosts, build and packaging scripts, workflows, and public documentation. Use the cross-platform checklist to record platform-specific evidence and hardware-dependent checks.

## 2. Confirm, fix and review

- [x] With Flutter 3.41.9 / Dart 3.11.5, bootstrap from the workspace root using `dart run tool/bootstrap_deps.dart` and `dart pub get --enforce-lockfile`. Run `bash tool/test_pyramid.sh --level <gates|unit|widget>` for each layer and record baseline failures.
- [x] Confirm each finding against the product contract and current code. Record its trigger, impact, source and verification. Add regression coverage where the existing suite misses a confirmed defect, then verify the fix at the nearest normal entry point.
- [x] Reuse the same two agents for independent review of the fixes and tests. Resolve every confirmed finding, retest and review the final diff.
- Run the local gates, package and widget suites, and native or device checks relevant to the fixes. Use `git diff --check` and `git status --short` before publishing. Record unavailable hardware and signing prerequisites where they affect verification.

## 3. Publish and merge

- Create a PR against `master` with confirmed findings, fixes and test evidence. Apply `ci:e2e` for the E2E and visual workflows.
- Verify the checks reported for the reviewed PR head with `gh pr checks` and `gh run view`. Investigate failures, retry transient failures, and review and verify any new commits.
- Merge after CI passes, matching the reviewed head. Confirm the PR is merged and verify the merge commit on remote `master`.

## Findings and regression coverage

| Area | Defect and fix | Evidence |
| --- | --- | --- |
| Async navigation | Group, contact, key profile and node operations now close their own route. Group creation opens its conversation only while the Groups tab remains exposed. Failed key-profile writes preserve the committed bindings. | `chat_sheet_route_test.dart`, `key_setup_page_test.dart`, `key_profiles_test.dart`, `bootstrap_nodes_page_test.dart` |
| Chat history | A hidden message retains its bookmark. Clearing or deleting history refreshes the open timeline, search and pending-message views. Storage failure is surfaced, and unresolved queued sends keep their history and controls. | `message_management_ui_test.dart`, `chat_service_test.dart` |
| Group outbox | A queued group message publishes its status when transport accepts it, including when no delivery receipt arrives. | `group_dht_reconnect_test.dart` |
| Camera | Retrying a failed scanner start replaces the controller. Only the exposed scanner route owns the active camera. | `qr_scan_lifecycle_test.dart` |
| Audio and backup | Stopping live capture finalizes the current mark. Audio-only encrypted backups include the library index, and the preview counts recordings. Practice-only restores can display notes and relink missing recordings. | `listen_controller_test.dart`, `workbench_screen_test.dart`, `encrypted_backup_test.dart` |

Platform coverage includes source review of all shipping hosts and the PR's automated platform matrix. Physical camera permission changes, wired/Bluetooth audio routes, and store signing remain hardware or release-environment checks.

## Change log

- 2026-11-18 — Created the plan using the current default branch and validation matrix. Two Codex reviewers covered the app and services, then cross-reviewed the fixes.

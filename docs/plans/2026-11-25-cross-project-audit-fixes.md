# Cross-project audit fixes implementation plan

**Goal:** Fix the 13 confirmed findings in the 2026-11-25 cross-project audit, independently review all changes, create PRs, wait for their final-head CI, and merge.

**Architecture:** Reuse the already verified fixes from sibling projects, preserving each app's existing contracts. Apply selective DitMesh Dart/native overlays for the two dependency defects; keep unrelated upstream changes out. Bind asynchronous side effects to current policy and their owning routes. Stop destructive recording cleanup based on incomplete indexes. Validate actual Apple binary platforms/minima and Android package versions.

**Stack:** Flutter 3.41.9 / Dart 3.11.5, C++ Tim2Tox, Python artifact validators, GitHub CI.

## 1. DitMesh application and device recovery (F06–F11)
- Modify packages/morse_io/lib/src/widgets/{straight_key_button,paddle_buttons}.dart: track pressed physical keys per action, retain pointer/keyboard semantics. Port and first run sibling multiple-key regressions (red), fix, then run morse_io tests (green).
- Modify apps/ditmesh/lib/ui/listen/workbench/workbench_waveform.dart: capture the opposite drag endpoint at gesture start, keep per-field drafts/dirty state, reject invalid input and preserve exact unchanged frame positions. Port four workbench regressions, observe red, fix, run related workbench suite.
- Modify apps/ditmesh/lib/ui/listen/record_pcm_source.dart: terminate the active recording on system pause and restore audio session once. Add interruption regression, observe red, fix, run capture/listen tests.
- Modify apps/ditmesh/lib/desktop/desktop_shell_controller.dart and necessary adapters: recover hidden windows when tray host vanishes, retry late host registration, and recover from native quit failure without leaving closing latched or the tray unavailable. Port three controller regressions, observe red, fix, run desktop suite.

## 2. DitMesh dependency isolation and delivery (F01–F02)
- Add committed Dart overlay(s) to preserve two distinct same-source same-text inbound messages while still coalescing duplicate delivery across callback sources. Add plain/ACTION/conference polling regressions and duplicate-source controls.
- Add native overlay(s) for friendship session reset at uninit/reinit, including cached applications/unread state and related account-scoped caches. Add a native account A→B isolation test.
- Update overlay series/integrity metadata according to existing bootstrap/build conventions. Do not bump to unrelated upstream functionality. Bootstrap from a clean worktree, run Dart regressions, native tests and overlay integrity checks.

## 3. MorseCQ recording preservation (F03)
- Modify apps/morsecq/lib/ui/listen/workbench/workbench_screen.dart and recording cleanup only as necessary to avoid deleting valid WAVs from a stale/recovered/partly corrupt index.
- Add the two production WorkbenchScreen/disk regressions for recovered backup and a skipped malformed entry. Observe failure before code; fix, run workbench/backup/material persistence tests and gates.

## 4. toxee notification and route ownership (F04–F05)
- Modify lib/notifications/notification_message_listener.dart and notification_service.dart: pass a current-policy predicate through all async preparation and check immediately before publishing. Add mute/block/open-conversation races, including service-level awaits, and preserve session/privacy checks.
- Modify lib/ui/settings/bootstrap_nodes_page.dart: retain the exact dialog/list routes and close only owned routes. Add system-back during delayed node change and covering-route regressions.
- Observe existing audit reproductions fail, integrate durable tests into repo, implement minimum fix, run notification/navigation suites.

## 5. Artifact gates (G01–G02)
- toxee and DitMesh tool/ci/native_payload.py plus shared Apple runtime helpers: validate every iOS Mach-O slice is an iOS device slice and its minimum OS does not exceed the app declaration. Thread explicit iOS context through packaging/archive entrypoints; preserve desktop behavior. Add parser/real-binary controls for simulator, minimum OS, mixed slices, and valid device binaries.
- toxee tool/ci/android_release_preflight.py and packaging/workflow callers: read source version/build and compare APK metadata, including versionName and full versionCode. Add stale-version/build and valid identity tests; preserve signer/native checks.

## Review, validation, delivery
- Implementers self-review. Independent agents review requirements first, then correctness/quality, lifecycle, platform compatibility and regression coverage. Fix every confirmed review issue and re-review.
- Run repository-appropriate gates/static analysis/format, targeted and required complete test suites. Record baseline/environment failures distinctly; investigate rather than hide failures.
- Commit only this task's source/tests/notes. Create one PR per application repo, with final behavior, cross-project provenance and validation. Add the existing full E2E trigger where appropriate.
- Track all final-head CI. Investigate failures, fix real defects, rerun transient infrastructure failures only with evidence. After all applicable checks pass, merge at expected head and verify remote master contains the merge.
- No RTK, no Claude review/tooling. Do not disturb other worktrees or user changes.

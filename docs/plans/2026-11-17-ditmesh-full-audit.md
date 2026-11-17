[简体中文](./2026-11-17-ditmesh-full-audit.zh-CN.md)

# DitMesh Full Code Audit Plan

**Goal** Audit DitMesh across its product features, fix every confirmed finding, review the final changes, and merge the audit PR into `master` after its CI passes.

**Baseline** Review `origin/master` at `0fbc204768c0a5e7a86953ea5088e8e26a7740b7`, including the native integration maintained by this repository. Compare the findings with PR #46, which handles a group reconnect fix and device E2E changes. If it merges first, update the audit branch and recheck the overlapping behavior.

## 1. Initial review

- [x] Assign one reviewer to the Flutter application. Trace startup, DI, lifecycle and navigation through `apps/ditmesh/lib`. Cover identity creation, unlock, passwords, backup/import and deletion. Review direct and group chat, contacts and QR, history, search, bookmarks, unread counts, queued actions, playback and training. Inspect Morse entry and settings, reference and radio tools, location and nearby, privacy, notifications, appearance, localization, responsive layout, shortcuts, windows and tray. Check failure paths and platform differences against app and integration tests.
- [x] Assign the second reviewer to `packages/ditmesh_chat_api/`, `packages/ditmesh_chat/`, and the Tim2Tox overlays. Follow FFI wiring, connections, reconnect, IDs, receipts, retries, deduplication, deletion and restart; include encrypted profiles, backup, group state, bootstrap and LAN. Check encoding, timing, audio, training and calculation boundaries in `packages/morse_{core,dsp,io,trainer}/` and `packages/radio_tools/` against their app entry points.
- [x] Check feature coverage against the README, `doc/VALIDATION.md`, and `doc/testing/`. Review five platform hosts and permissions, distribution scripts, GitHub Actions, dependency overlays, and support-site claims. Record the trigger, impact, source and verification for each confirmed finding.

## 2. Fixes and follow-up review

- [x] Use Flutter 3.41.9 / Dart 3.11.5. Run `dart run tool/bootstrap_deps.dart` and `dart pub get --enforce-lockfile` from the workspace root. Record baseline results for `bash tool/test_pyramid.sh --level <level>` at `gates`, `unit`, and `widget`.
- [x] Verify each finding at the closest normal entry point. Reproduce the problem before changing behavior where practical. Verify the fix, existing behavior, compatibility with persisted data, failure recovery and affected platforms.
- [x] Reuse the same two reviewers for follow-up diff and regression review. Resolve all confirmed findings and recheck cross-module behavior.
- [ ] Run the local gates, unit and widget tests, and any affected native or packaging tests. Run `git diff --check` and inspect `git status --short`. Record device, signing and CI verification limits.

## 3. PR, CI and merge

- [ ] Open a dedicated audit PR against `master`. Include findings, fixes, coverage and test evidence. Use the `ci:e2e` label to run the five-platform E2E suite and the visual matrix.
- [ ] Use `gh pr checks <number>` and `gh run view` to check analysis, layout, native tests, platform builds, E2E and visual jobs for the current head. Diagnose failures, retry recoverable jobs and review any resulting code changes before waiting for CI again.
- [ ] Merge the reviewed head after CI passes. Verify the result with `gh pr view <number> --json state,mergeCommit,mergedAt` and remote `master`.


## Audit log

- On 2026-11-17, two independent Codex reviewers conducted the initial review. The main agent checked product entry points, Android and Apple permissions, the five platform hosts, packaging and release tools, workflow triggers, and the public support pages.
- The audit branch fast-forwarded to `4036f61b0a803011aac4c76d7198bbc8a52b23ff` after PR #46 merged. Native verification uses the resulting group reconnect overlay.
- The fixes cover account navigation and backup, shared drafts, hidden conversations, location and notification permission, scanner callbacks, the WAV workbench and playback, and radio calculations. Hardware permission prompts, physical audio and camera behavior, and store signing require device or distribution verification.

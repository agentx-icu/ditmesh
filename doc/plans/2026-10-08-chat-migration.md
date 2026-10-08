# DitMesh / MorseCQ split implementation plan

**Goal:** Move the complete Morse-only Tox chat experience into DitMesh and ship MorseCQ as an account-free offline trainer.

**Architecture:** Preserve the existing pure Dart Morse engine, Flutter keying layer, chat API and Tim2Tox adapter. DitMesh owns identities, contacts, direct/group conversations, moderation, backups and notifications. MorseCQ owns local learning data and has no chat transport or identity service dependency. Both apps have independent application identifiers and storage.

**Tech stack:** Flutter 3.41.9, Dart 3.11.5, Material 3, c-toxcore/Tim2Tox, CMake, platform runners and GitHub Actions.

## Approved design

The user approved the independent-app design on 2026-10-08. DitMesh exposes Chat / Groups / Reference / Me. Straight key and iambic paddles work through touch and physical keyboard; the decoded draft stays read-only. Preserve the v1 plain-text Tox wire format for interoperability. Preserve chat-assisted practice where needed by the migrated conversation features. MorseCQ exposes Learn / Reference / Me and includes the existing offline training, DSP, reference and radio tools.

Use `icu.agentx.ditmesh` for DitMesh and use `icu.agentx.morsecq` for MorseCQ. Keep independent application data. On 2026-10-08 the user clarified that neither application has been released; historical-version compatibility and old-data migration are unnecessary and removed from the implementation scope. MorseCQ uses a clean local learning profile without Tox.

Platform support is Android, iOS, macOS, Linux and Windows. iOS release packages can be unsigned; Apple signing/notarization and Android store signing require owner credentials. CI must distinguish required targets from experimental architectures. Tags produce a draft GitHub Release with checksums after required builds and tests pass.

## Workspaces and ownership

- DitMesh: `/Users/bin.gao/chat-uikit/ditmesh`, branch `codex/chat-migration`.
- MorseCQ: `/Users/bin.gao/chat-uikit/morsecq/.worktrees/offline-learning`, branch `codex/offline-learning`.
- Preserve the source checkout's untracked pedagogy review documents and the unrelated pedagogy worktree.
- No RTK and no Claude tools or reviews. Use local checks and independent Codex agent reviews.

## Task 1 — Baseline and reproducible import

1. Record source revision `3ce9597` and Tim2Tox pin `093730ce346cef186bfd3d71214343b38d6c5ca6`.
2. Run existing package/app tests as baseline; capture failures before changing behaviour.
3. Import tracked source only, excluding generated/build state and obsolete product documentation/screenshots.
4. Rename the app, chat packages, product labels, platform identifiers, test imports and script paths to DitMesh.
5. Register the pinned Tim2Tox submodule and preserve the documented SDK overlays; never edit upstream submodule source in place.
6. Bootstrap and resolve once at the workspace root, then run analyzer and package tests.

## Task 2 — MorseCQ offline trainer (isolated implementation agent)

Files: root workspace/pubspec and `apps/morsecq/{lib,test,integration_test}`, platform runners, `tool/`, `.github/`, docs/site.

1. Add a regression showing first launch enters learning without registration and no chat destination exists; verify the old app fails that expectation.
2. Replace backend/identity startup with a local learning scope, preferences, training-controller host and lifecycle persistence.
3. Remove chat/identity API and transport packages, submodule registration, Tencent overlays, FFI build scripts, account/contact/group/chat/notification UI and obsolete tests.
4. Adapt learning, DSP recording paths, preference persistence and desktop services to local storage; use a local learning data directory.
5. Persist current local learning progress, settings and recordings without any account/password/native library or legacy import flow.
6. Remove native linking/pods/Android dependencies and unnecessary permissions; keep microphone access for DSP features.
7. Update source guards, integration walks and screenshots to the offline scenes.
8. Update bilingual product/build/privacy/support documentation and design references. Run analyzer, gates, relevant regressions and full remaining tests.

## Task 3 — DitMesh chat app (app implementation agent)

Files: `apps/ditmesh/{lib,test,integration_test,test_driver}`, `packages/ditmesh_chat*`, shared Morse packages if necessary. Platform/build tooling has separate ownership.

1. Run migrated tests and add a regression that initial navigation is Chat and composer remains read-only for both direct and group targets.
2. Make identity startup and Chat / Groups / Reference / Me the default product experience; remove guest-first learning onboarding.
3. Preserve complete contacts, requests, QR, groups/invites/members, history/search/bookmarks, outbox retries/cancel, blocking, backup/restore, notifications and desktop routing.
4. Keep chat-assisted Morse practice and key profiles intact; hide unrelated standalone training destinations.
5. Ensure native backend preparation failure is visibly reported and never silently substitutes a demo backend in production.
6. Audit independent data paths and current DitMesh backup identification/restore. No MorseCQ legacy backup compatibility is required.
7. Adapt launch/integration scenes and assertions for the migrated product. Run analyzer, guards, package/app tests and native smoke tests.

## Task 4 — Build, packaging and CI (build implementation agent)

Files: DitMesh platform runners, `tool/{ci,build_*,bootstrap_deps.dart,import_guard.dart,ui_literal_guard.dart}`, `.github/workflows/`, `build_all.sh`, pubspec/platform metadata.

1. Audit renamed package, bundle, channel, notification and installer identifiers; retain native Tim2Tox ABI names.
2. Make native and app jobs cover all required platforms, including Dart/UI source and dependency changes in triggers.
3. Gate tagged release publishing on analysis and unit tests as well as successful required app builds.
4. Build Linux packages, Windows installer/archive, macOS installer/archive, Android APK/AAB and unsigned iOS IPA; fail when required libraries are missing.
5. Produce deterministic asset names/version metadata and SHA256SUMS. Create draft Releases, preserve minimum token permissions and document unsigned packages.
6. Validate workflow syntax with actionlint, script syntax with shell tooling, host macOS native release build/package and iOS simulator/device build where possible.
7. Add documented manual steps for signing secrets, physical-device checks and experimental Linux/Windows ARM targets.

## Task 5 — Documentation, screenshots and review (coordinator)

1. Rewrite DitMesh English/Chinese README, application responsibility/build/release docs and public privacy/terms/support pages.
2. Update MorseCQ docs after implementation; mark old plans historical and point current product decisions to the split plan.
3. Capture real app screenshots in English and Chinese on macOS and available iOS/iPad simulators; use CI for unavailable hosts and never relabel old screenshots as current.
4. Update product design diagrams to match navigation and responsibilities; regenerate raster concepts with imagegen if used.
5. Review both diffs for spec compliance, correctness, lifecycle persistence, mobile parity and native ownership. Fix findings.
6. Run final analyzer, layering/localization/complexity guards, full applicable tests, snapshot verification and build checks. Record exact results and remaining external blockers.
7. Commit reviewable changes on the two branches. Publish draft PRs only if needed for CI execution, attach created PRs to the task, and leave merging/tagging/signing to explicit authorization.

## Additional backlog included

- Independent storage, backup metadata and product identifiers.
- Production-native startup error visibility instead of silent fake-chat fallback.
- Current local learning lifecycle durability without account-scoped storage.
- Required test gates before Release assets can publish.
- Current screenshot scene validation and bilingual documentation links.
- Least-required native dependencies and platform permissions in the offline trainer.

## Validation limits

Real network conversations require two reachable Tox peers. Physical-device latency/haptics, signed store submission, Apple notarization and Windows/Linux local execution depend on devices or credentials unavailable on this Mac. CI execution and package inspection can validate remote target builds; report pending runs accurately.

## Change log

- 2026-10-08: Created after user approval; records migration boundaries, independent storage, worktree ownership, release gates and local/remote verification.

- 2026-10-08 user clarification: both applications are unreleased. Remove legacy learning/ZIP import and MorseCQ backup compatibility; simplify implementation and first-release documentation.

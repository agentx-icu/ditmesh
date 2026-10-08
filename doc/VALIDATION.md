[简体中文](./VALIDATION.zh-CN.md)

# Verification record — 2026-10-08

Implementation is on `codex/chat-migration`. Both applications are unreleased; historical compatibility and migration were removed from scope by the user. The final remote platform run follows the native fixes below; these are executed results, with earlier build evidence identified explicitly.

| Check | Executed result |
|---|---|
| Source MorseCQ baseline | Seven package suites passed; app 1253 passed, 1 skipped |
| DitMesh application | Earlier full run: 1259 passed, 1 skipped; one historical regression was subsequently deleted; final full run is required in CI |
| Chat / API packages | Final chat 236 passed, 4 skipped / API 79 passed; backup/container/Tox checks 39 passed + peer-harness skip, default Chat/identity checks 33 passed; all seven numeric-node/selection tests passed |
| Native integration | Four needs-native suites passed: encryption/rekey, encrypted backups/tamper, persistence and identity/network/offline queue/group smoke |
| Strict analyzer and source guards | Scoped analyzer and all three guards passed; supplemental chat analyzer passed after historical-feature removal |
| Workflow and packaging checks | actionlint 1.7.12, ShellCheck 0.11, Bash/Podfile syntax and six packaging/overlay regressions passed; actionlint also passed with runner ShellCheck 0.10 |
| Screenshot import safety | 12 regressions passed with private PNG fixtures |
| Native platform libraries | Fresh hook-free macOS ARM64, Android arm64/armv7/x86_64, iOS device + ARM64/x86_64 simulator libraries built |
| Initial macOS ARM64 package | Real-backend release app, PKG and ZIP passed before the final native fixes; bundle signature, installation location and no-relocation metadata checked |
| Initial Android package | Real-backend release APK/AAB passed before the final native fixes; all three ABI libraries and runtime libraries verified; local packages use debug signing |
| Initial iOS package | Real-backend unsigned release app/IPA passed before the final native fixes; bundle identity, version and native privacy manifest verified |
| Real product screenshots | macOS, iPhone, iPad, Android, Linux and Windows: 12 scenes × English/Chinese each passed (144 frames) |
| Real peer transport | Two real Tox processes passed bidirectional DM/NGC, encrypted profile/preferences restart, durable queued DM delivered exactly once, automatic group rejoin and post-restart bidirectional group messages; self/remote presence was online before delivery and offline or removed after disconnect |
| Native source fixes | Group persistence and member connection reporting are applied to a copied pinned source tree; upstream submodules remain clean, and all 366 public FFI exports are unchanged; the old library failed the positive presence regression and the corrected library passed |
| Fresh public startup | Optional public DHT probe passed in 10 seconds with the numeric defaults; deterministic required CI uses local real peers |
| Desktop E2E CI | [macOS/Linux/Windows UI and screenshot run passed](https://github.com/agentx-icu/ditmesh/actions/runs/37719469365) |
| Remote CI | [Draft PR #1](https://github.com/agentx-icu/ditmesh/pull/1) runs Native/Analyze/E2E; all six native targets and Linux/Windows/Android/iOS application packages passed in the first run; the analysis shell gate was corrected and required network CI now uses two real local UDP peers; final run pending |

Source revision: MorseCQ `3ce9597`. Tim2Tox pin: `093730ce346cef186bfd3d71214343b38d6c5ca6`. Host: Apple Silicon macOS with Xcode 26.4.1, Flutter 3.41.9 and Dart 3.11.5. Source and final app logs are local temporary evidence at `/tmp/ditmesh-source-baseline.log` and `/tmp/ditmesh-chat-final-full-tests.log`.

Initial local packages (before the final persistence/bootstrap fixes) in ignored `dist/`: macOS PKG 25,876,884 bytes, ZIP 26,109,945 bytes; Android APK 107,613,474 bytes, AAB 73,469,570 bytes; iOS unsigned IPA 12,820,577 bytes. The release verifier requires all twelve platform assets plus SHA256SUMS before updating a draft GitHub Release.

Native source downloads use pinned hashes. Direct per-command GitHub access was used when inherited proxy variables failed; global proxy settings were preserved. Fixes include independent installer identifiers, atomic native downloads/error propagation and root-application macOS installer relocation metadata.

Physical-device behavior and signed distribution/notarization remain separate checks. No release tag, merge or store submission has been performed.

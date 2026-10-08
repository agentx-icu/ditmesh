[简体中文](./VALIDATION.zh-CN.md)

# Verification record — 2026-10-08

Implementation is on `codex/chat-migration`. Both applications are unreleased; historical compatibility and migration were removed from scope by the user. The complete split baseline at `2317f6d` passed remote analysis, desktop E2E and all required native/application build jobs. The added full bootstrap/LAN port, appearance capture support and selected icon C passed local verification; current product captures and the next remote run follow below as they complete.

| Check | Executed result |
|---|---|
| Source MorseCQ baseline | Seven package suites passed; app 1253 passed, 1 skipped |
| DitMesh application | Current full local suite: 1344 passed, 2 opt-in visual exporters skipped; 41 existing onboarding/startup/network tests passed again after the Welcome icon changed |
| Chat / API packages | Current ordinary suites: chat 269 passed / API 79 passed; native cases are counted separately below |
| Native integration | Current tagged suite: 11 passed, 1 separate peer-worker skipped; original encryption/rekey, encrypted backups/tamper, persistence and identity/network/offline queue/group cases included |
| Strict analyzer and source guards | Scoped analyzer and all three guards passed; supplemental chat analyzer passed after historical-feature removal |
| Workflow and packaging checks | actionlint 1.7.12, ShellCheck 0.11, Bash/Podfile syntax and eight packaging/overlay/cache regressions passed; actionlint also passed with runner ShellCheck 0.10 |
| Screenshot import safety | 19 regressions passed with private PNG fixtures, including mandatory network scene and locale/style/theme boundaries |
| Native platform libraries | Fresh hook-free macOS ARM64, Android arm64/armv7/x86_64, iOS device + ARM64/x86_64 simulator libraries built |
| Initial macOS ARM64 package | Real-backend release app, PKG and ZIP passed before the final native fixes; bundle signature, installation location and no-relocation metadata checked |
| Initial Android package | Real-backend release APK/AAB passed before the final native fixes; all three ABI libraries and runtime libraries verified; local packages use debug signing |
| Initial iOS package | Real-backend unsigned release app/IPA passed before the final native fixes; bundle identity, version and native privacy manifest verified |
| Real product screenshots | Current macOS, iPhone, iPad and Android: 13 scenes × English/Chinese each passed (104 frames), including Welcome C branding and network settings; Swift/Kotlin compiled. Linux/Windows retain 48 preceding frames until the current CI import. |
| Real peer transport | Two real Tox processes passed bidirectional DM/NGC, encrypted profile/preferences restart, durable queued DM delivered exactly once, automatic group rejoin and post-restart bidirectional group messages; self/remote presence was online before delivery and offline or removed after disconnect |
| Native source fixes | Group persistence, member connection reporting and private-probe isolation are applied to a copied pinned source tree; upstream stays clean. New macOS ARM64 library retains all 366 public FFI exports (all 724 defined names unchanged), contains no test hooks/ToxAV, and preserves ordinary LAN port behavior. Positive presence and probe-isolation regressions failed before their fixes and passed afterwards. |
| Fresh public startup | Current optional public DHT startup passed in 10 seconds with numeric defaults and the rebuilt library; deterministic required CI uses local real peers |
| Analysis, guards and all package/app tests | [Analysis passed](https://github.com/agentx-icu/ditmesh/actions/runs/37724455049), split baseline `2317f6d` |
| Desktop E2E CI | [macOS/Linux/Windows UI and screenshots passed](https://github.com/agentx-icu/ditmesh/actions/runs/37724455062), split baseline `2317f6d` |
| Required platform CI | [All 13 jobs passed](https://github.com/agentx-icu/ditmesh/actions/runs/37724455301): six native targets, six application jobs and quality; all three real-peer gates passed. Release publication correctly skipped on [draft PR #1](https://github.com/agentx-icu/ditmesh/pull/1). |
| Selected icon C | 57 platform/tray resources generated from one SVG coverage source; icon tools analyzed clean; 51 platform PNGs checked for dimensions/channel type, two ICO containers checked for complete size tables |
| Local appearance follow-up | Four screenshot parser/apply tests plus 40 functional Morse DM/group style tests passed; ten locales and five styles rendered with real fonts: 38 profiles / 76 PNGs; 19 screenshot-import regressions passed |
| Local native bootstrap follow-up | Tagged native suite: 11 passed, 1 separate peer-worker skipped. Seven new tests prove actual LAN sockets and two clients online, preserved instances, startup/probe cancellation, real local response with wrong-key negative, and no child connection broadcasts or live chat-state changes. Copied-source private-probe overlay keeps the signed creator ABI and all 366 public exports; eight packaging/overlay regressions passed. |
| Apple LAN permissions and node pages | Required-purpose regression failed for both Apple platforms before the fix; 13 native-locale checks and 27 node widget tests passed after adding all twenty localized purpose entries. All 22 plist/string files passed plutil. Auto/Manual saved-node tests, large-text/RTL flows, rollback retries and blocked-start disposal are covered. |

Source revision: MorseCQ `3ce9597`. Tim2Tox pin: `093730ce346cef186bfd3d71214343b38d6c5ca6`. Host: Apple Silicon macOS with Xcode 26.4.1, Flutter 3.41.9 and Dart 3.11.5. Current logs are temporary local evidence at `/tmp/ditmesh-bootstrap-final-suite-app.log`, `/tmp/ditmesh-bootstrap-native-complete-final.log`, `/tmp/ditmesh-bootstrap-public-final.log` and `/tmp/ditmesh-bootstrap-real-peers-final.log`. The final real-peer workers each passed in 27 seconds.

All twelve split-baseline `2317f6d` packages were downloaded from that exact CI run into ignored `dist/release-v1.0.0`. The asset verifier and independent SHA-256 checks passed; `dist/final-build-evidence.json` binds them to the remote source SHA and explicitly marks them as preceding the new bootstrap/appearance/icon work. The release verifier requires all twelve platform assets plus SHA256SUMS before updating a draft GitHub Release.

Native source downloads use pinned hashes. Direct per-command GitHub access was used when inherited proxy variables failed; global proxy settings were preserved. Fixes include independent installer identifiers, atomic native downloads/error propagation and root-application macOS installer relocation metadata.

Physical-device behavior and signed distribution/notarization remain separate checks. No release tag, merge or store submission has been performed.

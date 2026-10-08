[简体中文](./VALIDATION.zh-CN.md)

# Verification record — 2026-10-08

Implementation is on `codex/chat-migration`. Remote platform validation is the next gate; the following are executed local results.

| Check | Executed result |
|---|---|
| Source MorseCQ baseline | Seven package suites passed; app 1253 passed, 1 skipped |
| DitMesh application | 1259 passed, 1 skipped |
| Chat / API packages | 230 passed, 3 needs-native skips / 79 passed |
| Native integration | Four needs-native suites passed: encryption/rekey, encrypted backups/tamper, persistence and identity/network/offline queue/group smoke |
| Strict analyzer and source guards | Scoped analyzer and all three guards passed |
| Workflow and packaging checks | actionlint 1.7.12, ShellCheck 0.11, Bash/Podfile syntax and five packaging regressions passed |
| Screenshot import safety | 12 regressions passed with private PNG fixtures |
| Native platform libraries | Fresh hook-free macOS ARM64, Android arm64/armv7/x86_64, iOS device + ARM64/x86_64 simulator libraries built |
| macOS ARM64 | Real-backend release app, PKG and ZIP passed; bundle signature verification passed; installation location and no-relocation metadata checked |
| Android | Real-backend release APK/AAB passed; all three ABI libraries and runtime libraries verified; local packages use debug signing |
| iOS | Real-backend unsigned release app/IPA passed; bundle identity, version and native privacy manifest verified |
| Real product screenshots | macOS and iPhone: 12 scenes × English/Chinese passed; iPad/Android capture in progress |
| Remote CI | Awaiting draft PR creation; Linux, Windows and macOS Intel have no completed local build claim |

Source revision: MorseCQ `3ce9597`. Tim2Tox pin: `093730ce346cef186bfd3d71214343b38d6c5ca6`. Host: Apple Silicon macOS with Xcode 26.4.1, Flutter 3.41.9 and Dart 3.11.5. Source and final app logs are local temporary evidence at `/tmp/ditmesh-source-baseline.log` and `/tmp/ditmesh-chat-final-full-tests.log`.

Local packages in ignored `dist/`: macOS PKG 25,876,884 bytes, ZIP 26,109,945 bytes; Android APK 107,613,474 bytes, AAB 73,469,570 bytes; iOS unsigned IPA 12,820,577 bytes. The release verifier requires all twelve platform assets plus SHA256SUMS before updating a draft GitHub Release.

Native source downloads use pinned hashes. Direct per-command GitHub access was used when inherited proxy variables failed; global proxy settings were preserved. Fixes include independent installer identifiers, atomic native downloads/error propagation and root-application macOS installer relocation metadata.

Physical-device behavior, signed distribution/notarization and real two-peer direct/group delivery remain separate checks. No release tag, merge or store submission has been performed.

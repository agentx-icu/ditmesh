# Contributor guidance

DitMesh is the Morse-only Tox chat application split from MorseCQ. Current application responsibilities are documented in `doc/APP_SPLIT.md`. MorseCQ is now the separate offline trainer.

- Product name DitMesh; application identifier `icu.agentx.ditmesh`; independent `ditmesh` storage. Do not implicitly read MorseCQ identities or data.
- Main navigation: Chat / Groups / Reference / Me on Android, iOS, macOS, Linux and Windows. Every platform includes chat; there is no offline-only DitMesh distribution.
- Morse chat is keyed by touch or physical keyboard, straight key or iambic paddles; compose draft remains read-only.
- Only `packages/ditmesh_chat` imports Tim2Tox/Tencent compatibility code. Do not edit upstream submodule files in place.
- Production backend failures must surface clearly. Fakes require `DITMESH_FAKE_BACKEND=true` and exist for tests/demos.
- Flutter 3.41.9 / Dart 3.11.5; bootstrap before root `dart pub get`; no subpackage dependency resolution.
- Analyzer has zero issues, including infos. Keep the 500-line baseline empty; run complexity, import and UI-literal guards. UI prose goes in all ARB locales.
- New behavior needs useful regression tests; verify mobile and desktop parity. Preserve stream/timer teardown and durable outbox/backup ownership semantics.
- Documents are English + zh-CN pairs. Append change logs to plan edits. Screenshots come from the integration capture pipeline, never hand-edited PNGs.
- Never commit build outputs, caches, native binaries, signing keys or generated registrants.
- User policy: no RTK. Independent Codex agent review plus appropriate local verification is required.

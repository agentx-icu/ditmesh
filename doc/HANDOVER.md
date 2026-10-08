[简体中文](./HANDOVER.zh-CN.md)

# DitMesh handover

The complete Tox Morse chat was migrated from MorseCQ; the offline-learning split is implemented in MorseCQ's `codex/offline-learning` worktree. The approved scope is [the split plan](plans/2026-10-08-chat-migration.md). Exact executed checks belong in [VALIDATION.md](VALIDATION.md), not inherited claims from the old application.

## Included follow-up work

Independent product/storage/installer identifiers; explicit production backend failure; compatibility with source encrypted chat backups; preserving MorseCQ local learning files; five-platform build/packaging definitions; test gates before draft Release publication; current bilingual documentation, concept boards and real screenshot scenes.

## Remaining external checks

- Apple distribution certificate/provisioning/team, iOS signed IPA/store upload, macOS Developer ID signing and notarization.
- Android release/upload keystore and store account. Keep all credentials out of Git.
- Physical-device sidetone latency, silent-switch playback, haptics, camera QR, notification tap routing, microphone decoding and background limits.
- Real direct/group conversations between two reachable Tox peers, offline-to-online queue delivery and restart/rejoin.
- Run and inspect Linux/Windows release artifacts on their respective hosts; experimental native ARM architectures do not count as required platform coverage.
- Network keyed-timing annotations and live keying remain future upstream work; v1 intentionally interoperates using text.

Creating a release tag, publishing a draft, merging branches and uploading store submissions are separate owner actions. CI workflow configuration is not evidence that a remote run has passed; consult the validation record for actual run links/results.

## Development policy

No RTK and no Claude reviews. Run strict analyzer, package/app tests and all three source guards. Keep Morse-only input and mobile/desktop parity. Keep lifecycle durability and identity/backup ownership tests. Do not edit upstream submodule source in place or commit generated build/signing files.

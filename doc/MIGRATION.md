[简体中文](./MIGRATION.zh-CN.md)

# Moving chat from MorseCQ to DitMesh

MorseCQ is the offline learning app. DitMesh is the Morse-only Tox chat app. Their application identifiers and support directories are different. Neither app automatically opens the other's account.

## Existing MorseCQ chat users

1. Before upgrading MorseCQ to the offline version, open the existing app and export an encrypted backup from Me. Include identity, contacts/groups, chat history, drafts/bookmarks and unsent messages as needed. Keep the file and passphrase safe.
2. Install DitMesh. On its welcome screen, choose restore and select that backup. The old MorseCQ backup envelope/manifest is accepted deliberately; new DitMesh exports identify themselves as DitMesh backups.
3. Review the components and restore report. Unsent messages are restored for review, not automatically transmitted. Connect and verify contacts and groups before resuming conversations.
4. Keep the original backup and MorseCQ files until both chat and learning data have been checked. Importing into DitMesh does not remove the source application or its files.
5. Upgrade MorseCQ to the offline trainer. Existing local guest learning storage remains in place. Use its explicit legacy learning import to copy older identity-scoped learning files when needed.

A legacy `.tox` profile restores identity material, not an entire history/materials/preferences archive. A Tox ID alone is public contact information and cannot restore the private identity. DitMesh cannot recover a lost backup passphrase.

## Learning data

MorseCQ retains the existing `<support>/morsecq/guest/` local profile. Identity-scoped learning files from old installations remain on disk; the offline app can import learning files explicitly without connecting to Tox or loading a private profile. It validates and copies learning data rather than deleting the source. Existing target data must not be overwritten without an explicit user choice.

OS application-support directories differ by platform. Use the system file picker/export tools rather than assuming one desktop path applies to a phone. Imported recordings must stay together with their relative references.

## Protocol and privacy

DitMesh keeps the existing Tim2Tox v1 text-message wire protocol. Local app naming does not change peer identities or group IDs inside a restored profile. Chat uses Tox networking; learning in MorseCQ needs no chat network. See [privacy](../site/privacy.md).

## Source provenance

Chat was imported from `agentx-icu/morsecq` revision `3ce9597`; the Tim2Tox git submodule remains pinned to `093730ce346cef186bfd3d71214343b38d6c5ca6`. GPL-3.0 and original engine third-party notices are retained.

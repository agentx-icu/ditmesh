[简体中文](./2026-10-09-keyed-rhythm.zh-CN.md)

# Original keyed rhythm — implementation contract

This implementation supersedes the earlier proposed annotation RFC for DitMesh. The pinned Tim2Tox revision is `093730ce346cef186bfd3d71214343b38d6c5ca6`; bootstrap generates a separate Dart package with reviewed patches under `tool/ci/tim2tox-dart-overlays`. It does not edit the upstream submodule.

## Recording and storage

`KeyedRecording` is a version-1 array of positive millisecond durations, alternating mark and gap, beginning and ending with a mark. The array has an odd length, at most 511 spans and at most 120 seconds total. Invalid or unsupported recordings are discarded while the message text remains usable.

The composer captures key transitions before the local sidetone gate and associates them with decoded tokens in the shared live draft. Deletion removes the corresponding token's spans; the gap between surviving tokens keeps its actual elapsed time. Capture itself is bounded. Unrecorded/restored text, incompatible clocks or an exceeded bound makes original replay unavailable until the draft is cleared. This is timing metadata rather than an audio-file recording.

`ChatMessage.recording` and `ChatService.sendText(recording:)` expose it without leaking transport types into the app. Local history, the authoritative outgoing queue and encrypted backups store it in the message metadata. Restored pending items carry the optional recording. Delivery status remains independent of recording availability.

Late timing events set the local `ChatMessage.isUpdate` annotation. Notifications and automatic playback ignore them as arrivals; a visible or parked bubble updates in place without adding to the new-message count. The annotation is not sent on the wire or retained in backups.

The player derives word positions from the Morse tokens and uses original durations only when its complete mark/gap topology matches. Otherwise it displays original timing as unavailable and uses listener timing. Each accepted original span replaces the corresponding generated duration without normalization. A late recording updates an open player panel but does not restart the current clip; an explicit replay uses the updated recording.

## Direct messages

Standard native C2C text has no sender-generated identity exposed to the Dart receiver. Matching timing by text, ordering or a nearby timestamp would mix identical messages. Compatible peers instead negotiate a session-bound extension and transmit one envelope containing text, a random message identity, content kind and optional recording. It materializes one ordinary message under the `dmr:` identity, persists before acknowledging and deduplicates by that identity across restart. Distinct identities preserve repeated identical text.

When capability negotiation is unavailable, the existing ordinary text send path remains usable. Original replay is available only when recording was received. An acknowledged recorded envelope sets the existing message's delivery confirmation; the authenticated sender and the current author session must match.

Duplicates must also cross the history durability barrier before acknowledgement; a cache hit does not prove a successful write. Failed arrivals keep an unpublished marker and publish once after storage recovers. At most 128 are retained; capacity rejects new receives before append. History session/clear tokens and a local account generation prevent stale work from publishing or acknowledging across identity changes.

An authenticated capability hello advertises the sender's current session. Receiving a fresh hello refreshes that peer's session even when a short outage was not observed locally; older challenge acknowledgements cannot roll it back. Older version-1 hellos without a session remain compatible through challenge/acknowledgement negotiation. A send awaiting negotiation rechecks its local session after the wait: logout cancels an online send and leaves an offline queued item durable.

## Native group chats

NGC always sends its existing ordinary text. Optional recording is associated with the group chat ID, authenticated sender public key and native message ID (`gmid`). Metadata is sent privately to current online group members using the existing group receipt channel. It may arrive before or after the text; attachment updates that text's existing row. A group text receipt confirms at least one member and does not imply receipt of its recording.

## Control carrier and bounds

Extension JSON is carried inside the existing exact typed receipt schema, with a reserved `dmr1:` message-ID prefix. The receiver consumes it before ordinary receipt matching, preview, unread counting or notifications. Existing Tim2Tox receipt handlers consume unresolved receipt IDs; the plaintext fallback and public group text remain unchanged.

Envelopes are limited to 8 KiB, split into 352-byte chunks with a random transfer ID, index and count. Reassembly is scoped by authenticated sender, conversation and transfer ID; chunks may arrive out of order. At most 24 parts, 32 incomplete assemblies and 30 seconds of retention are allowed. Conflicting chunks invalidate their transfer. Recording validation is applied again at the message boundary.

## Reproducing verification

Run bootstrap at the workspace root, then the API/backend suites. Native peer tests use `packages/ditmesh_chat/test/helpers/run_real_peers.py` with a hook-free `TIM2TOX_FFI_LIB`; they launch separate processes because Tim2Tox has one singleton per process. The scenarios cover exact direct/group timings, repeated text with distinct identities, actual delivery receipts, encrypted restart, recorded durable queue drainage and group rejoin. See [validation evidence](../VALIDATION.md) for this worktree's results and limitations.

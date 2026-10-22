[简体中文](./README.zh-CN.md)

# DitMesh Dart overlays

Bootstrap copies the pinned `third_party/tim2tox/dart` package into the ignored
`third_party/tim2tox_ditmesh` directory and applies numbered patches in order.
The source and patches are fingerprinted; run `dart run tool/bootstrap_deps.dart`
after changing a patch and `--offline-check-only` to verify the resulting stamp.
The pinned submodule remains unchanged.

`0010-recorded-receive-durability.patch` adds a receipt scope bound to the
history store's session and conversation-clear tokens. Cached duplicates must
complete a real write before their ACK; archive duplicates are checked under
the same write lock, including overflow rows still awaiting an archive write.
Failed arrivals retain a publication marker, so recovery emits their arrival
once. At the 128-entry limit, new receives fail before appending rather than
discarding an unpublished marker. A local Dart session generation also prevents
a closed or replaced receiver from publishing or acknowledging old work.
Expired session/clear scopes are pruned before applying the capacity limit;
valid unpublished entries for other conversations remain available to recover.

`packages/ditmesh_chat/test/recorded_receive_durability_test.dart` covers
unwritable storage, repeated retry, writable recovery, silent durable duplicate,
fresh-service disk reload, held-save teardown/reopen, history clear, and bounded
unpublished state.

`0011-adaptive-default-instance-poll.patch` lets a host whose only chat
service runs on the default native instance leave the upstream 50 ms
shared-instance poll. Upstream defaults are unchanged; `DitmeshFfiChatService`
opts out and sets a 500 ms idle cadence (200 ms for 2 s after any event or
send, 50 ms during inbound file transfers or while probe instances are
registered). `tox_iterate` runs on the native event thread, so only event
draining is paced. Outbound sends and extension packets mark activity and
re-arm an idle timer at once. An outbound file send (unreachable in DitMesh,
which sends no files) marks activity on start and on every progress event, so
it drains at 200 ms: outbound transfer records are not cleared on completion
and cannot drive the 50 ms rule. `packages/ditmesh_chat/test/poll_cadence_test.dart` covers the
policy and the session cadence; `native_two_peer_test.dart` checks the
production engine builds the adaptive service.

`0012-extension-refusal-keeps-queue.patch` adds `ExtensionSendRefused`, which
a `sendTextExtension` override throws when the native transport refuses one of
its packets. The offline-queue drain treats it like a refused native text send:
the item stays queued and its row stays pending instead of being marked failed.
A recorded envelope is retried under the same message identity, which the
receiver deduplicates. `packages/ditmesh_chat/test/recorded_resend_test.dart`
covers it together with DitMesh's replay of unacknowledged recorded messages.

`0013-legacy-row-reconcile.patch` lets a drain find a legacy own row
without a msgID again after its queue-removal await when a receipt replaced
it meanwhile (`copyWith`): by content and exact instant, so the row leaves
pending and keeps the receipt. Rows with a msgID use the upstream lookup.
It replaces the former `0005-preserve-recorded-outbox-ack.patch`, which
upstream #31 made redundant for rows with a msgID.
`packages/ditmesh_chat/test/legacy_recorded_outbox_test.dart` and
`recorded_outbox_ack_test.dart` cover both.

`0014-retry-failed-tombstone.patch` lets Retry re-queue a row whose drain
failure only its committed `failed` tombstone records (the row's own write
was lost before a restart, so the reloaded row does not say failed while
DitMesh shows it failed). Delivery proof still beats the failure.
`packages/ditmesh_chat/test/failed_tombstone_retry_test.dart` covers it.

`0015-preserve-future-history.patch` ports Tim2Tox
`5341e64ed62b81a94a311c768a73863a3cffcbb1` without changing the pinned
submodule. Reads and writes check both the primary and backup schema before
mutation, propagate `HistorySchemaNewerThanAppException`, and leave newer data
verbatim. It is rebased over 0010's receipt fence, so a recorded receive still
must commit before ACK/publication. The identity boundary maps this exception
to the localized upgrade-required error. `history_schema_downgrade_test.dart`,
`recorded_receive_durability_test.dart`, `recorded_resend_test.dart` and
`identity_persistence_test.dart` verify preservation and receipt behavior.

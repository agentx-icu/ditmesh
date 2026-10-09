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

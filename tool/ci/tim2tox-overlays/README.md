# DitMesh native overlays

The native builder copies the pinned Tim2Tox sources into
`build/native/.sources/<target>/tim2tox` and applies these reviewed patches.
It leaves `third_party/tim2tox` and the upstream Dart package unchanged.
Source contents, patches and the staging helper are fingerprinted. A changed
upstream source must still accept every patch; a mismatch fails the build.
Required and experimental CI native cache keys include the patch/helper digest.

`0001-enable-group-persistence.patch` enables Tox's group persistence option
before `tox_new` loads savedata. The upstream default omits NGC membership and
peer state, preventing groups from reconnecting after an identity restart.
DitMesh requires that state alongside the identity and protects savedata through
its encrypted profile storage and backup flows.

`0002-report-group-member-connection.patch` populates the existing member online
field from Tox's successful peer connection query and includes it in both JSON
member serializers. Self status also checks the local/group connection. Legacy
conference enumeration contains online peers only, according to the pinned Tox
API contract. Existing structures and exported function signatures are unchanged.

`0003-isolate-private-node-probes.patch` reserves signed `udp_start_port = -1`
on the existing headless `tim2tox_ffi_create_bootstrap_instance` creator for
private reachability probes. It disables local discovery and keeps the default
UDP bind range, without registering global SDK/message listeners or replaying
chat listeners. A probe's connection transitions therefore cannot produce the
unscoped `conn:` events that would change the live chat's connection state.
The C parameter remains `int` and the pinned Dart binding remains signed
`Int32`; no export is added or removed. Ordinary LAN hosting with `0` or a
positive preferred port retains discovery, IPv6 and its existing port range.
The option regression compiles the patched creator and executes private,
default, positive, maximum and invalid inputs; real native regressions verify
both probe/live-event isolation and ordinary LAN binding/DHT responses.

The required Linux and macOS CI jobs exercise two isolated real UDP peers, direct and group
messages, encrypted restart, durable queues and group restoration. The public
DHT network probe is separate and explicitly enabled with
`DITMESH_PUBLIC_DHT_SMOKE=true`.

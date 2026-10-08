# Complete Toxee bootstrap port implementation plan

**Goal:** Give DitMesh all working bootstrap features of Toxee at `88f9e478`, including settings before unlocking an identity, real node probes, desktop LAN hosting, and mobile network recovery.

**Architecture:** A separate `NetworkBootstrapService` contract in `ditmesh_chat_api` owns public node configuration and state. Its implementation and every Tim2Tox import stay in `ditmesh_chat`; the app owns responsive localized pages, lifecycle events, and platform network-path channels. Keep native pin `093730ce`, the group persistence/member-status overlays, and existing Morse-only composers.

**Tech stack:** Dart/Flutter, existing HTTP and FFI libraries, SharedPreferences-backed key/value store, Android ConnectivityManager, iOS NWPathMonitor.

The user authorized this port under the approved two-app architecture. No old-release compatibility or source-project edits are needed. The coordinator owns commits, CI, icons, and integration screenshots. Coordinate all Dart/Flutter commands with the screenshot agent.

## Verified source inventory

| Capability | Source | Port behavior |
| --- | --- | --- |
| Official catalogue and fallback | `lib/util/bootstrap_nodes.dart` | HTTPS `https://nodes.tox.chat/json`, eight-second deadline, row validation, status/maintainer/location/last ping, IPv4/IPv6 endpoints, visible fallback state |
| Startup and reconnect | `lib/util/bootstrap_node_ensurer.dart` | Saved selection immediately; first-run numeric fallback; four online entries refreshed after startup; manual/LAN modes never fetch public entries; resumed disconnected sessions refresh |
| Real reachability | `lib/util/bootstrap_node_probe.dart` | Fresh scratch native instance, discovery disabled, one candidate, serialized probes, ten-second timeout, one-second retries; distinguish negative, invalid, UDP unavailable, and probe unavailable |
| Settings and manual entry | `lib/ui/settings/bootstrap_settings_section.dart` | Auto/manual mode, current-node test, catalogue selection, exact tested host/port/key tuple before manual promotion, edited tuple invalidates result |
| Catalogue UI | `lib/ui/settings/bootstrap_nodes_page*.dart` | Refresh, online selection, separate test/switch actions, inconclusive results remain neutral, IPv6 bracketed display, narrow-width layout |
| Desktop LAN service | `lib/util/lan_bootstrap_service.dart` | Headless native DHT instance, requested UDP port range, real local address selection, start/stop sharing, generation cancellation, private separate profile, no startup autostart |
| LAN transactions and recovery | settings section / `lib/bootstrap/prefs_bootstrap.dart` | Snapshot prior node; failed start rolls back; stop restores prior selection; failed restore retains recovery state; cold start removes stale running state before session init |
| Network changes | `lib/util/network_change_rebootstrapper.dart` | First snapshot ignored, three-second debounce, thirty-second interval and one trailing kick, offline cancellation, no overlap, disposed session guards |
| Native mobile watchers | `NetworkPathChannel.kt`, iOS `AppDelegate.swift` | Effective path identity includes interface/address changes; `ditmesh/network_path` in the target |

Source LAN scanning is unimplemented: unused value types and localization only, confirmed by `test/mcp/S92_lan_bootstrap_service.md`. Port actual hosting and manual peer entry; do not create a scanner stub. Toxcore's existing local discovery remains enabled for ordinary peers and the LAN node.

The current production hook-free macOS library exports all required probe/LAN instance APIs. Relevant C++ bodies and Dart bindings are identical between the two pins; no pin upgrade is required. Independent review identified that source probes used full SDK listeners and could publish unscoped connection events into the user's session. Copied-source overlay `0003-isolate-private-node-probes.patch` reserves signed `udp_start_port=-1` on the existing headless creator for private probes: discovery disabled, default UDP range, no chat listeners. Normal LAN zero/positive port semantics and the 366 exported functions remain unchanged. The genuine isolation regression checks raw `conn:` broadcasts and live service state. Do not depend on source native test-only listener-count exports in production gates.

## Task 1: Contract, catalogue, and durable settings

Create `packages/ditmesh_chat_api/lib/src/network_bootstrap.dart` and its test fake. Create `packages/ditmesh_chat/lib/src/bootstrap/{node_catalogue,bootstrap_settings,host_resolver}.dart`.

1. Write failing tests for descriptor validation, IPv6 display, independent malformed-row rejection, fallback on HTTP/timeout/empty list, settings preservation, and stale LAN recovery.
2. Run the focused tests and record the expected failure before implementation.
3. Implement typed contracts and public-metadata-only persistence. Retain four verified numeric first-run seeds; remote list refresh must never gate startup. Preserve manual hostname text, resolve asynchronously with a deadline, and pass only numeric addresses into blocking native calls (including native init adapters).
4. Run focused tests, format, and analyze. Keep each module below 500 lines.

## Task 2: Probe, LAN host, and service facade

Create `packages/ditmesh_chat/lib/src/bootstrap/{node_probe,probe_session,lan_bootstrap_host,lan_addresses,network_bootstrap_service}.dart`; adapt engine/backend bootstrap wiring.

1. Write failing probe-verdict and facade tests covering manual selection, changing mode during pending fetch, stale session cancellation, LAN start/apply rollback, stop/restore failure, and no-identity settings/probe use.
2. Run the focused red tests.
3. Port isolated probe and desktop host mechanics with synchronous-only current-instance leases, cleanup in all exit paths, separate private DitMesh scratch/LAN directories, bounded startup, idempotent concurrent operations, and pre-LAN state recovery. Keep runtime state truthful instead of trusting a persisted running flag.
4. Connect the facade to backend startup, stop, and disposal without leaking native types across the app import boundary.
5. Run focused green tests. Add native gates for real ports, DHT responses, current-instance restoration, real local-client online states, active-probe cancellation, and absence of child-instance connection events in both the raw broadcast queue and live session; use only production exports.

## Task 3: Settings pages and mobile network recovery

Create `apps/ditmesh/lib/ui/network/{bootstrap_page,bootstrap_current_node,bootstrap_labels,bootstrap_nodes_page,bootstrap_manual_form,lan_bootstrap_panel}.dart`, network-path monitor/policy, and ten-language ARB messages. Wire BackendFactory/AppScope, Me, Welcome, Unlock, and lifecycle resume. Add Android/iOS channels using `ditmesh/network_path`.

1. Write failing functional widget tests for entrypoints, modes, pre-identity testing, list refresh/fallback, custom tuple validation/invalidation, negative versus inconclusive verdicts, node switch failure, LAN start/stop/share, phone widths/large text/RTL, and disposed asynchronous screens.
2. Run the red tests before implementing those behaviors.
3. Implement responsive widgets in the existing DitMesh style. Auto/manual modes show the saved current endpoint, full copyable public key, and a direct test action even for a custom node absent from the public catalogue. Show the LAN host's actual UDP port; do not imply the desktop host is a TCP relay server. Mobile supports auto/manual, including a manually entered LAN node; desktop adds hosting mode.
4. Port debounced network-path policy and register native watchers. On resume refresh disconnected live sessions; on a changed available path refresh even if Tox reports a stale connected state. Stop work when the session or mode generation changes.
5. Generate localization once the Flutter lock is available, then run widget/policy tests and app analysis.

## Task 4: Required validation and evidence

Run the focused and complete API/chat package suites, new native LAN/probe tests, existing four native tests, and the genuine two-process DM/group/restart/queued-send harness. Run scoped app tests and analysis, import/UI-literal/complexity guards, and native Android/iOS compilation where available. Coordinate screenshot scenes with the screenshot agent; the coordinator updates user docs and validation summaries.

Required evidence must distinguish local native/DHT success from public-network availability. Retain exact logs for failures. Do not mark TCP reachability proven by a UDP DHT verdict, do not silently use fakes in production, and do not modify Toxee or either native submodule.

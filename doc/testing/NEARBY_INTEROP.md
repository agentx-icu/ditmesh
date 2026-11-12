# DitMesh / Toxee native interoperability

[简体中文](./NEARBY_INTEROP.zh-CN.md)

`tool/test_nearby_toxee.py` starts independent Flutter test processes for
DitMesh and Toxee. DitMesh uses the production backend, transport adapter,
nearby state machine and `ChatLocation` codec. Toxee uses its existing native
nearby/location test, production nearby state machine, SDK and UIKit send path.
All payloads use real native Tox UDP sockets; files carry only bootstrap
endpoints and phase/verification metadata.

```sh
python3 tool/test_nearby_toxee.py \
  --toxee ../toxee \
  --toxee-harness ../toxee/build/location-verification-2q4l4xk1/flutter-harness \
  --ditmesh-lib build/native/macos-arm64/libtim2tox_ffi.dylib \
  --toxee-lib ../toxee/build/location-verification-2q4l4xk1/native-build/ffi/libtim2tox_ffi.dylib \
  --output build/nearby-toxee-interop/run
```

The Toxee harness is a prepared dependency checkout; its native loader must
resolve to `--toxee-lib`. The existing Toxee worker needs a native build with
its test-instance hooks enabled. DitMesh uses its ordinary hook-free library.
Pass `--flutter` when the intended Flutter SDK is not on PATH.

The runner makes an isolated copy of the Toxee test, preserving all production
code. Both peers use their production IPv6-enabled configuration; Toxee's
original test explicitly disables IPv6, which can otherwise let opposite
address-family sockets bind the same UDP port on macOS. This network override
is recorded in `result.json`. Profiles and logs stay in temporary test storage;
no existing account or HOME setting is changed.

Discovery waits allow 180 seconds on both workers. A second native cell can
connect inside the peer-join throttle; the production 60-second fix timer can
then need two ticks to send presence again. The test preserves that cadence
and records the isolated worker's wait override in the result.

Coverage includes two-cell discovery and deduplication, leaving one cell and
using the remaining route, encrypted friend intent, nonce-matched friend
request/acceptance, both directions of C2C and NGC location messages (including
group sender identity), discovery-cell isolation from ordinary chats/groups,
and peer disappearance when visibility is disabled.

`result.json` requires both process exit codes to be zero, all required phase
markers, distinct native peer PIDs and actual received native packets. Skipped
tests cannot pass. Fixed synthetic Pacific coordinates exercise the protocol;
this test makes no OS-location or GPS hardware claim. The application-level
OS permission/fix path must be tested separately on connected devices.

## System location evidence (2026-11-12)

The opt-in `integration_test/location_device_test.dart` uses the real OS provider, creates no identity and records no coordinates. Run from `apps/ditmesh`:

```sh
flutter test integration_test/location_device_test.dart -d macos --no-pub --dart-define=DITMESH_LOCATION_MANUAL_START=true
```

The initial attempts obtained no real position. Location services were enabled, but a permission request could hang; a foreground request returned granted while immediate and delayed checks remained denied, and the one-shot provider returned PermissionDeniedException. An independent foreground position-stream control (without explicit permission request) also returned PositionUpdateException and cancelled its subscription. The app bounds native waits and offers a system-settings recovery action. The historical investigation is retained below; see the final section for the dependency fix and passing real-location interop.

Redacted evidence is retained in ignored `build/location-device-verification/`: `summary.json`, `attempt-4.result.json`, `stream-direct.result.json` and runner logs. No iOS/Android physical device was connected. This real-OS limitation is separate from the passing two-process native interop test, which explicitly uses fixed synthetic coordinates.

### Local recheck (2026-11-12 17:17–17:30, UTC+8)

- Both the system location switch and DitMesh's permission were enabled. The repeated OS probe still obtained no position.
- A standalone native probe used an existing Developer ID certificate through a temporary Xcode override. On-disk signature and designated-requirement verification passed. An actual foreground click returned granted from the permission request, while immediate and delayed native checks returned denied, with `hasFix=false`. System logs also reported `get_verified_requirement: failed SecCodeCopyGuestWithAttributes`; the root cause remains unconfirmed.
- The native window rendered the production location card with clearly labeled synthetic Pacific coordinates, including coordinates, grid, time and snapshot notice. No real coordinates were displayed, recorded or sent.
- Two original 100-second discovery waits expired. After correcting the test budget, packet logs confirmed second-route recovery through the periodic broadcast. Both independent native processes exited zero, passing discovery, remaining-route fallback, friend intent, bidirectional C2C/group location messages and visibility shutdown. Each received four native nearby packets. Neither the Toxee checkout nor production broadcast cadence changed.
- The 38 related tests passed, and app static analysis found no issues.

Latest evidence: `build/nearby-toxee-interop/recheck-production-cadence/result.json`,
`build/location-device-verification/standalone-signed.result.json` and their logs.
The `signed-developerid-recheck/` integration-test attempt timed out awaiting a
foreground click and is not foreground-click evidence. That test now aborts
without a click instead of continuing to produce a misleading report.

Run the independent native window from `apps/ditmesh`:

```sh
flutter run -d macos --debug --no-pub --target integration_test/location_probe_app.dart
```

It creates no account or network session and logs no coordinates. The signing
control uses only a temporary local configuration; project signing is unchanged.

### Permission regression fix and real-position interop (2026-11-12 17:37–17:52, UTC+8)

The regression was isolated to `geolocator_apple`: 2.4.2 replaced the instance permission query with a background class-method query, retained in 2.4.3. [Upstream issue #1819](https://github.com/Baseflow/flutter-geolocator/issues/1819) reports the same macOS symptom; the [introducing commit](https://github.com/Baseflow/flutter-geolocator/commit/0b3a15bbbd8abadbec2d233a259436b7e6463dba) shows the change. With signing and system switches unchanged, switching only to 2.4.1 produced a valid real position on this host.

The app explicitly pins `geolocator_apple: 2.4.1`, preserving the global Pub
cache and Toxee checkout. A fresh CoreLocation manager can also briefly report
notDetermined, mapped by the plugin to denied. Permission requests now confirm
the actual OS status within a deadline before reporting granted. Persistent
denial remains denied; grants are neither cached nor used to bypass checks.
Two regression tests failed before this change and passed afterward.

An actual foreground click in the ordinary ad-hoc debug build returned a valid
real fix, with immediate and two-second delayed permission checks both `always`.
The position was about 30 ms old when read, with roughly 202 m accuracy.
The existing Developer ID signing control also succeeded. Project signing,
system switches and existing user accounts were unchanged.

That real OS snapshot subsequently passed bidirectional DitMesh ↔ Toxee
encrypted C2C location-message verification. Both independent native processes
exited zero and both received matching coordinates. Discovery kept synthetic
coordinates; no real position was advertised to public discovery cells. Real
mode covers C2C only, while ordinary synthetic mode retains group coverage.

Explicitly prepare a disposable private handoff from `apps/ditmesh`:

```sh
flutter run -d macos --debug --no-pub \
  --target integration_test/location_probe_app.dart \
  --dart-define=DITMESH_LOCATION_HANDOFF=true
```

After the foreground click succeeds, `LOCATION_FIX_HANDOFF` logs only the path.
The file in the app's private temporary directory contains the snapshot for
local test peers; the report contains no coordinates. Pass the path using the
runner's `--real-location-file /private/path/snapshot.json`. The runner validates
freshness, coordinates and the real-OS source marker; it does not acquire OS
location itself. Both peers use one real host snapshot, rather than independent
location acquisition on two mobile devices.

Real mode redacts worker output before writing logs and retains only matching
results in phase evidence. Temporary native accounts, message histories and
intermediate copies are removed afterward. This run also removed the original
handoff file. Evidence:

- `build/location-device-verification/permission-confirm-fixed.result.json`
- `build/nearby-toxee-interop/real-os-20261112-1747/result.json`
- `permission-confirm-red.log` / `permission-confirm-green.log` (permission regression tests)

The complete app suite passed 1600 tests with 36 skipped; four private-snapshot
and redaction tests also passed. App analysis and the import, UI-literal and
complexity guards passed.

Pre-PR review also covered the pinned plugin's single one-shot callback:
concurrent Apple nearby/chat/grid reads now share the native request while
retaining independent deadlines, and a later request can recover after all
callers time out. macOS/iOS overlap and timeout regressions pass. Remote nearby
names, intent wording and matched friend replies are cleaned only for display
using the existing `PeerText` policy; signed records and nonce wording are
unchanged. Unicode-control regressions exercise these confirmation paths.

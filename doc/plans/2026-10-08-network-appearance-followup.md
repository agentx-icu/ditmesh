# Network, appearance and icon follow-up

**Goal:** Complete the user's additional toxee bootstrap port, preserve MorseCQ's ten-language/five-style support, strengthen capture/testing, and apply the selected signal-tower icon.

**Architecture:** Retain the approved independent applications and Morse-only composers. `ditmesh_chat` implements a separate bootstrap facade; the app uses that facade and a test fake, without importing native SDK internals. Keep Tim2Tox `093730ce`: its hook-free library already exports the APIs used by toxee `88f9e478` for probes and LAN hosting, with identical native implementations. Preserve the two reviewed group overlays and apply the private-probe isolation overlay to a copied source tree; public FFI exports and the pinned upstream checkout remain unchanged.

**Tech stack:** Flutter 3.41.9 / Dart 3.11.5, existing Tox FFI, Android Kotlin/iOS Swift network watchers, Dart widget/integration tests, editable SVG and shared Dart icon generators.

**Authorization:** The user requested the complete existing toxee bootstrap feature set and selected icon C, the solid tower with Morse cutouts. This extends the already approved app split. No historical compatibility is required.

## Bootstrap

Create node/catalogue/address validation, persistent auto/manual selection, per-node native DHT probes, startup/resume/network rebootstrap and a transactional desktop LAN host in separate modules below the source complexity limit. Refresh the official HTTPS catalogue after immediate fallback startup; resolve hostnames asynchronously before native calls. Guard asynchronous work with session generations, restore pre-LAN selection after stop/crash, preserve the chat session's native instance, and dispose workers/timers/host instances on shutdown.

Add node list/probe/custom editor/mode controls and desktop LAN start/stop/copy/share information. Expose settings from Me and before identity creation/unlock. Mobile devices can select a LAN node and use native network-path notifications. Port Android/iOS watchers under `ditmesh/network_path` and localize all controls in the ten shipped locales.

Tests cover source feature parity, address/port/key validation, failed/repeated catalogue loads, manual isolation, detached sessions, probe verdicts and resource release, concurrent/cancelled LAN start, stop/recovery transactions, native instance isolation, mobile network debounce and the UI flows. Real native tests verify hosting and connecting to the advertised node with the production hook-free library.

## Appearance and capture

Retain all ten locales and five styles, including independent light/dark/system brightness and durable preferences. Add actual chat/group navigation, readable bubbles, large-text phone and desktop interaction tests across styles and locales.

Extend both apps' capture configuration to the ten canonical locale tags and a chosen style. Modern EN/ZH remains the default product gallery; other configurations require an explicit output directory. Validate configuration before capture/import and protect existing galleries on incomplete input. A bounded visual CI splits the axes: ten-language representative pages and five styles in both brightness modes and phone/desktop layouts, with real fonts. Do not generate a full thousands-frame Cartesian gallery.

## Icon C

`apps/ditmesh/icon/signal_tower_mask.svg` and its generated 1024px coverage image are the common mark. Both Dart generators consume that geometry for all platform assets, Android monochrome/adaptive variants and macOS/Windows/Linux tray images. Keep iOS marketing icons opaque and template icons transparent. Check actual ICO frames, PNG dimensions/alpha and small-size previews before packaging.

## Delivery and verification

Continue in `codex/chat-migration` and MorseCQ's existing `codex/offline-learning` worktree. Coordinate local Flutter commands, independently review the final bootstrap lifecycle, run source guards/tests/visual capture, then rebuild all required platform packages and checksum manifests in CI. Record actual implementation revisions and run results, update bilingual documentation, screenshots and PR descriptions. Retain the draft PRs; tag creation, publication, merging and store credentials remain owner actions.

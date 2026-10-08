[简体中文](./README.zh-CN.md)

# DitMesh

**Chat in Morse code.** DitMesh is a serverless Morse messenger over the [Tox](https://tox.chat) peer-to-peer network. Key messages with a straight key or iambic paddles, by touch or physical keyboard, in direct conversations and group nets. No phone number, e-mail or central registration is needed: your identity is generated on your device.

For offline Morse learning and practice, use [MorseCQ](https://github.com/agentx-icu/morsecq).

![DitMesh desktop and mobile product design concept](doc/designs/product-2026-10-08/product-concept.png)

*Product design concept.*

## Features

The main destinations are **Chat / Groups / Reference / Me** on phones, tablets and desktops.

- **Morse-only composing:** touch/keyboard straight key and iambic paddles, read-only decoded draft, Morse preview, pre-listen, correction and byte limit. There is no text-typing chat mode.
- **Direct chat:** Tox ID and QR contacts, friend requests, local notes to yourself, unread counts, drafts and persistent history.
- **Group nets:** create, join by group ID, invite, manage members and rejoin after restart. Group messages use the same Morse composer.
- **Playback and practice:** listener-selected speed and Farnsworth spacing, audio/haptic/flash playback, listen-first/reveal and listen-only modes, copy exercises, saved practice material and group practice.
- **Message management:** history search, filters, jump to result, bookmarks, queued-send cancellation and failed-send retry without duplicate bubbles.
- **Device identity and backups:** password-protected identity, encrypted export/restore with preview, selective components, Tox profile import and current DitMesh backup restore.
- **Privacy and moderation:** peer-to-peer encrypted transport, local notifications, blocked peers and community guidelines. No messaging or push server.
- **Reference and key setup:** alphabet, prosigns, Q-codes, translator, Chinese telegraph-code interpretation and configurable device key bindings.
- **Network configuration:** official node catalogue, node reachability tests, automatic/manual selection and desktop LAN hosting; network settings also work before unlocking an identity. [Node and LAN guide](doc/operations/NETWORK.md).
- **Appearance and languages:** ten interface locales; Classic Brass, Modern Calm, Night Radio, Paper Handbook and Fresh Cartoon styles with light/dark/system brightness.
- **Desktop integration:** responsive panes, window persistence, tray, unread badge and notification routing.

DitMesh exchanges messages with other Tox clients such as [toxee](https://github.com/agentx-icu/toxee). Morse playback uses your preferred speed and spacing.

Automatic mode uses saved or default nodes and refreshes the [official Tox list](https://nodes.tox.chat/) in the background; manual node settings are preserved. Both peers must be running and reachable for delivery. Messages for an offline peer wait in the send queue until the peer reconnects. Keep the app running to receive messages.

## Screenshots

<table><tr>
<td><img src="doc/screenshots/macos/en/conversation.png" alt="DitMesh direct Morse conversation on macOS"></td>
<td><img src="doc/screenshots/macos/en/group_conversation.png" alt="DitMesh group Morse conversation on macOS"></td>
</tr></table>

[Capture gallery and platform coverage](doc/screenshots/README.md) · [Capture languages/styles](tool/screenshots/README.md) · [Product design](doc/designs/product-2026-10-08/README.md) · [App icon](doc/designs/icon-2026-10-08/README.md)

Screenshots show demo conversations.

## Build and run

Pinned toolchain: **Flutter 3.41.9 / Dart 3.11.5**. Android, iOS, macOS **13.0 or later** (Intel/ARM), Linux and Windows are supported; browser chat is not supported by the native Tox transport.

```bash
git clone --recurse-submodules https://github.com/agentx-icu/ditmesh.git
cd ditmesh
dart run tool/bootstrap_deps.dart
dart pub get
bash tool/ci/build_tim2tox.sh --target macos-arm64
cd apps/ditmesh
flutter run -d macos
```

See [build and packaging](doc/operations/BUILD_AND_DEPLOY.md), [release requirements](doc/release/APP_STORE.md), [application responsibilities](doc/APP_SPLIT.md) and the [test pyramid](doc/testing/TEST_PYRAMID.md).

## Development checks

Run dependency resolution at the workspace root, not inside a package:

```bash
dart run tool/check_complexity.dart
dart run tool/import_guard.dart
dart run tool/ui_literal_guard.dart
dart analyze --fatal-infos tool
for dir in packages/* apps/*; do
  [ -f "$dir/pubspec.yaml" ] || continue
  flutter analyze "$dir"
  [ -d "$dir/test" ] || continue
  (cd "$dir" && flutter test --exclude-tags=needs-native)
done
```

## Privacy, support and licence

[Privacy](site/privacy.md) · [Community guidelines](site/terms.md) · [Support](https://github.com/agentx-icu/ditmesh/issues) · [GPL-3.0](LICENSE)

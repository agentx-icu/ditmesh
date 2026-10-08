# ditmesh overlay for the vendored `tencent_cloud_chat_sdk` plugin

Applied by `tool/bootstrap_deps.dart` **after** tim2tox's patch series, on
top of `third_party/tencent_cloud_chat_sdk/` (generated, gitignored).

Why: ditmesh talks to `libtim2tox_ffi` through the plugin's Dart bindings
(`setNativeLibraryName('tim2tox_ffi')`) and never to Tencent's servers, but
the plugin's *platform* halves still pull Tencent's native IM SDK — the
`TXIMSDK_Plus_iOS_XCFramework` / `TXIMSDK_Plus_Mac` pods, the
`com.tencent.imsdk:imsdk-plus` AAR plus four `libdart_native_imsdk.so`
ABIs, and `ImSDK.dll`/`dart_native_imsdk.dll` on Windows — tens of MB of
code the app never calls, with its own licence. This overlay replaces those
halves with no-op plugin classes so the generated plugin registrants still
link, and drops every Tencent binary.

Layout mirrors the plugin: every file here is copied over the same path in
the vendored plugin; `REMOVE.txt` lists paths deleted first. The overlay's
SHA-256 is recorded in `third_party/.vendor_state.json` (`overlay_sha256`)
so `--offline-check-only` can prove the tree matches.

Not a tim2tox patch on purpose: toxee needs the full plugin (hybrid runtime),
ditmesh does not. Upstreaming a "headless" flavour of the plugin is a later
option.

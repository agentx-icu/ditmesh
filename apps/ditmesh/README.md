# DitMesh (app)

The Flutter application shell for DitMesh. Feature logic lives in the
workspace packages (`packages/morse_core`, `packages/morse_trainer`,
`packages/morse_io`, `packages/ditmesh_chat`); this app wires them into a
responsive Material 3 UI.

Run from the repository root:

```bash
export PATH=/home/user/flutter/bin:$PATH
dart pub get                      # workspace-wide resolution
flutter analyze apps/ditmesh
(cd apps/ditmesh && flutter test)
(cd apps/ditmesh && flutter run -d macos)   # or linux / windows / a device
```

See the root `README.md` and `CLAUDE.md` for layout and conventions.

/// Internal feature context for isolated learning-surface tests.
///
/// DitMesh is always a Tox chat product. Production does not read the former
/// offline-trainer build flag; platform builds all use the same navigation,
/// identity startup and notification services.
class AppFeatures {
  const AppFeatures({this.chat = true});

  final bool chat;

  static const AppFeatures fromEnvironment = AppFeatures();
}

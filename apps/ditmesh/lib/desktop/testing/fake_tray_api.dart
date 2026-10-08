import '../tray_api.dart';

/// In-memory [TrayApi]. Records calls in [calls]; [failing] makes every call
/// throw (a tray-less session) and [unsupported] makes only the named
/// methods throw (Linux has no tooltip, for instance).
class FakeTrayApi implements TrayApi {
  FakeTrayApi({this.failing = false, Set<String> unsupported = const {}})
    : unsupported = {...unsupported};

  final List<String> calls = [];
  bool failing;
  final Set<String> unsupported;
  String? iconAsset;
  bool? isTemplate;
  String? tooltip;
  String? title;
  List<TrayMenuEntry> menu = const [];
  bool destroyed = false;
  TrayEventHandler? handler;

  void _guard(String method) {
    calls.add(method);
    if (failing || unsupported.contains(method)) {
      throw UnsupportedError('FakeTrayApi.$method is unavailable');
    }
  }

  @override
  Future<void> setIcon(String assetPath, {bool isTemplate = false}) async {
    _guard('setIcon');
    iconAsset = assetPath;
    this.isTemplate = isTemplate;
  }

  @override
  Future<void> setToolTip(String tooltip) async {
    _guard('setToolTip');
    this.tooltip = tooltip;
  }

  @override
  Future<void> setTitle(String title) async {
    _guard('setTitle');
    this.title = title;
  }

  @override
  Future<void> setMenu(List<TrayMenuEntry> entries) async {
    _guard('setMenu');
    menu = List.unmodifiable(entries);
  }

  @override
  Future<void> destroy() async {
    _guard('destroy');
    destroyed = true;
  }

  @override
  void setEventHandler(TrayEventHandler? handler) {
    calls.add('setEventHandler');
    this.handler = handler;
  }

  /// Left click on the icon.
  void simulateClick() => handler?.onTrayIconClicked();

  /// Activation of the menu row with [key].
  void simulateMenuItem(String key) => handler?.onTrayMenuItem(key);
}

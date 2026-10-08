import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records what the app asks to open; [opens] decides whether a mail app or
/// browser "exists". Installed for one test with [install].
class FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launched = <String>[];
  bool opens = true;

  static FakeUrlLauncher install() {
    final UrlLauncherPlatform previous = UrlLauncherPlatform.instance;
    final FakeUrlLauncher fake = FakeUrlLauncher();
    UrlLauncherPlatform.instance = fake;
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    return fake;
  }

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => opens;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return opens;
  }
}

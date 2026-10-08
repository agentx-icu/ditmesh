import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/identity/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<Object?, Object?> options;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = call.arguments as Map<Object?, Object?>;
          options = arguments['options']! as Map<Object?, Object?>;
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('macOS verifier uses Keychain without requiring provisioning', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await FlutterSecureStore().write('test-verifier', 'value');
    expect(options['usesDataProtectionKeychain'], 'false');
  });

  test('iOS verifier retains device-unlocked Keychain accessibility', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await FlutterSecureStore().write('test-verifier', 'value');
    expect(options['accessibility'], 'unlocked');
    expect(options['usesDataProtectionKeychain'], isNull);
  });
}

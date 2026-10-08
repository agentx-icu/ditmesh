import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');

  test(
    'platform false results are surfaced and failed cache edits reload',
    () async {
      SharedPreferences.resetStatic();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method.startsWith('getAll')) {
              return <String, Object>{'flutter.existing': 'before'};
            }
            return false;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        SharedPreferences.resetStatic();
      });
      final store = await SharedPreferencesStore.open();
      await expectLater(store.setString('existing', 'after'), throwsStateError);
      expect(store.getString('existing'), 'before');
      await expectLater(store.setBool('flag', true), throwsStateError);
      await expectLater(store.setInt('number', 1), throwsStateError);
      await expectLater(store.setStringList('list', ['x']), throwsStateError);
      await expectLater(store.remove('existing'), throwsStateError);
      expect(store.getString('existing'), 'before');
    },
  );
}

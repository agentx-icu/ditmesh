import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/notifications/flutter_local_notifications_api.dart';

void main() {
  test(
    'coinstalled DitMesh and MorseCQ have separate Windows toast activators',
    () {
      expect(
        FlutterLocalNotificationsApi.windowsGuid,
        isNot('e98da184-450e-43c1-88ba-c2082fc8de1d'),
        reason:
            'the source MorseCQ COM activator belongs to its own executable',
      );
      expect(
        FlutterLocalNotificationsApi.windowsAppUserModelId,
        'icu.agentx.ditmesh',
      );
      expect(
        FlutterLocalNotificationsApi.windowsGuid,
        matches(RegExp(r'^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$')),
      );
    },
  );
}

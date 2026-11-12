// Opt-in real-network probe. Uses an isolated temporary identity and the
// packaged production native library; no fake connection states or user data.
//
// flutter test integration_test/network_device_test.dart -d <device> --no-pub \
//   --dart-define=DITMESH_NETWORK_DEVICE_TEST=true
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real network: fresh identity and persisted native session reconnect',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      final result = await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('ditmesh_network_');
        DitmeshChatBackend? backend;
        final report = <String, Object?>{
          'platform': defaultTargetPlatform.name,
          'connectionProvider': 'real native Tox session',
          'syntheticConnection': false,
          'stages': <Map<String, Object?>>[],
        };
        try {
          backend = await DitmeshChatBackend.create(
            paths: IdentityPaths('${root.path}/identity'),
            store: MemoryKeyValueStore(),
            secureStore: MemorySecureStore(),
          );
          await backend.identity.create(displayName: 'Network device probe');
          final publicKey = backend.identity.current!.publicKey;
          for (final stage in ['coldStart', 'savedSessionRestart']) {
            final elapsed = Stopwatch()..start();
            await backend.identity.connect();
            while (backend.identity.connectionStatus !=
                    ConnectionStatus.online &&
                elapsed.elapsed < const Duration(seconds: 90)) {
              await Future<void>.delayed(const Duration(milliseconds: 250));
            }
            final online =
                backend.identity.connectionStatus == ConnectionStatus.online;
            (report['stages']! as List<Map<String, Object?>>).add({
              'name': stage,
              'online': online,
              'elapsedMs': elapsed.elapsedMilliseconds,
              'identityPreserved':
                  backend.identity.current?.publicKey == publicKey,
            });
            debugPrint('NETWORK_DEVICE_STAGE ${jsonEncode(report)}');
            if (!online) return report;
            await backend.identity.disconnect();
          }
          return report;
        } finally {
          await backend?.dispose();
          await root.delete(recursive: true);
        }
      });
      expect(result, isNotNull);
      binding.reportData = result;
      final stages = result!['stages']! as List<Map<String, Object?>>;
      expect(stages, hasLength(2));
      for (final stage in stages) {
        expect(stage['online'], isTrue, reason: jsonEncode(stage));
        expect(stage['identityPreserved'], isTrue);
      }
    },
    skip: !const bool.fromEnvironment('DITMESH_NETWORK_DEVICE_TEST'),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

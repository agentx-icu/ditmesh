import 'dart:async';
import 'package:ditmesh/di/app_services.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/lifecycle/network_change_rebootstrapper.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Network extends FakeNetworkBootstrapService {
  final calls = <bool>[];
  final guards = <bool Function()?>[];
  @override
  Future<void> rebootstrap({
    bool onlyIfDisconnected = false,
    bool Function()? isCurrent,
  }) async {
    calls.add(onlyIfDisconnected);
    guards.add(isCurrent);
  }
}

void main() {
  testWidgets(
    'resume refreshes only disconnected; network handover also nudges connected sessions',
    (tester) async {
      final identity = FakeIdentityService();
      final chat = FakeChatService();
      final locale = LocaleController(InMemoryKeyValueStore());
      final network = _Network();
      final paths = StreamController<NetworkPathSnapshot>.broadcast(sync: true);
      final services = AppServices(
        identity: identity,
        chat: chat,
        locale: locale,
        networkBootstrap: network,
        networkSnapshots: paths.stream,
      )..start();
      paths.add(const NetworkPathSnapshot(available: true, identity: 'wifi'));
      await tester.pump(const Duration(seconds: 4));
      expect(network.calls, isEmpty);
      paths.add(const NetworkPathSnapshot(available: true, identity: 'cell'));
      await tester.pump(const Duration(seconds: 4));
      expect(network.calls, [false]);
      services.lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
      services.lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(network.calls, [false, true]);
      final live = network.guards.first!;
      expect(live(), isTrue);
      await tester.runAsync(services.dispose);
      expect(live(), isFalse);
      paths.add(
        const NetworkPathSnapshot(available: true, identity: 'wifi-new'),
      );
      await tester.pump(const Duration(seconds: 40));
      expect(network.calls, [false, true]);
      await tester.runAsync(() async {
        await paths.close();
        await network.dispose();
        await chat.dispose();
        await identity.dispose();
      });
      locale.dispose();
    },
  );
}

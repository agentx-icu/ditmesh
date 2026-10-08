import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/bootstrap/bootstrap_settings.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';

const _node = BootstrapNode(
  host: '192.0.2.1',
  port: 33445,
  publicKey: '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
);
const _lan = BootstrapNode(
  host: '192.168.1.2',
  port: 33446,
  publicKey: '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674',
);

class _FailingStore extends MemoryKeyValueStore {
  String? failKey;
  @override
  Future<void> remove(String key) async {
    if (key == failKey) throw StateError('injected persistent failure');
    await super.remove(key);
  }
}

void main() {
  test('settings retain manual selection across instances', () async {
    final store = MemoryKeyValueStore();
    final settings = BootstrapSettings(store);
    await settings.setMode(BootstrapMode.manual);
    await settings.setCurrent(_node);
    final reopened = BootstrapSettings(store);
    expect(reopened.mode, BootstrapMode.manual);
    expect(reopened.current, _node);
  });

  test('cold start restores prior node and clears stale LAN state', () async {
    final store = MemoryKeyValueStore();
    final settings = BootstrapSettings(store);
    await settings.setCurrent(_node);
    await settings.stageLan();
    await settings.setCurrent(_lan);
    await settings.setLanRunning(true);
    await settings.recoverLan();
    expect(settings.current, _node);
    expect(settings.preLan, isNull);
    expect(settings.lanRunning, isFalse);
  });

  test(
    'journal flag failure preserves previous node until retry completes',
    () async {
      final store = _FailingStore();
      final settings = BootstrapSettings(store);
      await settings.setCurrent(_node);
      await settings.stageLan();
      await settings.setCurrent(_lan);
      await settings.setLanRunning(true);
      store.failKey = 'lan_bootstrap_transition_pending';
      await expectLater(settings.recoverLan(), throwsStateError);
      expect(settings.preLan, _node);
      store.failKey = null;
      await settings.recoverLan();
      expect(settings.current, _node);
      expect(settings.lanRunning, isFalse);
    },
  );

  test('cold start with no previous node clears dead LAN node', () async {
    final settings = BootstrapSettings(MemoryKeyValueStore());
    await settings.stageLan();
    await settings.setCurrent(_lan);
    await settings.setLanRunning(true);
    await settings.recoverLan();
    expect(settings.current, isNull);
    expect(settings.lanRunning, isFalse);
  });
}

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_adapter.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native init reads numeric resolution and preserves stored hostname',
    () async {
      final store = MemoryKeyValueStore();
      await store.setString('current_bootstrap_host', 'test.example');
      await store.setInt('current_bootstrap_port', 33445);
      await store.setString('current_bootstrap_pubkey', 'KEY');
      final prefs = Tim2ToxPreferencesAdapter(
        store,
        accountPrefix: 'test',
        resolveBootstrapHost: (_) async => '192.0.2.1',
        persistBootstrapSelection: false,
      );
      final bootstrap = Tim2ToxBootstrapAdapter(
        store,
        resolveHost: (_) async => '192.0.2.1',
      );
      expect((await prefs.getCurrentBootstrapNode())?.host, '192.0.2.1');
      expect(await bootstrap.getBootstrapHost(), '192.0.2.1');
      await prefs.setCurrentBootstrapNode('192.0.2.1', 33445, 'KEY');
      expect(store.getString('current_bootstrap_host'), 'test.example');
    },
  );
}

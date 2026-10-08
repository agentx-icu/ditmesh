import 'dart:async';
import 'dart:io';

import 'package:ditmesh_chat/src/bootstrap/host_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numeric seeds never invoke DNS', () async {
    final resolver = BootstrapHostResolver(
      lookup: (_) => throw StateError('DNS called'),
    );
    expect(await resolver.addresses('144.217.167.73'), ['144.217.167.73']);
    expect(await resolver.addresses('2001:db8::1'), ['2001:db8::1']);
  });
  test(
    'hostname resolution yields numeric addresses and has a deadline',
    () async {
      final resolver = BootstrapHostResolver(
        lookup: (_) async => [InternetAddress('192.0.2.1')],
      );
      expect(await resolver.addresses('test.example'), ['192.0.2.1']);
      final stalled = BootstrapHostResolver(
        timeout: const Duration(milliseconds: 5),
        lookup: (_) => Completer<List<InternetAddress>>().future,
      );
      expect(await stalled.addresses('offline.example'), isEmpty);
    },
  );
}

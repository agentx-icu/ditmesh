import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/src/identity/identity_record.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future identity metadata is neither recovered nor overwritten', () async {
    final dir = await Directory.systemTemp.createTemp('future_identity_');
    try {
      final file = File('${dir.path}/identity.json');
      const record = IdentityRecord(toxId: 'ABC', displayName: 'current');
      final future = jsonEncode({
        ...record.toJson(),
        'version': 999,
        'futureField': 'preserve',
      });
      await file.writeAsString(future);
      final unsupported = isA<ChatException>().having(
        (error) => error.code,
        'code',
        'unsupported_data_version',
      );
      await expectLater(IdentityRecord.read(file.path), throwsA(unsupported));
      await expectLater(record.write(file.path), throwsA(unsupported));
      expect(await file.readAsString(), future);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}

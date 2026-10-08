import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards every shipped ARB against drifting from the English template.
/// Data-driven over `lib/l10n/app_*.arb` (toxee's `_completeLocales`
/// pattern): adding `app_zh_Hant.arb` or `app_ja.arb` is covered
/// automatically. `flutter test` runs with the package root (apps/ditmesh)
/// as the working directory.
void main() {
  late Map<String, Object?> en;
  late Map<String, Map<String, Object?>> others; // file name -> content

  setUpAll(() {
    en = _readArb('lib/l10n/app_en.arb');
    others = {
      for (final file in _arbFiles().where((f) => !f.endsWith('app_en.arb')))
        file: _readArb(file),
    };
    expect(others, isNotEmpty, reason: 'at least one translation must ship');
  });

  test('every ARB declares a locale matching its file name', () {
    expect(en['@@locale'], 'en');
    others.forEach((file, arb) {
      final expected = RegExp(r'app_(.+)\.arb$').firstMatch(file)!.group(1);
      expect(arb['@@locale'], expected, reason: file);
    });
  });

  test('every translation has exactly the template key set', () {
    final enKeys = _messageKeys(en);
    others.forEach((file, arb) {
      final keys = _messageKeys(arb);
      expect(keys.difference(enKeys), isEmpty, reason: 'keys only in $file');
      expect(
        enKeys.difference(keys),
        isEmpty,
        reason: 'keys missing from $file — translate every key of '
            'app_en.arb in $file',
      );
    });
  });

  test('every message value is a non-empty string', () {
    for (final arb in [en, ...others.values]) {
      for (final key in _messageKeys(arb)) {
        expect(arb[key], isA<String>(), reason: key);
        expect((arb[key] as String).isNotEmpty, isTrue, reason: key);
      }
    }
  });

  test('translations keep every placeholder the template declares', () {
    for (final key in _messageKeys(en)) {
      final meta = en['@$key'];
      if (meta is! Map) continue;
      final placeholders = meta['placeholders'];
      if (placeholders is! Map) continue;
      others.forEach((file, arb) {
        final value = arb[key] as String;
        for (final name in placeholders.keys) {
          expect(
            value.contains('{$name'),
            isTrue,
            reason: '$key in $file drops placeholder {$name}',
          );
        }
      });
    }
  });

  test('plural messages carry an "other" branch in every file', () {
    final plural = RegExp(r'\{(\w+),\s*plural,');
    for (final arb in [en, ...others.values]) {
      for (final key in _messageKeys(arb)) {
        final value = arb[key] as String;
        if (!plural.hasMatch(value)) continue;
        expect(value, contains('other{'), reason: '$key in ${arb['@@locale']}');
      }
    }
  });

  test('no translation still carries a TODO marker', () {
    others.forEach((file, arb) {
      for (final key in arb.keys.where((k) => k.startsWith('@'))) {
        final meta = arb[key];
        if (meta is! Map) continue;
        final description = meta['description'];
        expect(
          description is String && description.contains('@@TODO'),
          isFalse,
          reason: '$key in $file is untranslated',
        );
      }
    });
  });

  test('every template message has a translator description', () {
    for (final key in _messageKeys(en)) {
      final meta = en['@$key'];
      expect(meta, isA<Map<String, Object?>>(),
          reason: 'app_en.arb has no "@$key" entry');
      final description = (meta as Map<String, Object?>)['description'];
      expect(
        description is String && description.trim().isNotEmpty,
        isTrue,
        reason: '"@$key" needs a description saying where the string is '
            'shown and what it means',
      );
    }
  });

  test('no template description points at the deleted *Strings classes', () {
    for (final key in _messageKeys(en)) {
      final meta = en['@$key'];
      if (meta is! Map) continue;
      final description = meta['description'];
      if (description is! String) continue;
      expect(description, isNot(contains('_strings.dart')), reason: key);
      expect(description, isNot(contains('Strings.')), reason: key);
    }
  });

  test('the nav destinations and app name exist', () {
    for (final key in [
      'appName',
      'navLearn',
      'navChat',
      'navGroups',
      'navReference',
      'navMe',
    ]) {
      expect(en.containsKey(key), isTrue, reason: key);
    }
    others.forEach((file, arb) {
      expect(arb['appName'], en['appName'],
          reason: 'product name is not translated ($file)');
    });
  });

  test('every ChatException code has an error message', () {
    const codes = [
      'errorWrongPassword',
      'errorPeerOffline',
      'errorInvalidToxId',
      'errorAlreadyFriend',
      'errorOwnId',
      'errorGroupNotFound',
      'errorMessageTooLong',
      'errorUnknown',
    ];
    for (final key in codes) {
      expect(en.containsKey(key), isTrue, reason: key);
    }
  });
}

List<String> _arbFiles() {
  final dir = Directory('lib/l10n');
  expect(dir.existsSync(), isTrue,
      reason: 'missing lib/l10n (cwd ${Directory.current.path})');
  return dir
      .listSync()
      .whereType<File>()
      .map((f) => f.path.replaceAll('\\', '/'))
      .where((p) => RegExp(r'/app_[A-Za-z_]+\.arb$').hasMatch(p))
      .toList()
    ..sort();
}

Map<String, Object?> _readArb(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue,
      reason: 'missing $path (cwd ${Directory.current.path})');
  final decoded = jsonDecode(file.readAsStringSync());
  expect(decoded, isA<Map<String, Object?>>());
  return decoded as Map<String, Object?>;
}

Set<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

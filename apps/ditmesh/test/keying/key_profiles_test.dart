import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/keying/key_profile.dart';
import 'package:ditmesh/keying/key_profiles.dart';
import 'package:ditmesh/keying/profile_keyer.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/training/training_settings.dart';

KeyProfile _vail() => KeyProfile(
  id: 'vail',
  name: 'Vail',
  straight: {LogicalKeyboardKey.keyK},
  dit: {LogicalKeyboardKey.bracketLeft},
  dah: {LogicalKeyboardKey.bracketRight},
);

void main() {
  group('profile', () {
    test('defaults match today\'s behaviour', () {
      final d = KeyProfile.defaults;
      expect(d.binding.actionFor(LogicalKeyboardKey.space), KeyerAction.straight);
      expect(d.binding.actionFor(LogicalKeyboardKey.controlLeft), KeyerAction.dit);
      expect(d.binding.actionFor(LogicalKeyboardKey.controlRight), KeyerAction.dah);
      expect(d.keyerMode, KeyerMode.iambicB);
      expect(d.appSidetone, isTrue);
      expect(d.adapterKeyer, isFalse);
      d.validate();
    });

    test('swap exchanges the paddle keys; adapter keys go straight', () {
      final swapped = _vail().copyWith(swapPaddles: true);
      expect(swapped.binding.actionFor(LogicalKeyboardKey.bracketLeft), KeyerAction.dah);
      final adapter = _vail().copyWith(adapterKeyer: true);
      expect(adapter.effectiveMode, KeyerMode.straight);
      expect(adapter.binding.actionFor(LogicalKeyboardKey.bracketLeft), KeyerAction.straight);
      expect(adapter.binding.actionFor(LogicalKeyboardKey.bracketRight), KeyerAction.straight);
    });

    test('duplicate, reserved and missing keys are refused', () {
      expect(
        () => _vail().copyWith(dah: {LogicalKeyboardKey.bracketLeft}).validate(),
        throwsA(isA<KeyProfileException>().having((e) => e.error, 'error', KeyProfileError.conflict)),
      );
      expect(
        () => _vail().copyWith(straight: {LogicalKeyboardKey.tab}).validate(),
        throwsA(isA<KeyProfileException>().having((e) => e.error, 'error', KeyProfileError.reserved)),
      );
      expect(
        () => _vail().copyWith(dah: const {}).validate(),
        throwsA(isA<KeyProfileException>().having((e) => e.error, 'error', KeyProfileError.missing)),
      );
      // A straight-only profile needs no paddles.
      _vail().copyWith(dit: const {}, dah: const {}, keyerMode: KeyerMode.straight).validate();
    });

    test('json round trip; unknown key ids are dropped', () {
      final p = _vail().copyWith(swapPaddles: true, appSidetone: false, keyerMode: KeyerMode.iambicA);
      expect(KeyProfile.fromJson(p.toJson()), p);
      final odd = KeyProfile.fromJson({...p.toJson(), 'straight': [-42, 'x']})!;
      expect(odd.straight, isEmpty);
      expect(KeyProfile.fromJson({'id': ''}), isNull);
    });
  });

  group('store', () {
    test('save selects, persists and reloads; delete falls back', () async {
      final kv = InMemoryKeyValueStore();
      final a = KeyProfiles(kv);
      expect(a.active.isDefault, isTrue);
      await a.save(_vail());
      expect(a.active.id, 'vail');
      final b = KeyProfiles(kv);
      expect(b.active, _vail());
      await b.useDefaults();
      expect(KeyProfiles(kv).active.isDefault, isTrue);
      await b.select('vail');
      await b.delete('vail');
      expect(b.active.isDefault, isTrue);
      expect(KeyProfiles(kv).saved, isEmpty);
    });

    test('an invalid profile is refused and not stored', () async {
      final kv = InMemoryKeyValueStore();
      final s = KeyProfiles(kv);
      await expectLater(
        s.save(_vail().copyWith(dit: {LogicalKeyboardKey.keyK})),
        throwsA(isA<KeyProfileException>()),
      );
      expect(s.saved, isEmpty);
      expect(kv.getString(KeyProfiles.storageKey), isNull);
    });

    test('a wrong-typed field never takes the app down', () {
      final odd = {..._vail().toJson(), 'keyerMode': 1, 'swapPaddles': 'yes'};
      final s = KeyProfiles(InMemoryKeyValueStore({
        KeyProfiles.storageKey: jsonEncode({'v': 1, 'selected': 'vail', 'profiles': [odd]}),
      }));
      expect(s.active.id, 'vail');
      expect(s.active.keyerMode, KeyerMode.iambicB);
      expect(s.active.swapPaddles, isFalse);
    });

    test('the sidetone switch gates only the sound, not flash or haptics', () {
      final tone = RecordingSink(clock: FakeClock());
      final flash = RecordingSink(clock: FakeClock());
      final echo = ProfileKeyer.gateSidetone(CompositeSink([tone, flash]), tone, () => false);
      echo.on();
      expect(tone.isOn, isFalse);
      expect(flash.isOn, isTrue);
      echo.off();
      expect(flash.isOn, isFalse);
    });

    test('broken, foreign-version or ambiguous stored data falls back', () {
      expect(KeyProfiles(InMemoryKeyValueStore({KeyProfiles.storageKey: '{oops'})).active.isDefault, isTrue);
      expect(
        KeyProfiles(InMemoryKeyValueStore({
          KeyProfiles.storageKey: jsonEncode({'v': 99, 'selected': 'vail', 'profiles': [_vail().toJson()]}),
        })).saved,
        isEmpty,
      );
      final bad = _vail().copyWith(dah: {LogicalKeyboardKey.keyK}).toJson();
      final s = KeyProfiles(InMemoryKeyValueStore({
        KeyProfiles.storageKey: jsonEncode({'v': 1, 'selected': 'vail', 'profiles': [bad]}),
      }));
      expect(s.saved, isEmpty);
      expect(s.active.isDefault, isTrue);
    });
  });
}

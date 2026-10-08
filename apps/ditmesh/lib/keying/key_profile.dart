import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:morse_io/morse_io.dart';

import '../training/training_settings.dart';

/// Why a key profile was refused (F12).
enum KeyProfileError {
  /// One key is bound to two actions.
  conflict,

  /// A key the system or the app needs (focus, back, OS shortcuts).
  reserved,

  /// No key at all for the actions the keyer mode needs.
  missing,
}

final class KeyProfileException implements Exception {
  const KeyProfileException(this.error, [this.keys = const {}]);

  final KeyProfileError error;
  final Set<LogicalKeyboardKey> keys;

  @override
  String toString() => 'KeyProfileException(${error.name}, $keys)';
}

/// A named, device-local keying setup (F12): which keyboard keys (or
/// keyboard-emulating adapter outputs) act as straight key / dit / dah,
/// paddle orientation, keyer mode, whether an external keyer already times
/// the elements, and whether the app sounds its own sidetone.
///
/// The app cannot tell which physical device sent a key event, so a profile
/// is a preset of bindings, never an automatic device detection.
@immutable
final class KeyProfile {
  KeyProfile({
    required this.id,
    required this.name,
    required Set<LogicalKeyboardKey> straight,
    required Set<LogicalKeyboardKey> dit,
    required Set<LogicalKeyboardKey> dah,
    this.swapPaddles = false,
    this.keyerMode = KeyerMode.iambicB,
    this.adapterKeyer = false,
    this.appSidetone = true,
  }) : straight = Set.unmodifiable(straight),
       dit = Set.unmodifiable(dit),
       dah = Set.unmodifiable(dah);

  /// Today's behaviour: Space / left Ctrl / right Ctrl, iambic B, sidetone.
  static final KeyProfile defaults = KeyProfile(
    id: 'default',
    name: '',
    straight: KeyboardKeyBinding.defaults.straight,
    dit: KeyboardKeyBinding.defaults.dit,
    dah: KeyboardKeyBinding.defaults.dah,
  );

  static const int version = 1;

  /// Keys never accepted: focus and navigation, and OS-level modifiers
  /// whose key-up the app often never sees.
  static final Set<LogicalKeyboardKey> reservedKeys = {
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.capsLock,
    LogicalKeyboardKey.fn,
    LogicalKeyboardKey.fnLock,
    LogicalKeyboardKey.power,
    LogicalKeyboardKey.goBack,
  };

  final String id;

  /// User-given name; empty for the built-in default.
  final String name;
  final Set<LogicalKeyboardKey> straight;
  final Set<LogicalKeyboardKey> dit;
  final Set<LogicalKeyboardKey> dah;

  /// Left-handed: dah on the left paddle and on the dit key.
  final bool swapPaddles;
  final KeyerMode keyerMode;

  /// The external device runs its own keyer and sends timed key-down /
  /// key-up: every bound key is treated as a straight key and the app does
  /// not generate iambic elements from it.
  final bool adapterKeyer;

  /// Whether the app sounds its sidetone while keying (an adapter with its
  /// own sidetone may want it off). Decoding is unaffected.
  final bool appSidetone;

  bool get isDefault => id == defaults.id;

  /// The binding every keying surface uses.
  KeyboardKeyBinding get binding {
    final base = KeyboardKeyBinding(straight: straight, dit: dit, dah: dah);
    final oriented = swapPaddles ? base.swapped() : base;
    return adapterKeyer ? oriented.straightOnly() : oriented;
  }

  /// The keyer mode keying surfaces run: straight while an adapter keys its
  /// own elements.
  KeyerMode get effectiveMode => adapterKeyer ? KeyerMode.straight : keyerMode;

  /// Throws [KeyProfileException] for duplicate or reserved bindings, or
  /// when the mode lacks a key.
  void validate() {
    final binding = KeyboardKeyBinding(straight: straight, dit: dit, dah: dah);
    if (binding.hasConflicts) {
      throw KeyProfileException(KeyProfileError.conflict, binding.conflicts);
    }
    final reserved = {...straight, ...dit, ...dah}.intersection(reservedKeys);
    if (reserved.isNotEmpty) {
      throw KeyProfileException(KeyProfileError.reserved, reserved);
    }
    final needsPaddles = keyerMode.isPaddle && !adapterKeyer;
    if (needsPaddles ? dit.isEmpty || dah.isEmpty : effectiveKeys.isEmpty) {
      throw const KeyProfileException(KeyProfileError.missing);
    }
  }

  Set<LogicalKeyboardKey> get effectiveKeys => {...straight, ...dit, ...dah};

  /// The keys that key in [mode] under this profile (for hints).
  Set<LogicalKeyboardKey> keysFor(KeyerMode mode) {
    final b = binding;
    return effectiveMode == KeyerMode.straight || !mode.isPaddle
        ? b.straight
        : {...b.dit, ...b.dah};
  }

  KeyProfile copyWith({
    String? id,
    String? name,
    Set<LogicalKeyboardKey>? straight,
    Set<LogicalKeyboardKey>? dit,
    Set<LogicalKeyboardKey>? dah,
    bool? swapPaddles,
    KeyerMode? keyerMode,
    bool? adapterKeyer,
    bool? appSidetone,
  }) => KeyProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    straight: straight ?? this.straight,
    dit: dit ?? this.dit,
    dah: dah ?? this.dah,
    swapPaddles: swapPaddles ?? this.swapPaddles,
    keyerMode: keyerMode ?? this.keyerMode,
    adapterKeyer: adapterKeyer ?? this.adapterKeyer,
    appSidetone: appSidetone ?? this.appSidetone,
  );

  static List<int> _ids(Set<LogicalKeyboardKey> keys) =>
      keys.map((k) => k.keyId).toList()..sort();

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'straight': _ids(straight),
    'dit': _ids(dit),
    'dah': _ids(dah),
    'swapPaddles': swapPaddles,
    'keyerMode': keyerMode.name,
    'adapterKeyer': adapterKeyer,
    'appSidetone': appSidetone,
  };

  /// Null for a malformed entry. Unknown key ids are dropped; the result is
  /// validated by the caller.
  static KeyProfile? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;
    Set<LogicalKeyboardKey> keys(Object? raw) => {
      if (raw is List)
        for (final v in raw)
          if (v is int) ?LogicalKeyboardKey.findKeyByKeyId(v),
    };
    bool flag(String k, bool fallback) =>
        json[k] is bool ? json[k]! as bool : fallback;
    return KeyProfile(
      id: id,
      name: name,
      straight: keys(json['straight']),
      dit: keys(json['dit']),
      dah: keys(json['dah']),
      swapPaddles: flag('swapPaddles', false),
      keyerMode: KeyerMode.parse(
        json['keyerMode'] is String ? json['keyerMode']! as String : null,
      ),
      adapterKeyer: flag('adapterKeyer', false),
      appSidetone: flag('appSidetone', true),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeyProfile &&
      setEquals(other.straight, straight) &&
      setEquals(other.dit, dit) &&
      setEquals(other.dah, dah) &&
      other.id == id &&
      other.name == name &&
      other.swapPaddles == swapPaddles &&
      other.keyerMode == keyerMode &&
      other.adapterKeyer == adapterKeyer &&
      other.appSidetone == appSidetone;

  @override
  int get hashCode => Object.hash(id, name, swapPaddles, keyerMode);
}

/// Readable names of [keys] (the keyboard's own labels, not translated),
/// sorted, for hints and the setup page.
String keyLabels(Iterable<LogicalKeyboardKey> keys) {
  final names = [
    for (final k in keys) k.keyLabel.trim().isEmpty ? k.debugName ?? '?' : k.keyLabel,
  ]..sort();
  return names.join(' · ');
}

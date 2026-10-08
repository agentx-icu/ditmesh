import 'package:flutter/services.dart';

/// What a bound key does.
enum KeyerAction { straight, dit, dah }

/// Maps physical-keyboard keys to keyer actions. Pure data, no widgets.
///
/// Defaults: Space = straight key, left Ctrl = dit, right Ctrl = dah. The
/// sets are not `const` because [LogicalKeyboardKey] overrides `==`, which
/// Dart forbids in constant collections.
final class KeyboardKeyBinding {
  KeyboardKeyBinding({
    Set<LogicalKeyboardKey>? straight,
    Set<LogicalKeyboardKey>? dit,
    Set<LogicalKeyboardKey>? dah,
  })  : straight = Set<LogicalKeyboardKey>.unmodifiable(
            straight ?? <LogicalKeyboardKey>{LogicalKeyboardKey.space}),
        dit = Set<LogicalKeyboardKey>.unmodifiable(
            dit ?? <LogicalKeyboardKey>{LogicalKeyboardKey.controlLeft}),
        dah = Set<LogicalKeyboardKey>.unmodifiable(
            dah ?? <LogicalKeyboardKey>{LogicalKeyboardKey.controlRight});

  /// Space / left Ctrl / right Ctrl.
  static final KeyboardKeyBinding defaults = KeyboardKeyBinding();

  final Set<LogicalKeyboardKey> straight;
  final Set<LogicalKeyboardKey> dit;
  final Set<LogicalKeyboardKey> dah;

  /// Action for [key], or null when the key is not bound. Straight wins over
  /// dit over dah if a key is (mis)configured in several sets.
  KeyerAction? actionFor(LogicalKeyboardKey key) {
    if (straight.contains(key)) {
      return KeyerAction.straight;
    }
    if (dit.contains(key)) {
      return KeyerAction.dit;
    }
    if (dah.contains(key)) {
      return KeyerAction.dah;
    }
    return null;
  }

  /// Action for a keyboard [event]. Returns null for unbound keys and for
  /// [KeyRepeatEvent]s, which must never re-trigger a key that is held.
  KeyerAction? actionForEvent(KeyEvent event) =>
      event is KeyRepeatEvent ? null : actionFor(event.logicalKey);

  /// Keys bound to more than one action. A valid configuration has none:
  /// [actionFor]'s precedence is a fallback, not a feature.
  Set<LogicalKeyboardKey> get conflicts => <LogicalKeyboardKey>{
    ...straight.intersection(dit),
    ...straight.intersection(dah),
    ...dit.intersection(dah),
  };

  bool get hasConflicts => conflicts.isNotEmpty;

  /// Every bound key as a straight key, no paddles: for an external adapter
  /// that runs its own keyer and sends already-timed key-down / key-up, so
  /// the app must not generate a second iambic sequence from those marks.
  KeyboardKeyBinding straightOnly() => KeyboardKeyBinding(
    straight: <LogicalKeyboardKey>{...straight, ...dit, ...dah},
    dit: const <LogicalKeyboardKey>{},
    dah: const <LogicalKeyboardKey>{},
  );

  /// Swaps the dit and dah sets (left-handed operators).
  KeyboardKeyBinding swapped() =>
      KeyboardKeyBinding(straight: straight, dit: dah, dah: dit);

  KeyboardKeyBinding copyWith({
    Set<LogicalKeyboardKey>? straight,
    Set<LogicalKeyboardKey>? dit,
    Set<LogicalKeyboardKey>? dah,
  }) =>
      KeyboardKeyBinding(
        straight: straight ?? this.straight,
        dit: dit ?? this.dit,
        dah: dah ?? this.dah,
      );
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/desktop/shortcuts.dart';

SingleActivator _activatorFor(
  Map<ShortcutActivator, Intent> bindings,
  Type intent,
) =>
    bindings.entries.singleWhere((e) => e.value.runtimeType == intent).key
        as SingleActivator;

void main() {
  test('binds K, N and M to the three intents', () {
    final bindings = desktopShortcutBindings(platform: TargetPlatform.linux);
    expect(bindings, hasLength(3));
    expect(
      _activatorFor(bindings, FocusSearchIntent).trigger,
      LogicalKeyboardKey.keyK,
    );
    expect(
      _activatorFor(bindings, NewMessageIntent).trigger,
      LogicalKeyboardKey.keyN,
    );
    expect(
      _activatorFor(bindings, ToggleSidetoneIntent).trigger,
      LogicalKeyboardKey.keyM,
    );
  });

  test('uses Command on macOS and Control elsewhere', () {
    for (final a in desktopShortcutBindings(
      platform: TargetPlatform.macOS,
    ).keys.cast<SingleActivator>()) {
      expect(a.meta, isTrue);
      expect(a.control, isFalse);
    }
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.android,
    ]) {
      for (final a in desktopShortcutBindings(
        platform: platform,
      ).keys.cast<SingleActivator>()) {
        expect(a.control, isTrue, reason: '$platform');
        expect(a.meta, isFalse, reason: '$platform');
      }
    }
  });

  test('labels read ⌘K on Apple platforms and Ctrl+K elsewhere', () {
    expect(
      shortcutLabel(const SingleActivator(LogicalKeyboardKey.keyK, meta: true)),
      '⌘K',
    );
    expect(
      shortcutLabel(
        const SingleActivator(LogicalKeyboardKey.keyK, control: true),
      ),
      'Ctrl+K',
    );
    expect(
      shortcutLabel(
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ),
      ),
      'Ctrl+Shift+N',
    );
  });

  test('intents are const and distinct', () {
    expect(const ToggleSidetoneIntent(), isNot(const FocusSearchIntent()));
    expect(const FocusSearchIntent(), isNot(const NewMessageIntent()));
    expect(identical(const NewMessageIntent(), const NewMessageIntent()), true);
  });
}

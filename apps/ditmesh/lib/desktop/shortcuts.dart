import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// In-app (not system-wide) keyboard intents for the desktop shell.
///
/// `AppShell` binds search and new-message commands in its active route.
/// Sidetone stays unbound until a shared audio owner can implement it.

/// Mute / unmute the Morse sidetone.
class ToggleSidetoneIntent extends Intent {
  const ToggleSidetoneIntent();
}

/// Move focus to the search field of the current page.
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

/// Start a new message / conversation.
class NewMessageIntent extends Intent {
  const NewMessageIntent();
}

/// Whether the platform's primary shortcut modifier is Command (Apple) rather
/// than Control.
bool usesCommandModifier(TargetPlatform platform) =>
    platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;

/// Default bindings: Cmd/Ctrl+K search, Cmd/Ctrl+N new message,
/// Cmd/Ctrl+Shift+M mute sidetone. [platform] defaults to [defaultTargetPlatform].
Map<ShortcutActivator, Intent> desktopShortcutBindings({
  TargetPlatform? platform,
}) {
  final command = usesCommandModifier(platform ?? defaultTargetPlatform);
  SingleActivator primary(LogicalKeyboardKey key) => SingleActivator(
    key,
    meta: command,
    control: !command,
    includeRepeats: false,
  );
  return <ShortcutActivator, Intent>{
    primary(LogicalKeyboardKey.keyK): const FocusSearchIntent(),
    primary(LogicalKeyboardKey.keyN): const NewMessageIntent(),
    SingleActivator(
      LogicalKeyboardKey.keyM,
      meta: command,
      control: !command,
      shift: true,
    ): const ToggleSidetoneIntent(),
  };
}

/// The label shown beside an existing command's localized tooltip.
String shortcutHint(Intent intent, {TargetPlatform? platform}) => shortcutLabel(
  desktopShortcutBindings(platform: platform).entries
          .singleWhere((entry) => entry.value.runtimeType == intent.runtimeType)
          .key
      as SingleActivator,
);

/// Human-readable label for menus and tooltips, e.g. "⌘K" or "Ctrl+K".
String shortcutLabel(SingleActivator activator) {
  final parts = <String>[];
  if (activator.control) parts.add('Ctrl');
  if (activator.alt) parts.add('Alt');
  if (activator.shift) parts.add('Shift');
  final key = activator.trigger.keyLabel.toUpperCase();
  if (activator.meta) {
    final extra = parts.isEmpty ? '' : '${parts.join('+')}+';
    return '⌘$extra$key';
  }
  parts.add(key);
  return parts.join('+');
}

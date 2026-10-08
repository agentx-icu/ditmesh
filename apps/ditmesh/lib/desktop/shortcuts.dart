import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// In-app (not system-wide) keyboard intents for the desktop shell.
///
/// Pure definitions: pages bind them with `Actions` when they gain the
/// corresponding feature. Default bindings come from
/// [desktopShortcutBindings]; drop the map into a `Shortcuts` widget above
/// the navigator.

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
/// Cmd/Ctrl+M mute sidetone. [platform] defaults to [defaultTargetPlatform].
Map<ShortcutActivator, Intent> desktopShortcutBindings({
  TargetPlatform? platform,
}) {
  final command = usesCommandModifier(platform ?? defaultTargetPlatform);
  SingleActivator primary(LogicalKeyboardKey key) =>
      SingleActivator(key, meta: command, control: !command);
  return <ShortcutActivator, Intent>{
    primary(LogicalKeyboardKey.keyK): const FocusSearchIntent(),
    primary(LogicalKeyboardKey.keyN): const NewMessageIntent(),
    primary(LogicalKeyboardKey.keyM): const ToggleSidetoneIntent(),
  };
}

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

import 'package:flutter/foundation.dart';

/// User preferences for message notifications. Read at post time, so a
/// change applies to the next notification without restarting anything.
///
/// Persistence is the owner's job: the orchestrator round-trips [toJson] /
/// [NotificationPrefs.fromJson] through whatever settings store it already
/// uses and listens for changes to save. Defaults (everything on, nothing
/// muted) are what a fresh install gets.
class NotificationPrefs extends ChangeNotifier {
  NotificationPrefs({
    bool enabled = true,
    bool showText = true,
    bool showPattern = true,
    bool sound = true,
    Iterable<String> muted = const <String>[],
  }) : _enabled = enabled,
       _showText = showText,
       _showPattern = showPattern,
       _sound = sound,
       _muted = Set<String>.of(muted);

  factory NotificationPrefs.fromJson(Map<String, Object?> json) {
    final Object? muted = json['muted'];
    return NotificationPrefs(
      enabled: json['enabled'] as bool? ?? true,
      showText: json['showText'] as bool? ?? true,
      showPattern: json['showPattern'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
      muted: muted is List ? muted.whereType<String>() : const <String>[],
    );
  }

  bool _enabled;
  bool _showText;
  bool _showPattern;
  bool _sound;
  final Set<String> _muted;

  /// Master switch for message / request / invite notifications. The unread
  /// badge is unaffected (it mirrors the conversation list, not alerts).
  bool get enabled => _enabled;
  set enabled(bool value) => _set(value != _enabled, () => _enabled = value);

  /// Include the plain text in the body.
  bool get showText => _showText;
  set showText(bool value) => _set(value != _showText, () => _showText = value);

  /// Include the Morse pattern (`-.-. --.-`) in the body. With both this and
  /// [showText] off the body is a neutral "New message".
  bool get showPattern => _showPattern;
  set showPattern(bool value) =>
      _set(value != _showPattern, () => _showPattern = value);

  bool get sound => _sound;
  set sound(bool value) => _set(value != _sound, () => _sound = value);

  Set<String> get mutedConversations => Set<String>.unmodifiable(_muted);

  bool isMuted(String conversationId) => _muted.contains(conversationId);

  /// Replaces identity-scoped choices when the active identity changes.
  void replaceMuted(Iterable<String> conversations) {
    final next = conversations.toSet();
    if (setEquals(next, _muted)) return;
    _muted
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void setMuted(String conversationId, bool muted) {
    final bool changed = muted
        ? _muted.add(conversationId)
        : _muted.remove(conversationId);
    if (changed) notifyListeners();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': _enabled,
    'showText': _showText,
    'showPattern': _showPattern,
    'sound': _sound,
    'muted': _muted.toList()..sort(),
  };

  void _set(bool changed, void Function() apply) {
    if (!changed) return;
    apply();
    notifyListeners();
  }
}

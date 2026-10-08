import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../i18n/locale_controller.dart';
import '../ui/appearance/ui_style.dart';
import '../ui/chat/input_mode.dart';
import '../ui/listen/listen_settings.dart';
import 'app_preferences.dart';

/// The preferences a complete backup carries (F10), as one explicit
/// document: playback, reference playback, decoder settings, notification
/// choices and this identity's mutes, appearance and language. Window
/// geometry, keyer / external-key bindings, OS permissions and anything
/// transient are deliberately absent, so a restore on another device never
/// applies them.
extension PortablePreferences on AppPreferences {
  static const int version = 1;

  Uint8List exportPortable({LocaleController? locale}) {
    final n = notifications;
    final doc = <String, Object?>{
      'version': version,
      'chat.playback': {
        'wpm': playback.wpm,
        'farnsworthWpm': playback.farnsworthWpm,
        'toneHz': playback.toneHz,
        'trainingMode': playback.trainingMode,
        'inputMode': playback.inputMode.name,
        'autoPlay': playback.autoPlay,
        'listenOnly': playback.listenOnly,
      },
      'reference.playback': {
        'wpm': reference.wpm,
        'farnsworthWpm': reference.farnsworthWpm,
        'toneHz': reference.toneHz,
      },
      'listen.decoder': {
        'blockSize': listen.settings.blockSize,
        'minElementMs': listen.settings.minElementMs,
        'autoTune': listen.settings.autoTune,
        'manualHz': listen.settings.manualHz,
      },
      'notifications': {
        'enabled': n.enabled,
        'showText': n.showText,
        'showPattern': n.showPattern,
        'sound': n.sound,
        'muted': n.mutedConversations.toList()..sort(),
      },
      'appearance': {
        'style': settings.style.name,
        'mode': settings.themeMode.name,
      },
      if (locale != null)
        'locale': switch (locale.locale) {
          null => null,
          final Locale l => {
            'language': l.languageCode,
            'script': l.scriptCode,
            'country': l.countryCode,
          },
        },
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(doc)));
  }

  /// Applies [bytes] (from [exportPortable], possibly another device's)
  /// through the models' own validating setters and waits until it is
  /// saved. On failure the previous values are applied again and the error
  /// rethrown, so a half-applied document never sticks. Unknown keys and
  /// unknown versions are ignored field by field.
  Future<void> applyPortable(
    Uint8List bytes, {
    LocaleController? locale,
  }) async {
    final Object? doc;
    try {
      doc = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return;
    }
    if (doc is! Map) return;
    final previous = exportPortable(locale: locale);
    try {
      await _apply(doc, locale);
      await flush();
    } on Object {
      final old = jsonDecode(utf8.decode(previous));
      try {
        await _apply(old as Map, locale);
        await flush();
      } on Object catch (e) {
        debugPrint('[PortablePreferences] rollback failed: $e');
      }
      rethrow;
    }
  }

  Future<void> _apply(Map<Object?, Object?> doc, LocaleController? locale) async {
    double? number(Map m, String k) {
      final v = m[k];
      return v is num && v.isFinite ? v.toDouble() : null;
    }

    if (doc['chat.playback'] case final Map c) {
      if (number(c, 'wpm') case final double v) playback.wpm = v;
      if (number(c, 'farnsworthWpm') case final double v) {
        playback.farnsworthWpm = v;
      }
      if (number(c, 'toneHz') case final double v) playback.toneHz = v;
      if (c['trainingMode'] case final bool v) playback.trainingMode = v;
      if (c['autoPlay'] case final bool v) playback.autoPlay = v;
      if (c['listenOnly'] case final bool v) playback.listenOnly = v;
      final mode = InputMode.values.where((m) => m.name == c['inputMode']);
      if (mode.isNotEmpty) playback.inputMode = mode.first;
    }
    if (doc['reference.playback'] case final Map r) {
      if (number(r, 'wpm') case final double v) reference.wpm = v;
      if (number(r, 'toneHz') case final double v) reference.toneHz = v;
      reference.farnsworthWpm = number(r, 'farnsworthWpm');
    }
    if (doc['listen.decoder'] case final Map l) {
      final s = listen.settings;
      final block = number(l, 'blockSize')?.toInt();
      listen.update(
        ListenSettings(
          blockSize: ListenSettings.blockSizes.contains(block)
              ? block!
              : s.blockSize,
          minElementMs: (number(l, 'minElementMs')?.toInt() ?? s.minElementMs)
              .clamp(ListenSettings.minElementMinMs, ListenSettings.minElementMaxMs),
          autoTune: l['autoTune'] is bool ? l['autoTune']! as bool : s.autoTune,
          manualHz: (number(l, 'manualHz') ?? s.manualHz).clamp(
            ListenSettings.minHz,
            ListenSettings.maxHz,
          ),
        ),
      );
    }
    if (doc['notifications'] case final Map n) {
      final prefs = notifications;
      if (n['enabled'] case final bool v) prefs.enabled = v;
      if (n['showText'] case final bool v) prefs.showText = v;
      if (n['showPattern'] case final bool v) prefs.showPattern = v;
      if (n['sound'] case final bool v) prefs.sound = v;
      if (n['muted'] case final List muted) {
        prefs.replaceMuted(muted.whereType<String>());
      }
    }
    if (doc['appearance'] case final Map a) {
      final style = UiStyle.values.where((s) => s.name == a['style']);
      final mode = ThemeMode.values.where((m) => m.name == a['mode']);
      await settings.applyAppearance(
        style: style.isEmpty ? settings.style : style.first,
        themeMode: mode.isEmpty ? settings.themeMode : mode.first,
      );
    }
    if (locale != null && doc.containsKey('locale')) {
      final l = doc['locale'];
      final language = l is Map ? l['language'] : null;
      await locale.setLocale(
        language is String && language.isNotEmpty
            ? Locale.fromSubtags(
                languageCode: language,
                scriptCode: l is Map && l['script'] is String
                    ? l['script'] as String
                    : null,
                countryCode: l is Map && l['country'] is String
                    ? l['country'] as String
                    : null,
              )
            : null,
      );
    }
  }
}

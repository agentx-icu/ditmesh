import 'package:flutter/foundation.dart';

import 'listen_settings.dart';

/// Shared user choices; live microphone/decoded text remains screen-local.
final class ListenPreferences extends ChangeNotifier {
  ListenPreferences([ListenSettings settings = const ListenSettings()])
    : _settings = settings;

  ListenSettings _settings;
  ListenSettings get settings => _settings;

  void update(ListenSettings value) {
    if (_settings == value) return;
    _settings = value;
    notifyListeners();
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../training/training_controller.dart';
import '../../training/training_controller_host.dart';
import 'morse_playback_controller.dart';

/// Shares the identity's existing vibration preference with both chat keying
/// and message playback. No independent setting or audio preference is added.
final class ConversationHapticBinding {
  ConversationHapticBinding({
    required IdentityService identity,
    required MorsePlaybackController playback,
    TrainingControllerHost? training,
  }) : _identity = identity,
       _playback = playback,
       _training = training;

  static ConversationHapticBinding attach(
    BuildContext context,
    MorsePlaybackController playback,
  ) {
    final binding = ConversationHapticBinding(
      identity: context.read<IdentityService>(),
      playback: playback,
      training: context.read<TrainingControllerHost?>(),
    );
    unawaited(binding.start());
    return binding;
  }

  final IdentityService _identity;
  final MorsePlaybackController _playback;
  final TrainingControllerHost? _training;
  TrainingController? _controller;
  StreamSubscription<Identity?>? _identities;
  VoidCallback? _unbind;
  Future<void>? _starting;
  String? _profileKey;
  int _generation = 0;
  bool _disposed = false;

  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    if (_disposed) return;
    _unbind = _playback.bindHaptics(_allowsHaptics);
    // Isolated chat surfaces without the shared host stay conservatively off.
    if (_training == null) return;
    _identities = _identity.identityChanges.listen((_) => unawaited(_load()));
    await _load();
  }

  bool _allowsHaptics() {
    final controller = _controller;
    return !_disposed &&
        controller != null &&
        !controller.isDisposed &&
        _profileKey == _identity.current?.publicKey &&
        controller.settings.hapticEnabled;
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _detach();
    _profileKey = _identity.current?.publicKey;
    final key = _profileKey;
    if (_disposed || key == null) return;
    try {
      final controller = await _training!.controller();
      if (_disposed ||
          generation != _generation ||
          key != _identity.current?.publicKey ||
          controller.isDisposed) {
        return;
      }
      _controller = controller;
      controller.addListener(_refresh);
      _refresh();
    } on Object {
      // Unavailable/newer training data must not silently opt into vibration.
    }
  }

  void _refresh() => _playback.refreshHaptics();

  void _detach() {
    _controller?.removeListener(_refresh);
    _controller = null;
    _refresh();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    unawaited(_identities?.cancel());
    _identities = null;
    _detach();
    _unbind?.call();
    _unbind = null;
  }
}

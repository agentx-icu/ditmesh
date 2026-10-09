part of 'morse_playback_controller.dart';

extension _PlaybackControls on MorsePlaybackController {
  void _scheduleProgress() {
    _progressTimer?.cancel();
    if (_disposed || _current == null || _player.isPaused) return;
    _progressTimer = clock.schedule(const Duration(milliseconds: 100), () {
      _progressTimer = null;
      if (_disposed || _current == null || _player.isPaused) return;
      if (!_player.isPaused) _notify();
      _scheduleProgress();
    });
  }

  Future<void> _restartRange(_Clip clip) {
    clip.paused = _manualPaused;
    _halt();
    clip.repeated = false;
    _queue.addFirst(clip);
    return _advance();
  }
}

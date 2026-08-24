import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays a looping ringtone while an incoming video/chat session is waiting
/// for the professional to answer. Stops when the call is accepted or
/// dismissed.
class RingtoneService {
  AudioPlayer? _player;
  bool _disposed = false;

  /// Starts the ringtone (loops until [stop] is called). Safe to call
  /// multiple times — it will not start a second player while one is active.
  Future<void> start() async {
    if (_disposed) return;
    if (_player != null) return;

    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);
      _player = player;
      await player.play(AssetSource('sounds/ringtone.wav'));
    } catch (e) {
      _player = null;
      debugPrint('RingtoneService: failed to play ringtone: $e');
    }
  }

  /// Stops the ringtone and releases the audio player.
  Future<void> stop() async {
    final player = _player;
    _player = null;
    if (player == null) return;

    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      debugPrint('RingtoneService: error stopping ringtone: $e');
    }
  }

  /// Whether a ringtone is currently playing.
  bool get isPlaying => _player != null;

  Future<void> dispose() async {
    _disposed = true;
    await stop();
  }
}

/// Shared ringtone service for the app.
final ringtoneServiceProvider = Provider<RingtoneService>((ref) {
  final service = RingtoneService();
  ref.onDispose(service.dispose);
  return service;
});
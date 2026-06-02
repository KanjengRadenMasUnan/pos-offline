import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static AudioPlayer? _player;

  static Future<void> playBeep() async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}

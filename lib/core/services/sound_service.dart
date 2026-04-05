import 'package:audioplayers/audioplayers.dart';

/// Plays a soft UI confirmation sound on like / add-to-cart actions.
///
/// Uses a CC-licensed UI click sound from freesound.org (benzix2):
///   assets/sounds/ui_click.m4a — soft button click (default)
///   assets/sounds/tink.m4a    — iOS-style tink (alternative)
///   assets/sounds/pop.m4a     — deeper pop (alternative)
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  AudioPlayer? _player;
  bool _preloading = false;

  /// Call this early (e.g. in initState) to warm up the native player
  /// so the first tap has zero latency.
  Future<void> preload() async {
    if (_player != null || _preloading) return;
    _preloading = true;
    await _ensureInit();
    _preloading = false;
  }

  Future<void> _ensureInit() async {
    if (_player != null) return;

    // Ambient = plays through the silence switch on iOS.
    // mixWithOthers = does not interrupt background music.
    await AudioPlayer.global.setAudioContext(
      const AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: [AVAudioSessionOptions.mixWithOthers],
        ),
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          usageType: AndroidUsageType.notificationEvent,
          contentType: AndroidContentType.sonification,
        ),
      ),
    );

    _player = AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.stop);
    await _player!.setVolume(0.6);

    // Pre-cache the asset so the first playback is instant.
    await _player!.setSource(AssetSource('sounds/ui_click.m4a'));
  }

  /// Fire-and-forget. Never throws.
  Future<void> playTing() async {
    try {
      await _ensureInit();
      final player = _player;
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource('sounds/ui_click.m4a'));
    } catch (_) {}
  }
}

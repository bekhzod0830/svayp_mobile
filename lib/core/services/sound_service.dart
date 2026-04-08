import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _prefKey = 'sound_effects_enabled';

  // In-memory cache; loaded lazily from SharedPreferences.
  bool? _soundEnabled;

  /// Whether swipe sound effects are enabled. Defaults to true.
  Future<bool> get soundEnabled async {
    _soundEnabled ??= await _loadPref();
    return _soundEnabled!;
  }

  /// Returns the cached value synchronously (true until first load completes).
  bool get soundEnabledSync => _soundEnabled ?? true;

  Future<bool> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  /// Persist and cache the new value.
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  /// Load the preference into cache (call once on app start or profile open).
  Future<void> loadPreference() async {
    _soundEnabled = await _loadPref();
  }

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
    // Respect user preference — skip playback if sounds are disabled.
    if (!soundEnabledSync) return;
    try {
      await _ensureInit();
      final player = _player;
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource('sounds/ui_click.m4a'));
    } catch (_) {}
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _musicEnabled);

    if (!_musicEnabled) {
      await _bgmPlayer.stop();
    }
  }

  Future<void> playSound(String soundPath) async {
    if (!_soundEnabled) return;

    try {
      await _sfxPlayer.play(AssetSource('sounds/$soundPath'));
    } catch (e) {
      // Handle audio error silently
      print('Audio error: $e');
    }
  }

  Future<void> playBackgroundMusic(String musicPath) async {
    if (!_musicEnabled) return;

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/$musicPath'));
    } catch (e) {
      print('Background music error: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
  }

  // Predefined sound effects
  Future<void> playWinSound() => playSound('win.mp3');
  Future<void> playLoseSound() => playSound('lose.mp3');
  Future<void> playClickSound() => playSound('click.wav');
  Future<void> playGameSound() => playSound('game_start.wav');
  Future<void> playScoreSound() => playSound('score.wav');
  Future<void> playErrorSound() => playSound('error.wav');
  Future<void> playCountdownSound() => playSound('countdown.wav');
  Future<void> playPowerUpSound() => playSound('powerup.wav');

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
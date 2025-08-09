import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_score.dart';
import '../../data/repositories/score_repository.dart';
import '../../core/services/audio_service.dart';

// Repository provider
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepository();
});

// Audio service provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

// Cup scores provider
final cupScoresProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getCupScores();
});

// Game scores provider
final gameScoresProvider = Provider.family<List<GameScore>, String>((ref, gameType) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getScoresForGame(gameType);
});

// All scores provider
final allScoresProvider = Provider<List<GameScore>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getAllScores();
});

// Recent scores provider
final recentScoresProvider = Provider<List<GameScore>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getRecentScores(10);
});

// Player win counts provider
final playerWinCountsProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getPlayerWinCounts();
});

// Game statistics provider
final gameStatsProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getGameStats();
});

// Player names provider
final playerNamesProvider = Provider<Map<String, String>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getPlayerNames();
});

// Settings provider
class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier(this._repository) : super({}) {
    _loadSettings();
  }

  final ScoreRepository _repository;

  void _loadSettings() {
    state = {
      'soundEnabled': _repository.getSetting('sound_enabled', defaultValue: true),
      'musicEnabled': _repository.getSetting('music_enabled', defaultValue: true),
      'vibrationEnabled': _repository.getSetting('vibration_enabled', defaultValue: true),
      'player1Name': _repository.getPlayerName(1),
      'player2Name': _repository.getPlayerName(2),
    };
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _repository.setSetting(key, value);
    state = {...state, key: value};
  }

  Future<void> setPlayerName(int player, String name) async {
    await _repository.setPlayerName(player, name);
    state = {...state, 'player${player}Name': name};
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return SettingsNotifier(repository);
});

// Game session provider for tracking current game state
class GameSessionNotifier extends StateNotifier<GameSession?> {
  GameSessionNotifier() : super(null);

  void startGame(String gameType) {
    state = GameSession(
      gameType: gameType,
      startTime: DateTime.now(),
      player1Score: 0,
      player2Score: 0,
    );
  }

  void updateScore(int player, int score) {
    if (state == null) return;

    if (player == 1) {
      state = state!.copyWith(player1Score: score);
    } else {
      state = state!.copyWith(player2Score: score);
    }
  }

  void endGame(int winner) {
    if (state == null) return;

    state = state!.copyWith(
      winner: winner,
      endTime: DateTime.now(),
    );
  }

  void resetGame() {
    state = null;
  }
}

final gameSessionProvider = StateNotifierProvider<GameSessionNotifier, GameSession?>((ref) {
  return GameSessionNotifier();
});

// Game session model
class GameSession {
  final String gameType;
  final DateTime startTime;
  final DateTime? endTime;
  final int player1Score;
  final int player2Score;
  final int? winner;

  GameSession({
    required this.gameType,
    required this.startTime,
    this.endTime,
    required this.player1Score,
    required this.player2Score,
    this.winner,
  });

  int get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  GameSession copyWith({
    String? gameType,
    DateTime? startTime,
    DateTime? endTime,
    int? player1Score,
    int? player2Score,
    int? winner,
  }) {
    return GameSession(
      gameType: gameType ?? this.gameType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      winner: winner ?? this.winner,
    );
  }
}
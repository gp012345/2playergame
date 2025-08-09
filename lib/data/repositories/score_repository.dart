import 'package:hive/hive.dart';
import '../models/game_score.dart';

class ScoreRepository {
  static const String _scoresBoxName = 'scores';
  static const String _settingsBoxName = 'settings';

  Box<GameScore> get _scoresBox => Hive.box<GameScore>(_scoresBoxName);
  Box get _settingsBox => Hive.box(_settingsBoxName);

  Future<void> saveGameScore(GameScore score) async {
    await _scoresBox.add(score);
    await _updateCupScores(score.winner);
  }

  List<GameScore> getAllScores() {
    return _scoresBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<GameScore> getScoresForGame(String gameType) {
    return _scoresBox.values
        .where((score) => score.gameType == gameType)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<GameScore> getRecentScores([int limit = 10]) {
    final scores = getAllScores();
    return scores.take(limit).toList();
  }

  Map<String, int> getGameStats() {
    final scores = getAllScores();
    final stats = <String, int>{};

    for (final score in scores) {
      stats[score.gameType] = (stats[score.gameType] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> getPlayerWinCounts() {
    final scores = getAllScores();
    int player1Wins = 0;
    int player2Wins = 0;
    int draws = 0;

    for (final score in scores) {
      switch (score.winner) {
        case 1:
          player1Wins++;
          break;
        case 2:
          player2Wins++;
          break;
        default:
          draws++;
      }
    }

    return {
      'player1': player1Wins,
      'player2': player2Wins,
      'draws': draws,
    };
  }

  Future<void> _updateCupScores(int winner) async {
    if (winner == 0) return; // Don't update for draws

    final currentP1Score = _settingsBox.get('player1_cup_score', defaultValue: 0);
    final currentP2Score = _settingsBox.get('player2_cup_score', defaultValue: 0);

    if (winner == 1) {
      await _settingsBox.put('player1_cup_score', currentP1Score + 1);
    } else {
      await _settingsBox.put('player2_cup_score', currentP2Score + 1);
    }
  }

  Map<String, int> getCupScores() {
    return {
      'player1': _settingsBox.get('player1_cup_score', defaultValue: 0),
      'player2': _settingsBox.get('player2_cup_score', defaultValue: 0),
    };
  }

  Future<void> resetCupScores() async {
    await _settingsBox.put('player1_cup_score', 0);
    await _settingsBox.put('player2_cup_score', 0);
  }

  Future<void> clearAllScores() async {
    await _scoresBox.clear();
    await resetCupScores();
  }

  // Settings management
  Future<void> setPlayerName(int player, String name) async {
    await _settingsBox.put('player${player}_name', name);
  }

  String getPlayerName(int player) {
    return _settingsBox.get('player${player}_name', defaultValue: 'Player $player');
  }

  Map<String, String> getPlayerNames() {
    return {
      'player1': getPlayerName(1),
      'player2': getPlayerName(2),
    };
  }

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
}
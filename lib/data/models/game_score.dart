import 'package:hive/hive.dart';

part 'game_score.g.dart';

@HiveType(typeId: 0)
class GameScore extends HiveObject {
  @HiveField(0)
  late String gameType;

  @HiveField(1)
  late int player1Score;

  @HiveField(2)
  late int player2Score;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late int winner; // 1 or 2, 0 for draw

  @HiveField(5)
  late int gameDuration; // in seconds

  @HiveField(6)
  String? gameData; // Additional game-specific data (JSON)

  GameScore({
    required this.gameType,
    required this.player1Score,
    required this.player2Score,
    required this.winner,
    this.gameDuration = 0,
    this.gameData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get winnerName {
    switch (winner) {
      case 1:
        return 'Player 1';
      case 2:
        return 'Player 2';
      default:
        return 'Draw';
    }
  }

  String get gameTitle {
    final titles = {
      'tictactoe': 'Tic Tac Toe',
      'pingpong': 'Ping Pong',
      'spinner': 'Spinner War',
      'airhockey': 'Air Hockey',
      'snakes': 'Snakes',
      'pool': 'Pool',
      'penalty': 'Penalty Kicks',
      'sumo': 'Sumo',
      'chess': 'Chess',
      'golf': 'Mini Golf',
      'racing': 'Racing Cars',
      'sword': 'Sword Duels',
      'reaction': 'Reaction Time',
      'memory': 'Memory Flip',
      'typing': 'Speed Typing',
      'trivia': 'Trivia Quiz',
      'tapdot': 'Tap the Dot',
      'wordpuzzle': 'Word Puzzle',
    };
    return titles[gameType] ?? 'Unknown Game';
  }

  String get formattedDuration {
    final minutes = gameDuration ~/ 60;
    final seconds = gameDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
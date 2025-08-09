import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../games/game_stubs.dart';
import '../games/tic_tac_toe_game.dart';
import '../games/reaction_time_game.dart';
import '../games/memory_flip_game.dart';
import '../providers/game_provider.dart';
import '../../core/theme/app_theme.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String gameType;

  const GameScreen({super.key, required this.gameType});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Start game session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameSessionProvider.notifier).startGame(widget.gameType);
    });
  }

  @override
  void dispose() {
    // Reset game session when leaving
    ref.read(gameSessionProvider.notifier).resetGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget gameWidget;

    switch (widget.gameType) {
      case 'tictactoe':
        gameWidget = const TicTacToeGame();
        break;
      case 'pingpong':
        gameWidget = const PingPongGame();
        break;
      case 'spinner':
        gameWidget = const SpinnerWarGame();
        break;
      case 'reaction':
        gameWidget = const ReactionTimeGame();
        break;
      case 'memory':
        gameWidget = const MemoryFlipGame();
        break;
      case 'tapdot':
        gameWidget = const TapDotGame();
        break;
      case 'wordpuzzle':
        gameWidget = const WordPuzzleGame();
        break;
      case 'airhockey':
        gameWidget = const AirHockeyGame();
        break;
      default:
        gameWidget = ComingSoonGame(gameType: widget.gameType);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getGameTitle(widget.gameType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(child: gameWidget),
      ),
    );
  }

  String _getGameTitle(String gameType) {
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
    return titles[gameType] ?? 'Game';
  }
}

class ComingSoonGame extends StatelessWidget {
  final String gameType;

  const ComingSoonGame({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction,
              size: 64,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This game is under development',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home),
            label: const Text('Back to Games'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
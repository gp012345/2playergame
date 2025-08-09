import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_service.dart';
import '../../data/models/game_score.dart';
import '../providers/game_provider.dart';
import '../screens/game_result_dilog.dart';

enum GameState { waiting, ready, go, finished }

class ReactionTimeGame extends ConsumerStatefulWidget {
  const ReactionTimeGame({super.key});

  @override
  ConsumerState<ReactionTimeGame> createState() => _ReactionTimeGameState();
}

class _ReactionTimeGameState extends ConsumerState<ReactionTimeGame>
    with TickerProviderStateMixin {
  GameState _gameState = GameState.waiting;
  Timer? _gameTimer;
  DateTime? _startTime;
  int _player1BestTime = 0;
  int _player2BestTime = 0;
  int _currentRound = 1;
  final int _maxRounds = 5;
  List<int> _player1Times = [];
  List<int> _player2Times = [];
  int? _currentTime;
  bool _player1Pressed = false;
  bool _player2Pressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startNewRound();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: AppTheme.accentColor,
    ).animate(_colorController);

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    setState(() {
      _gameState = GameState.waiting;
      _player1Pressed = false;
      _player2Pressed = false;
      _currentTime = null;
    });

    _colorController.reset();

    // Random delay between 2-6 seconds
    final delay = Duration(milliseconds: 2000 + Random().nextInt(4000));

    _gameTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _gameState = GameState.go;
          _startTime = DateTime.now();
        });
        _colorController.forward();
        AudioService().playGameSound();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _playerPressed(int player) {
    if (_gameState != GameState.go ||
        (player == 1 && _player1Pressed) ||
        (player == 2 && _player2Pressed)) {
      return;
    }

    final reactionTime = DateTime.now().difference(_startTime!).inMilliseconds;

    setState(() {
      if (player == 1) {
        _player1Pressed = true;
        if (!_player2Pressed) _currentTime = reactionTime;
      } else {
        _player2Pressed = true;
        if (!_player1Pressed) _currentTime = reactionTime;
      }
    });

    HapticFeedback.lightImpact();
    AudioService().playClickSound();

    // Record the time
    if (player == 1) {
      _player1Times.add(reactionTime);
      if (_player1BestTime == 0 || reactionTime < _player1BestTime) {
        _player1BestTime = reactionTime;
      }
    } else {
      _player2Times.add(reactionTime);
      if (_player2BestTime == 0 || reactionTime < _player2BestTime) {
        _player2BestTime = reactionTime;
      }
    }

    // Check if round is complete
    if (_player1Pressed && _player2Pressed) {
      _completeRound();
    }
  }

  void _completeRound() {
    setState(() {
      _gameState = GameState.finished;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentRound < _maxRounds) {
        setState(() {
          _currentRound++;
        });
        _startNewRound();
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    // Calculate average times
    final player1Avg = _player1Times.isEmpty
        ? 9999
        : _player1Times.reduce((a, b) => a + b) ~/ _player1Times.length;
    final player2Avg = _player2Times.isEmpty
        ? 9999
        : _player2Times.reduce((a, b) => a + b) ~/ _player2Times.length;

    final winner = player1Avg < player2Avg ? 1 : 2;

    final gameSession = ref.read(gameSessionProvider);
    if (gameSession != null) {
      final score = GameScore(
        gameType: 'reaction',
        player1Score: _player1Times.length,
        player2Score: _player2Times.length,
        winner: winner,
        gameDuration: gameSession.duration,
        gameData: 'P1Avg:$player1Avg,P2Avg:$player2Avg,P1Best:$_player1BestTime,P2Best:$_player2BestTime',
      );
      ref.read(scoreRepositoryProvider).saveGameScore(score);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        result: winner == 1 ? 'Player 1' : 'Player 2',
        player1Score: _player1Times.length,
        player2Score: _player2Times.length,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _resetGame();
        },
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _resetGame() {
    _gameTimer?.cancel();
    setState(() {
      _currentRound = 1;
      _player1Times.clear();
      _player2Times.clear();
      _player1BestTime = 0;
      _player2BestTime = 0;
    });
    _startNewRound();
  }

  @override
  Widget build(BuildContext context) {
    final playerNames = ref.watch(playerNamesProvider);

    return Scaffold(
      body: Column(
        children: [
          // Round indicator
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: AppTheme.surfaceDecoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Round $_currentRound / $_maxRounds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentTime != null)
                  Text(
                    'Last: ${_currentTime}ms',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Game area
          Expanded(
            child: AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _gameState == GameState.go ? _pulseAnimation.value : 1.0,
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _getGameAreaColor(),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getGameAreaColor().withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: _gameState == GameState.go ? 10 : 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getGameIcon(),
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _getGameText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_gameState == GameState.go) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'TAP YOUR SIDE NOW!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Player areas
          Row(
            children: [
              // Player 1 area
              Expanded(
                child: GestureDetector(
                  onTap: () => _playerPressed(1),
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _player1Pressed
                          ? AppTheme.player1Color.withOpacity(0.8)
                          : AppTheme.player1Color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.player1Color,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: AppTheme.player1Color,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playerNames['player1'] ?? 'Player 1',
                          style: TextStyle(
                            color: AppTheme.player1Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_player1BestTime > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Best: ${_player1BestTime}ms',
                            style: TextStyle(
                              color: AppTheme.player1Color.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Player 2 area
              Expanded(
                child: GestureDetector(
                  onTap: () => _playerPressed(2),
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _player2Pressed
                          ? AppTheme.player2Color.withOpacity(0.8)
                          : AppTheme.player2Color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.player2Color,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppTheme.player2Color,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playerNames['player2'] ?? 'Player 2',
                          style: TextStyle(
                            color: AppTheme.player2Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_player2BestTime > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Best: ${_player2BestTime}ms',
                            style: TextStyle(
                              color: AppTheme.player2Color.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Reset button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGameAreaColor() {
    switch (_gameState) {
      case GameState.waiting:
        return Colors.grey.shade700;
      case GameState.ready:
        return Colors.orange;
      case GameState.go:
        return _colorAnimation.value ?? AppTheme.accentColor;
      case GameState.finished:
        return AppTheme.primaryColor;
    }
  }

  IconData _getGameIcon() {
    switch (_gameState) {
      case GameState.waiting:
        return Icons.timer;
      case GameState.ready:
        return Icons.hourglass_empty;
      case GameState.go:
        return Icons.flash_on;
      case GameState.finished:
        return Icons.check_circle;
    }
  }

  String _getGameText() {
    switch (_gameState) {
      case GameState.waiting:
        return 'Get Ready!\nWatch for the green signal...';
      case GameState.ready:
        return 'Almost there...';
      case GameState.go:
        return 'GO!';
      case GameState.finished:
        return 'Round Complete!';
    }
  }
}
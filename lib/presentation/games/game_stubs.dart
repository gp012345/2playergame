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

// Spinner War Game
class SpinnerWarGame extends ConsumerStatefulWidget {
  const SpinnerWarGame({super.key});

  @override
  ConsumerState<SpinnerWarGame> createState() => _SpinnerWarGameState();
}

class _SpinnerWarGameState extends ConsumerState<SpinnerWarGame>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  int _player1Score = 0;
  int _player2Score = 0;
  int _currentRound = 1;
  final int _maxRounds = 5;
  int? _lastResult;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.decelerate),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _lastResult = null;
    });

    HapticFeedback.mediumImpact();
    AudioService().playGameSound();

    await _spinController.forward();

    // Generate random result (1-10)
    final result = Random().nextInt(10) + 1;
    setState(() {
      _lastResult = result;
      _isSpinning = false;
    });

    // Determine winner (higher number wins, but 1 beats 10)
    final player1Number = result <= 5 ? result : 11 - result;
    final player2Number = result > 5 ? result - 5 : 6 - result;

    if (player1Number > player2Number || (player1Number == 1 && player2Number == 10)) {
      _player1Score++;
      AudioService().playWinSound();
    } else if (player2Number > player1Number || (player2Number == 1 && player1Number == 10)) {
      _player2Score++;
      AudioService().playWinSound();
    }

    _spinController.reset();

    if (_currentRound >= _maxRounds) {
      _endGame();
    } else {
      setState(() {
        _currentRound++;
      });
    }
  }

  void _endGame() {
    final winner = _player1Score > _player2Score ? 1 : 2;

    final gameSession = ref.read(gameSessionProvider);
    if (gameSession != null) {
      final score = GameScore(
        gameType: 'spinner',
        player1Score: _player1Score,
        player2Score: _player2Score,
        winner: winner,
        gameDuration: gameSession.duration,
      );
      ref.read(scoreRepositoryProvider).saveGameScore(score);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        result: 'Player $winner',
        player1Score: _player1Score,
        player2Score: _player2Score,
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
    setState(() {
      _player1Score = 0;
      _player2Score = 0;
      _currentRound = 1;
      _lastResult = null;
      _isSpinning = false;
    });
    _spinController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Score display
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: AppTheme.surfaceDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerScore('Player 1', _player1Score, AppTheme.player1Color),
              Text(
                'Round $_currentRound/$_maxRounds',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              _buildPlayerScore('Player 2', _player2Score, AppTheme.player2Color),
            ],
          ),
        ),

        // Spinner
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _spin,
              child: AnimatedBuilder(
                animation: _spinAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinAnimation.value * 12 * pi,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                            AppTheme.accentColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Spinner segments
                          for (int i = 0; i < 10; i++)
                            Positioned.fill(
                              child: Transform.rotate(
                                angle: (i * 36) * pi / 180,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Center(
                                    child: Transform.translate(
                                      offset: const Offset(0, -60),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Center circle
                          Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 30,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Result display
        if (_lastResult != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: AppTheme.surfaceDecoration,
            child: Text(
              'Result: $_lastResult',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        // Spin button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isSpinning ? null : _spin,
            icon: Icon(_isSpinning ? Icons.hourglass_empty : Icons.casino),
            label: Text(_isSpinning ? 'Spinning...' : 'SPIN!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScore(String player, int score, Color color) {
    return Column(
      children: [
        Text(
          player,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Tap the Dot Game
class TapDotGame extends ConsumerStatefulWidget {
  const TapDotGame({super.key});

  @override
  ConsumerState<TapDotGame> createState() => _TapDotGameState();
}

class _TapDotGameState extends ConsumerState<TapDotGame>
    with TickerProviderStateMixin {
  int _player1Score = 0;
  int _player2Score = 0;
  late Timer _gameTimer;
  int _timeLeft = 30; // 30 seconds game
  bool _gameActive = false;
  List<DotPosition> _dots = [];
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _dotController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameActive = true;
      _timeLeft = 30;
      _player1Score = 0;
      _player2Score = 0;
      _dots.clear();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          _generateRandomDots();
        });
      } else {
        _endGame();
      }
    });
  }

  void _generateRandomDots() {
    final random = Random();

    // Remove old dots
    _dots.removeWhere((dot) =>
    DateTime.now().difference(dot.createdAt).inSeconds > 2);

    // Add new dots
    if (_dots.length < 3 && random.nextBool()) {
      _dots.add(DotPosition(
        x: random.nextDouble() * 0.8 + 0.1,
        y: random.nextDouble() * 0.6 + 0.2,
        player: random.nextInt(2) + 1,
        createdAt: DateTime.now(),
      ));
    }
  }

  void _tapDot(DotPosition dot) {
    if (!_gameActive) return;

    HapticFeedback.lightImpact();
    AudioService().playClickSound();

    setState(() {
      if (dot.player == 1) {
        _player1Score++;
      } else {
        _player2Score++;
      }
      _dots.remove(dot);
    });

    _dotController.forward().then((_) => _dotController.reverse());
  }

  void _endGame() {
    _gameTimer.cancel();
    setState(() {
      _gameActive = false;
    });

    final winner = _player1Score > _player2Score
        ? 1
        : (_player2Score > _player1Score ? 2 : 0);

    final gameSession = ref.read(gameSessionProvider);
    if (gameSession != null) {
      final score = GameScore(
        gameType: 'tapdot',
        player1Score: _player1Score,
        player2Score: _player2Score,
        winner: winner,
        gameDuration: gameSession.duration,
      );
      ref.read(scoreRepositoryProvider).saveGameScore(score);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        result: winner == 0 ? 'Draw' : 'Player $winner',
        player1Score: _player1Score,
        player2Score: _player2Score,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _startGame();
        },
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timer and scores
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: AppTheme.surfaceDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerScore('Player 1', _player1Score, AppTheme.player1Color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft <= 5 ? Colors.red.withOpacity(0.2) : AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _timeLeft <= 5 ? Colors.red : AppTheme.accentColor,
                  ),
                ),
                child: Text(
                  '$_timeLeft',
                  style: TextStyle(
                    color: _timeLeft <= 5 ? Colors.red : AppTheme.accentColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPlayerScore('Player 2', _player2Score, AppTheme.player2Color),
            ],
          ),
        ),

        // Game area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: AppTheme.surfaceDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background gradient
                  Container(
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
                  ),
                  // Dots
                  ...(_dots.map((dot) => _buildDot(dot))),
                  // Instructions
                  if (!_gameActive && _timeLeft == 30)
                    const Center(
                      child: Text(
                        'Tap dots of your color!\nPlayer 1: Blue dots\nPlayer 2: Red dots',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Start/Reset button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _gameActive ? null : _startGame,
            icon: const Icon(Icons.play_arrow),
            label: Text(_gameActive ? 'Game Active' : 'Start Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(DotPosition dot) {
    final size = MediaQuery.of(context).size;
    final color = dot.player == 1 ? AppTheme.player1Color : AppTheme.player2Color;

    return Positioned(
      left: dot.x * (size.width - 100),
      top: dot.y * (size.height - 200),
      child: GestureDetector(
        onTap: () => _tapDot(dot),
        child: AnimatedBuilder(
          animation: _dotController,
          builder: (context, child) {
            final scale = DateTime.now().difference(dot.createdAt).inMilliseconds < 100
                ? 1.0 + _dotController.value * 0.3
                : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${dot.player}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String player, int score, Color color) {
    return Column(
      children: [
        Text(
          player,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class DotPosition {
  final double x;
  final double y;
  final int player;
  final DateTime createdAt;

  DotPosition({
    required this.x,
    required this.y,
    required this.player,
    required this.createdAt,
  });
}

// Additional game stubs for missing games
class PingPongGame extends StatelessWidget {
  const PingPongGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonWidget(gameName: 'Ping Pong');
  }
}

class AirHockeyGame extends StatelessWidget {
  const AirHockeyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonWidget(gameName: 'Air Hockey');
  }
}

class WordPuzzleGame extends StatelessWidget {
  const WordPuzzleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonWidget(gameName: 'Word Puzzle');
  }
}

class ComingSoonWidget extends StatelessWidget {
  final String gameName;

  const ComingSoonWidget({super.key, required this.gameName});

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
            '$gameName\nComing Soon!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
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
            ),
          ),
        ],
      ),
    );
  }
}
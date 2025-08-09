import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_service.dart';
import '../../data/models/game_score.dart';
import '../providers/game_provider.dart';
import '../screens/game_result_dilog.dart';

class TicTacToeGame extends ConsumerStatefulWidget {
  const TicTacToeGame({super.key});

  @override
  ConsumerState<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends ConsumerState<TicTacToeGame>
    with TickerProviderStateMixin {
  late List<String> board;
  late String currentPlayer;
  late int player1Score;
  late int player2Score;
  late List<AnimationController> _cellAnimationControllers;
  late AnimationController _winAnimationController;
  late Animation<double> _winAnimation;
  List<int> _winningLine = [];

  @override
  void initState() {
    super.initState();
    _initGame();
    _initAnimations();
  }

  void _initGame() {
    board = List.filled(9, '');
    currentPlayer = 'X';
    player1Score = 0;
    player2Score = 0;
    _winningLine = [];
  }

  void _initAnimations() {
    _cellAnimationControllers = List.generate(
      9,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _winAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _winAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _winAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    for (final controller in _cellAnimationControllers) {
      controller.dispose();
    }
    _winAnimationController.dispose();
    super.dispose();
  }

  void _makeMove(int index) {
    if (board[index] != '' || _winningLine.isNotEmpty) return;

    setState(() {
      board[index] = currentPlayer;
      currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
    });

    HapticFeedback.lightImpact();
    AudioService().playClickSound();

    _cellAnimationControllers[index].forward();

    _checkGameEnd();
  }

  void _checkGameEnd() {
    final winResult = _getWinner();

    if (winResult['winner'] != null) {
      final winner = winResult['winner'] as String;
      _winningLine = winResult['line'] as List<int>;

      setState(() {
        if (winner == 'X') {
          player1Score++;
        } else {
          player2Score++;
        }
      });

      _winAnimationController.forward();
      AudioService().playWinSound();

      Future.delayed(const Duration(milliseconds: 1500), () {
        _showGameResult(winner);
      });
    } else if (!board.contains('')) {
      AudioService().playLoseSound();
      Future.delayed(const Duration(milliseconds: 500), () {
        _showGameResult('Draw');
      });
    }
  }

  Map<String, dynamic> _getWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (var line in lines) {
      if (board[line[0]] != '' &&
          board[line[0]] == board[line[1]] &&
          board[line[1]] == board[line[2]]) {
        return {'winner': board[line[0]], 'line': line};
      }
    }
    return {'winner': null, 'line': <int>[]};
  }

  void _showGameResult(String result) {
    final winner = result == 'X' ? 1 : (result == 'O' ? 2 : 0);

    if (winner > 0) {
      final gameSession = ref.read(gameSessionProvider);
      if (gameSession != null) {
        final score = GameScore(
          gameType: 'tictactoe',
          player1Score: player1Score,
          player2Score: player2Score,
          winner: winner,
          gameDuration: gameSession.duration,
        );
        ref.read(scoreRepositoryProvider).saveGameScore(score);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        result: result,
        player1Score: player1Score,
        player2Score: player2Score,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _resetBoard();
        },
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _resetBoard() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      _winningLine = [];
    });

    for (final controller in _cellAnimationControllers) {
      controller.reset();
    }
    _winAnimationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final playerNames = ref.watch(playerNamesProvider);

    return Column(
      children: [
        // Score display
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: AppTheme.surfaceDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerScore(
                playerNames['player1'] ?? 'Player 1',
                'X',
                player1Score,
                AppTheme.player1Color,
                currentPlayer == 'X',
              ),
              Container(
                width: 2,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.3),
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              _buildPlayerScore(
                playerNames['player2'] ?? 'Player 2',
                'O',
                player2Score,
                AppTheme.player2Color,
                currentPlayer == 'O',
              ),
            ],
          ),
        ),

        // Current player indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: (currentPlayer == 'X' ? AppTheme.player1Color : AppTheme.player2Color)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentPlayer == 'X' ? AppTheme.player1Color : AppTheme.player2Color,
                width: 2,
              ),
            ),
            child: Text(
              'Current: ${currentPlayer == 'X' ? playerNames['player1'] ?? 'Player 1' : playerNames['player2'] ?? 'Player 2'} ($currentPlayer)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: currentPlayer == 'X' ? AppTheme.player1Color : AppTheme.player2Color,
              ),
            ),
          ),
        ),

        // Game board
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final isWinningCell = _winningLine.contains(index);
                    return GestureDetector(
                      onTap: () => _makeMove(index),
                      child: AnimatedBuilder(
                        animation: _cellAnimationControllers[index],
                        builder: (context, child) {
                          return AnimatedBuilder(
                            animation: _winAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (board[index] != '' ? _cellAnimationControllers[index].value * 0.1 : 0.0) +
                                    (isWinningCell ? _winAnimation.value * 0.2 : 0.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        isWinningCell
                                            ? AppTheme.accentColor.withOpacity(0.3)
                                            : AppTheme.backgroundColor,
                                        isWinningCell
                                            ? AppTheme.accentColor.withOpacity(0.1)
                                            : AppTheme.backgroundColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isWinningCell
                                          ? AppTheme.accentColor
                                          : AppTheme.primaryColor.withOpacity(0.3),
                                      width: isWinningCell ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      board[index],
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: board[index] == 'X'
                                            ? AppTheme.player1Color
                                            : board[index] == 'O'
                                            ? AppTheme.player2Color
                                            : Colors.transparent,
                                        shadows: isWinningCell
                                            ? [
                                          Shadow(
                                            color: AppTheme.accentColor.withOpacity(0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 0),
                                          ),
                                        ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Reset button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _resetBoard,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScore(String playerName, String symbol, int score, Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(
            playerName,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            symbol,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
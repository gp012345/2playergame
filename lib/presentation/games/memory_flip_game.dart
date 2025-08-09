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

class MemoryCard {
  final int id;
  final IconData icon;
  bool isFlipped;
  bool isMatched;
  bool isSelected;

  MemoryCard({
    required this.id,
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
    this.isSelected = false,
  });
}

class MemoryFlipGame extends ConsumerStatefulWidget {
  const MemoryFlipGame({super.key});

  @override
  ConsumerState<MemoryFlipGame> createState() => _MemoryFlipGameState();
}

class _MemoryFlipGameState extends ConsumerState<MemoryFlipGame>
    with TickerProviderStateMixin {
  List<MemoryCard> _cards = [];
  List<MemoryCard> _selectedCards = [];
  int _currentPlayer = 1;
  int _player1Score = 0;
  int _player2Score = 0;
  bool _isProcessing = false;
  Timer? _flipBackTimer;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _matchController;
  late Animation<double> _matchAnimation;

  final List<IconData> _cardIcons = [
    Icons.star, Icons.favorite, Icons.diamond, Icons.circle,
    Icons.square, Icons.change_history, Icons.hexagon, Icons.pentagon,
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeGame();
  }

  void _initAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _matchController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _matchAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _matchController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    _flipController.dispose();
    _matchController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _cards.clear();
    _selectedCards.clear();
    _player1Score = 0;
    _player2Score = 0;
    _currentPlayer = 1;
    _isProcessing = false;

    // Create pairs of cards
    for (int i = 0; i < _cardIcons.length; i++) {
      _cards.add(MemoryCard(id: i * 2, icon: _cardIcons[i]));
      _cards.add(MemoryCard(id: i * 2 + 1, icon: _cardIcons[i]));
    }

    // Shuffle cards
    _cards.shuffle(Random());
    setState(() {});
  }

  void _flipCard(MemoryCard card) {
    if (_isProcessing || card.isMatched || card.isFlipped || _selectedCards.length >= 2) {
      return;
    }

    setState(() {
      card.isFlipped = true;
      card.isSelected = true;
      _selectedCards.add(card);
    });

    HapticFeedback.lightImpact();
    AudioService().playClickSound();
    _flipController.forward().then((_) => _flipController.reverse());

    if (_selectedCards.length == 2) {
      _isProcessing = true;
      _checkForMatch();
    }
  }

  void _checkForMatch() {
    final card1 = _selectedCards[0];
    final card2 = _selectedCards[1];

    if (card1.icon == card2.icon) {
      // Match found!
      AudioService().playWinSound();
      _matchController.forward().then((_) => _matchController.reverse());

      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;

        if (_currentPlayer == 1) {
          _player1Score++;
        } else {
          _player2Score++;
        }
        // Player keeps their turn on a match
      });

      _selectedCards.clear();
      _isProcessing = false;

      // Check if game is complete
      if (_cards.every((card) => card.isMatched)) {
        _endGame();
      }
    } else {
      // No match
      AudioService().playLoseSound();

      _flipBackTimer = Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          card1.isFlipped = false;
          card2.isFlipped = false;
          card1.isSelected = false;
          card2.isSelected = false;
          _currentPlayer = _currentPlayer == 1 ? 2 : 1; // Switch turns
        });

        _selectedCards.clear();
        _isProcessing = false;
      });
    }
  }

  void _endGame() {
    final winner = _player1Score > _player2Score ? 1 : (_player2Score > _player1Score ? 2 : 0);

    final gameSession = ref.read(gameSessionProvider);
    if (gameSession != null) {
      final score = GameScore(
        gameType: 'memory',
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
          _initializeGame();
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
    final playerNames = ref.watch(playerNamesProvider);

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
              _buildPlayerScore(
                playerNames['player1'] ?? 'Player 1',
                _player1Score,
                AppTheme.player1Color,
                _currentPlayer == 1,
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
                _player2Score,
                AppTheme.player2Color,
                _currentPlayer == 2,
              ),
            ],
          ),
        ),

        // Current player indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: (_currentPlayer == 1 ? AppTheme.player1Color : AppTheme.player2Color)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _currentPlayer == 1 ? AppTheme.player1Color : AppTheme.player2Color,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: _currentPlayer == 1 ? AppTheme.player1Color : AppTheme.player2Color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current: ${_currentPlayer == 1 ? playerNames['player1'] ?? 'Player 1' : playerNames['player2'] ?? 'Player 2'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _currentPlayer == 1 ? AppTheme.player1Color : AppTheme.player2Color,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Game board
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _buildCard(card);
              },
            ),
          ),
        ),

        // Game info
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Find matching pairs! ${8 - _player1Score - _player2Score} pairs left',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade300,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Reset button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _initializeGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(MemoryCard card) {
    return GestureDetector(
      onTap: () => _flipCard(card),
      child: // Fix AnimatedBuilder in _buildCard:
      AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          return AnimatedBuilder(
            animation: _matchAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: card.isMatched ? _matchAnimation.value : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _getCardColors(card),
                        ),
                        border: Border.all(
                          color: _getCardBorderColor(card),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: card.isFlipped || card.isMatched
                            ? Icon(
                          card.icon,
                          size: 32,
                          color: Colors.white,
                        )
                            : Icon(
                          Icons.help_outline,
                          size: 32,
                          color: Colors.white.withOpacity(0.3),
                        ),
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
  }

  List<Color> _getCardColors(MemoryCard card) {
    if (card.isMatched) {
      return [
        AppTheme.accentColor,
        AppTheme.accentColor.withOpacity(0.7),
      ];
    } else if (card.isFlipped) {
      return [
        AppTheme.primaryColor,
        AppTheme.primaryColor.withOpacity(0.7),
      ];
    } else {
      return [
        AppTheme.backgroundColor,
        AppTheme.backgroundColor.withOpacity(0.8),
      ];
    }
  }

  Color _getCardBorderColor(MemoryCard card) {
    if (card.isMatched) {
      return AppTheme.accentColor;
    } else if (card.isSelected) {
      return AppTheme.primaryColor;
    } else {
      return AppTheme.primaryColor.withOpacity(0.3);
    }
  }

  Widget _buildPlayerScore(String playerName, int score, Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.memory,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
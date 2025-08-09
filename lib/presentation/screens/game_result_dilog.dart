import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';

class GameResultDialog extends StatelessWidget {
  final String result;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
  final int? player1Score;
  final int? player2Score;

  const GameResultDialog({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onHome,
    this.player1Score,
    this.player2Score,
  });

  @override
  Widget build(BuildContext context) {
    final isWin = result != 'Draw' && result != 'Tie';
    final winner = result == 'X' ? 'Player 1' : (result == 'O' ? 'Player 2' : result);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceColor,
              AppTheme.surfaceColor.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isWin ? AppTheme.accentColor : AppTheme.warningColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation/Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getResultColor().withOpacity(0.2),
              ),
              child: Icon(
                _getResultIcon(),
                size: 50,
                color: _getResultColor(),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _getResultTitle(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getResultColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Winner/Result
            Text(
              winner,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            if (player1Score != null && player2Score != null) ...[
              const SizedBox(height: 16),
              _buildScoreDisplay(),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onHome,
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPlayAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Play Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getResultColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text(
                'Player 1',
                style: TextStyle(
                  color: AppTheme.player1Color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                player1Score.toString(),
                style: const TextStyle(
                  color: AppTheme.player1Color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Column(
            children: [
              const Text(
                'Player 2',
                style: TextStyle(
                  color: AppTheme.player2Color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                player2Score.toString(),
                style: const TextStyle(
                  color: AppTheme.player2Color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getResultColor() {
    if (result == 'Draw' || result == 'Tie') return AppTheme.warningColor;
    if (result == 'X' || result == 'Player 1') return AppTheme.player1Color;
    if (result == 'O' || result == 'Player 2') return AppTheme.player2Color;
    return AppTheme.accentColor;
  }

  IconData _getResultIcon() {
    if (result == 'Draw' || result == 'Tie') return Icons.handshake;
    return Icons.emoji_events;
  }

  String _getResultTitle() {
    if (result == 'Draw' || result == 'Tie') return 'It\'s a Draw!';
    return 'Winner!';
  }
}
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/game_score.dart';

class ScoreCard extends StatelessWidget {
  final GameScore score;

  const ScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration.copyWith(
        border: Border.all(
          color: _getWinnerColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game title and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                score.gameTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatTimestamp(score.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Winner indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getWinnerColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getWinnerColor()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWinnerIcon(),
                      color: _getWinnerColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      score.winnerName,
                      style: TextStyle(
                        color: _getWinnerColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (score.gameDuration > 0)
                Text(
                  score.formattedDuration,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Score display
          Row(
            children: [
              Expanded(
                child: _buildPlayerScore(
                  'Player 1',
                  score.player1Score,
                  AppTheme.player1Color,
                  score.winner == 1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerScore(
                  'Player 2',
                  score.player2Score,
                  AppTheme.player2Color,
                  score.winner == 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String player, int playerScore, Color color, bool isWinner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          player,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWinner) ...[
              Icon(
                Icons.star,
                color: AppTheme.accentColor,
                size: 16,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              playerScore.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getWinnerColor() {
    switch (score.winner) {
      case 1:
        return AppTheme.player1Color;
      case 2:
        return AppTheme.player2Color;
      default:
        return AppTheme.warningColor;
    }
  }

  IconData _getWinnerIcon() {
    switch (score.winner) {
      case 1:
      case 2:
        return Icons.emoji_events;
      default:
        return Icons.handshake;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
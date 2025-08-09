import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatsWidget extends StatelessWidget {
  final String title;
  final Map<String, int> stats;

  const StatsWidget({
    super.key,
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.surfaceDecoration,
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final totalValue = stats.values.fold<int>(0, (sum, value) => sum + value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.surfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (title.contains('Performance') || title.contains('Wins'))
            _buildPerformanceStats(totalValue)
          else
            _buildGameStats(totalValue),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats(int totalValue) {
    return Column(
      children: [
        // Player 1 vs Player 2 performance
        _buildStatBar(
          'Player 1',
          stats['player1'] ?? 0,
          totalValue,
          AppTheme.player1Color,
        ),
        const SizedBox(height: 8),
        _buildStatBar(
          'Player 2',
          stats['player2'] ?? 0,
          totalValue,
          AppTheme.player2Color,
        ),
        if ((stats['draws'] ?? 0) > 0) ...[
          const SizedBox(height: 8),
          _buildStatBar(
            'Draws',
            stats['draws'] ?? 0,
            totalValue,
            AppTheme.warningColor,
          ),
        ],
        const SizedBox(height: 16),
        _buildSummaryRow(totalValue),
      ],
    );
  }

  Widget _buildGameStats(int totalValue) {
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        ...sortedEntries.take(5).map((entry) {
          final gameTitle = _getGameTitle(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildStatBar(
              gameTitle,
              entry.value,
              totalValue,
              AppTheme.primaryColor,
            ),
          );
        }),
        if (sortedEntries.length > 5) ...[
          const SizedBox(height: 8),
          Text(
            'And ${sortedEntries.length - 5} more games...',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildSummaryRow(totalValue),
      ],
    );
  }

  Widget _buildStatBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    final progress = total > 0 ? value / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$value ($percentage%)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade700,
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(int totalValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Total: $totalValue',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    return titles[gameType] ?? gameType;
  }
}
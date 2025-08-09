import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/score_card.dart';
import '../widgets/stats_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_service.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentScores = ref.watch(recentScoresProvider);
    final playerWinCounts = ref.watch(playerWinCountsProvider);
    final cupScores = ref.watch(cupScoresProvider);
    final gameStats = ref.watch(gameStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scores & Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _showClearDataDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Recent', icon: Icon(Icons.history)),
            Tab(text: 'Stats', icon: Icon(Icons.analytics)),
            Tab(text: 'Cup', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Recent Games Tab
          _buildRecentGamesTab(recentScores),

          // Statistics Tab
          _buildStatsTab(gameStats, playerWinCounts),

          // Cup Standings Tab
          _buildCupTab(cupScores, playerWinCounts),
        ],
      ),
    );
  }

  Widget _buildRecentGamesTab(List scores) {
    if (scores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No games played yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start playing to see your game history!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ScoreCard(score: score),
        );
      },
    );
  }

  Widget _buildStatsTab(Map<String, int> gameStats, Map<String, int> playerWinCounts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatsWidget(
            title: 'Overall Performance',
            stats: playerWinCounts,
          ),
          const SizedBox(height: 16),
          StatsWidget(
            title: 'Games Played',
            stats: gameStats,
          ),
          const SizedBox(height: 16),
          _buildDetailedStats(playerWinCounts),
        ],
      ),
    );
  }

  Widget _buildCupTab(Map<String, int> cupScores, Map<String, int> playerWinCounts) {
    final player1Score = cupScores['player1'] ?? 0;
    final player2Score = cupScores['player2'] ?? 0;
    final totalGames = player1Score + player2Score;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cup Trophy
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.surfaceDecoration,
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: player1Score > player2Score
                      ? AppTheme.player1Color
                      : player2Score > player1Score
                      ? AppTheme.player2Color
                      : AppTheme.accentColor,
                ),
                const SizedBox(height: 16),
                Text(
                  totalGames == 0
                      ? 'No Champion Yet'
                      : player1Score > player2Score
                      ? 'Player 1 Leads!'
                      : player2Score > player1Score
                      ? 'Player 2 Leads!'
                      : 'It\'s a Tie!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (totalGames > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Total Cup Games: $totalGames',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cup Progress
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.surfaceDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cup Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProgressBar(player1Score, player2Score, totalGames),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCupPlayerStats('Player 1', player1Score, AppTheme.player1Color),
                    _buildCupPlayerStats('Player 2', player2Score, AppTheme.player2Color),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reset Cup Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: totalGames > 0 ? () => _showResetCupDialog(context) : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Cup Scores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int player1Score, int player2Score, int totalGames) {
    if (totalGames == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final player1Percentage = player1Score / totalGames;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.shade600,
      ),
      child: Row(
        children: [
          Expanded(
            flex: (player1Percentage * 100).round(),
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.player1Color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          Expanded(
            flex: ((1 - player1Percentage) * 100).round(),
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.player2Color,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupPlayerStats(String playerName, int score, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.person, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          playerName,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(Map<String, int> playerWinCounts) {
    final totalGames = (playerWinCounts['player1'] ?? 0) +
        (playerWinCounts['player2'] ?? 0) +
        (playerWinCounts['draws'] ?? 0);

    if (totalGames == 0) {
      return const SizedBox.shrink();
    }

    final player1Percentage = ((playerWinCounts['player1'] ?? 0) / totalGames * 100).round();
    final player2Percentage = ((playerWinCounts['player2'] ?? 0) / totalGames * 100).round();
    final drawPercentage = ((playerWinCounts['draws'] ?? 0) / totalGames * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.surfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Games Played', totalGames.toString()),
          _buildStatRow('Player 1 Wins', '${playerWinCounts['player1']} ($player1Percentage%)'),
          _buildStatRow('Player 2 Wins', '${playerWinCounts['player2']} ($player2Percentage%)'),
          _buildStatRow('Draws', '${playerWinCounts['draws']} ($drawPercentage%)'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade300),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Clear All Data', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all scores and statistics. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(scoreRepositoryProvider).clearAllScores();
              Navigator.pop(context);
              AudioService().playClickSound();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetCupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Reset Cup Scores', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will reset the cup scores to 0-0. Game history will be preserved.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(scoreRepositoryProvider).resetCupScores();
              Navigator.pop(context);
              AudioService().playClickSound();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cup scores reset')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
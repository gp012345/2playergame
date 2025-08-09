import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_provider.dart';
import '../widgets/cup_score_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_service.dart';
import '../widgets/game_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize audio service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final gameList = [
    {'name': 'Tic Tac Toe', 'icon': Icons.grid_3x3, 'type': 'tictactoe'},
    {'name': 'Ping Pong', 'icon': Icons.sports_tennis, 'type': 'pingpong'},
    {'name': 'Spinner War', 'icon': Icons.casino, 'type': 'spinner'},
    {'name': 'Air Hockey', 'icon': Icons.sports_hockey, 'type': 'airhockey'},
    {'name': 'Snakes', 'icon': Icons.pets, 'type': 'snakes'},
    {'name': 'Pool', 'icon': Icons.sports_baseball, 'type': 'pool'},
    {'name': 'Penalty Kicks', 'icon': Icons.sports_soccer, 'type': 'penalty'},
    {'name': 'Sumo', 'icon': Icons.person, 'type': 'sumo'},
    {'name': 'Chess', 'icon': Icons.check, 'type': 'chess'},
    {'name': 'Mini Golf', 'icon': Icons.sports_golf, 'type': 'golf'},
    {'name': 'Racing Cars', 'icon': Icons.directions_car, 'type': 'racing'},
    {'name': 'Sword Duels', 'icon': Icons.sports_martial_arts, 'type': 'sword'},
    {'name': 'Reaction Time', 'icon': Icons.timer, 'type': 'reaction'},
    {'name': 'Memory Flip', 'icon': Icons.memory, 'type': 'memory'},
    {'name': 'Speed Typing', 'icon': Icons.keyboard, 'type': 'typing'},
    {'name': 'Trivia Quiz', 'icon': Icons.quiz, 'type': 'trivia'},
    {'name': 'Tap the Dot', 'icon': Icons.touch_app, 'type': 'tapdot'},
    {'name': 'Word Puzzle', 'icon': Icons.text_fields, 'type': 'wordpuzzle'},
  ];

  @override
  Widget build(BuildContext context) {
    final cupScores = ref.watch(cupScoresProvider);
    final playerNames = ref.watch(playerNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '2 Player Games Challenge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              AudioService().playClickSound();
              context.push('/scores');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AudioService().playClickSound();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            CupScoreWidget(
              player1Name: playerNames['player1'] ?? 'Player 1',
              player2Name: playerNames['player2'] ?? 'Player 2',
              player1Score: cupScores['player1'] ?? 0,
              player2Score: cupScores['player2'] ?? 0,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: gameList.length,
                  itemBuilder: (context, index) {
                    final game = gameList[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      curve: Curves.easeOutBack,
                      child: GameTile(
                        title: game['name'] as String,
                        icon: game['icon'] as IconData,
                        onTap: () => context.push('/game/${game['type']}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
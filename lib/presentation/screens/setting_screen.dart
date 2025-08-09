import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _player1Controller.text = settings['player1Name'] ?? 'Player 1';
      _player2Controller.text = settings['player2Name'] ?? 'Player 2';
    });
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Names Section
            _buildSectionCard(
              'Player Names',
              Icons.people,
              [
                _buildPlayerNameField(
                  'Player 1 Name',
                  _player1Controller,
                  AppTheme.player1Color,
                      (name) => ref.read(settingsProvider.notifier).setPlayerName(1, name),
                ),
                const SizedBox(height: 16),
                _buildPlayerNameField(
                  'Player 2 Name',
                  _player2Controller,
                  AppTheme.player2Color,
                      (name) => ref.read(settingsProvider.notifier).setPlayerName(2, name),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Audio Settings Section
            _buildSectionCard(
              'Audio Settings',
              Icons.volume_up,
              [
                _buildSwitchTile(
                  'Sound Effects',
                  'Play sound effects during games',
                  Icons.music_note,
                  settings['soundEnabled'] ?? true,
                      (value) async {
                    await ref.read(settingsProvider.notifier).updateSetting('soundEnabled', value);
                    if (value) await audioService.toggleSound();
                  },
                ),
                _buildSwitchTile(
                  'Background Music',
                  'Play background music',
                  Icons.library_music,
                  settings['musicEnabled'] ?? true,
                      (value) async {
                    await ref.read(settingsProvider.notifier).updateSetting('musicEnabled', value);
                    await audioService.toggleMusic();
                  },
                ),
                _buildSwitchTile(
                  'Vibration',
                  'Haptic feedback on interactions',
                  Icons.vibration,
                  settings['vibrationEnabled'] ?? true,
                      (value) => ref.read(settingsProvider.notifier).updateSetting('vibrationEnabled', value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Game Settings Section
            _buildSectionCard(
              'Game Settings',
              Icons.gamepad,
              [
                _buildInfoTile(
                  'Game Difficulty',
                  'Balanced for all skill levels',
                  Icons.trending_up,
                ),
                _buildInfoTile(
                  'Auto-save',
                  'Scores are automatically saved',
                  Icons.save,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // About Section
            _buildSectionCard(
              'About',
              Icons.info,
              [
                _buildInfoTile(
                  'Version',
                  '1.0.0',
                  Icons.tag,
                ),
                _buildInfoTile(
                  'Total Games',
                  '18 mini-games included',
                  Icons.games,
                ),
                _buildActionTile(
                  'Reset All Settings',
                  'Restore default settings',
                  Icons.restore,
                      () => _showResetSettingsDialog(),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Credits
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.surfaceDecoration,
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppTheme.secondaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2 Player Games Challenge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built with Flutter & Love',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.surfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlayerNameField(
      String label,
      TextEditingController controller,
      Color color,
      Function(String) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter player name',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            prefixIcon: Icon(Icons.person, color: color),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onChanged(value.trim());
              AudioService().playClickSound();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label updated to: ${value.trim()}'),
                  backgroundColor: color,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          onChanged(newValue);
          AudioService().playClickSound();
        },
        activeColor: AppTheme.accentColor,
        activeTrackColor: AppTheme.accentColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    );
  }

  Widget _buildActionTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.warningColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () {
        AudioService().playClickSound();
        onTap();
      },
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Reset Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will restore all settings to their default values. Player names will be reset to "Player 1" and "Player 2".',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Reset all settings
              await ref.read(settingsProvider.notifier).updateSetting('soundEnabled', true);
              await ref.read(settingsProvider.notifier).updateSetting('musicEnabled', true);
              await ref.read(settingsProvider.notifier).updateSetting('vibrationEnabled', true);
              await ref.read(settingsProvider.notifier).setPlayerName(1, 'Player 1');
              await ref.read(settingsProvider.notifier).setPlayerName(2, 'Player 2');

              // Update text controllers
              _player1Controller.text = 'Player 1';
              _player2Controller.text = 'Player 2';

              Navigator.pop(context);
              AudioService().playClickSound();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
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
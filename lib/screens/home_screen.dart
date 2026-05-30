// =============================================================================
// HomeScreen
// The first thing the player sees. Shows the game logo, current high score,
// games played, and a big glowing PLAY button. Pure UI — no game logic.
// =============================================================================

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();

  // A slow breathing animation drives the glow on the title and the play button.
  late final AnimationController _pulse;

  int _highScore = 0;
  int _gamesPlayed = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _loadStats();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final hs = await _storage.getHighScore();
    final gp = await _storage.getGamesPlayed();
    if (!mounted) return;
    setState(() {
      _highScore = hs;
      _gamesPlayed = gp;
    });
  }

  void _startGame() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    )
        .then((_) {
      // When the user returns to the home screen, refresh stats — they may have
      // set a new high score on the previous run.
      _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A vertical gradient background gives depth without needing images.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgDark, AppTheme.bgDarker],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildStatsRow(),
                const Spacer(flex: 2),
                _buildPlayButton(),
                const SizedBox(height: 24),
                _buildHowToPlay(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logo: stacked ShaderMask gradients for the "NEON / DRIFT / MINI" lockup.
  // ---------------------------------------------------------------------------
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        // Pulse value oscillates 0..1; we use it to brighten the glow.
        final glow = 0.5 + _pulse.value * 0.5;
        return Column(
          children: [
            // "NEON" — pink/purple/cyan gradient with a soft glow halo.
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [
                  AppTheme.neonPink,
                  AppTheme.neonPurple,
                  AppTheme.neonCyan,
                ],
              ).createShader(rect),
              child: Text(
                'NEON',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppTheme.neonPink.withValues(alpha: glow * 0.8),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
            ),
            // "DRIFT" — cyan/green gradient, slightly smaller.
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [AppTheme.neonCyan, AppTheme.neonGreen],
              ).createShader(rect),
              child: Text(
                'DRIFT',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppTheme.neonCyan.withValues(alpha: glow * 0.8),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // "MINI" badge — small yellow pill underneath.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neonYellow.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Text(
                'MINI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: AppTheme.neonYellow,
                  shadows: [
                    Shadow(
                      color: AppTheme.neonYellow.withValues(alpha: glow),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18), // adds vertical space
            Text(
              'Licensed by @TharinduX.exe',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
                color: AppTheme.neonCyan.withValues(alpha: 0.75), // soft cyan
                shadows: [
                  Shadow(
                    color: AppTheme.neonCyan.withValues(alpha: glow * 0.6),
                    blurRadius: 10, // gives it a subtle glow
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Stats row: high score + games played side by side.
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'HIGH SCORE',
            value: _highScore.toString(),
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            label: 'GAMES',
            value: _gamesPlayed.toString(),
            color: AppTheme.neonPink,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Big play button with a pink-purple gradient and pulsing glow.
  // ---------------------------------------------------------------------------
  Widget _buildPlayButton() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.4 + _pulse.value * 0.6;
        return GestureDetector(
          onTap: _startGame,
          child: Container(
            width: double.infinity,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.neonPink, AppTheme.neonPurple],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPink.withValues(alpha: glow * 0.7),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'PLAY',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowToPlay() {
    return Text(
      'Tap left / right or swipe to switch lanes',
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }
}

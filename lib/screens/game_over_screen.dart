// =============================================================================
// GameOverScreen
// Shown after the player crashes. Displays the run summary, a "new high score"
// badge when applicable, and Retry / Home buttons.
//
// All stats are passed in as parameters — this screen does no I/O itself.
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int coinsCollected;
  final int level;
  final int highScore;
  final bool isNewHighScore;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.coinsCollected,
    required this.level,
    required this.highScore,
    required this.isNewHighScore,
  });

  void _retry(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                const Spacer(),
                if (isNewHighScore) _buildNewHighBadge(),
                if (isNewHighScore) const SizedBox(height: 14),
                _buildTitle(),
                const SizedBox(height: 28),
                _buildScoreBlock(),
                const SizedBox(height: 18),
                _buildMiniStats(),
                const Spacer(),
                _buildRetryButton(context),
                const SizedBox(height: 14),
                _buildHomeButton(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "NEW HIGH SCORE" badge — only visible when isNewHighScore is true.
  // ---------------------------------------------------------------------------
  Widget _buildNewHighBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neonYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.neonYellow.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonYellow.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        '⭐ NEW HIGH SCORE!',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: AppTheme.neonYellow,
          shadows: [
            Shadow(
              color: AppTheme.neonYellow.withValues(alpha: 0.8),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GAME OVER title with pink-purple gradient.
  // ---------------------------------------------------------------------------
  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [AppTheme.neonPink, AppTheme.neonPurple],
      ).createShader(rect),
      child: const Text(
        'GAME OVER',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          color: Colors.white,
          shadows: [
            Shadow(color: AppTheme.neonPink, blurRadius: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Big score block with current run + best.
  // ---------------------------------------------------------------------------
  Widget _buildScoreBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'YOUR SCORE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppTheme.neonCyan.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
          Text(
            'BEST: $highScore',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Level + coins side by side.
  // ---------------------------------------------------------------------------
  Widget _buildMiniStats() {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            label: 'LEVEL',
            value: level.toString(),
            color: AppTheme.neonPink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniStat(
            label: 'COINS',
            value: coinsCollected.toString(),
            color: AppTheme.neonYellow,
          ),
        ),
      ],
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: color.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons.
  // ---------------------------------------------------------------------------
  Widget _buildRetryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _retry(context),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.neonPink, AppTheme.neonPurple],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPink.withValues(alpha: 0.55),
              blurRadius: 26,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'RETRY',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _goHome(context),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'HOME',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppTheme.neonCyan.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

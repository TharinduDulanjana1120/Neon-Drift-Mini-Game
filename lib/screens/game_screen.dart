// =============================================================================
// GameScreen
// Hosts the gameplay: creates a GameController, drives it with a Ticker,
// renders the world via GamePainter, and exposes touch + swipe controls.
//
// Lifecycle:
//   initState  -> create controller + ticker, start game after first frame
//   _onTick    -> compute dt (clamped) and tell controller to update
//   game over  -> stop ticker, persist stats, navigate to GameOverScreen
//   dispose    -> tear down ticker and controller
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/game_controller.dart';
import '../game/game_painter.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameController _controller;
  late final Ticker _ticker;
  final StorageService _storage = StorageService();

  /// Timestamp of the previous tick, used to compute dt.
  Duration? _lastTick;

  /// Latch so we only run the game-over flow once.
  bool _gameOverHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController()..addListener(_onControllerUpdate);
    _ticker = createTicker(_onTick);

    // Start the game after the first frame, so the canvas size has been
    // measured and passed to the controller via the painter widget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startGame();
      _ticker.start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tick: compute dt in seconds, clamp to avoid huge jumps after backgrounding,
  // then advance the simulation.
  // ---------------------------------------------------------------------------
  void _onTick(Duration elapsed) {
    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }
    final dtSeconds =
        (elapsed - _lastTick!).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;

    // Cap dt at 50ms so a long pause doesn't teleport obstacles into the player.
    final dt = dtSeconds.clamp(0.0, 0.05);
    _controller.update(dt);
  }

  void _onControllerUpdate() {
    if (_controller.state == GameState.gameOver && !_gameOverHandled) {
      _gameOverHandled = true;
      _handleGameOver();
    }
  }

  Future<void> _handleGameOver() async {
    _ticker.stop();
    HapticFeedback.heavyImpact();

    final score = _controller.score;
    final coins = _controller.coinsCollected;
    final level = _controller.level;

    // Persist stats in parallel.
    final isNewHigh = await _storage.saveHighScore(score);
    await _storage.saveBestLevel(level);
    await _storage.incrementGamesPlayed();
    final highScore = await _storage.getHighScore();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          score: score,
          coinsCollected: coins,
          level: level,
          highScore: highScore,
          isNewHighScore: isNewHigh,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input handlers — buttons trigger these directly; swipe is detected by the
  // surrounding GestureDetector and routed here as well.
  // ---------------------------------------------------------------------------
  void _moveLeft() {
    HapticFeedback.lightImpact();
    _controller.moveLeft();
  }

  void _moveRight() {
    HapticFeedback.lightImpact();
    _controller.moveRight();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarker,
      body: GestureDetector(
        // Horizontal flicks switch lanes.
        onHorizontalDragEnd: (details) {
          final vx = details.primaryVelocity ?? 0;
          if (vx < -100) _moveLeft();
          if (vx > 100) _moveRight();
        },
        child: SafeArea(
          child: Stack(
            children: [
              // The actual game canvas fills the screen behind the HUD.
              Positioned.fill(child: _GameCanvas(controller: _controller)),

              // Top HUD: score, level, coins.
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: _buildHud(),
              ),

              // Bottom controls: left + right buttons.
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: _buildControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HUD widgets.
  // ---------------------------------------------------------------------------
  Widget _buildHud() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _hudPill(
            label: 'SCORE',
            value: _controller.score.toString(),
            color: AppTheme.neonCyan,
          ),
          _hudPill(
            label: 'LV',
            value: _controller.level.toString(),
            color: AppTheme.neonPink,
          ),
          _hudPill(
            label: 'COINS',
            value: _controller.coinsCollected.toString(),
            color: AppTheme.neonYellow,
          ),
        ],
      ),
    );
  }

  Widget _hudPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom control buttons.
  // ---------------------------------------------------------------------------
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _controlButton(
          icon: Icons.arrow_back_ios_new_rounded,
          color: AppTheme.neonCyan,
          onTap: _moveLeft,
        ),
        _controlButton(
          icon: Icons.arrow_forward_ios_rounded,
          color: AppTheme.neonPink,
          onTap: _moveRight,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(color: color.withValues(alpha: 0.75), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}

// =============================================================================
// _GameCanvas
// Thin wrapper around CustomPaint that measures itself and pushes the size
// back into the GameController whenever it changes. Using LayoutBuilder lets
// the painter compute lane positions in real pixels.
// =============================================================================
class _GameCanvas extends StatelessWidget {
  final GameController controller;
  const _GameCanvas({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Push the latest canvas size into the controller after the frame so
        // we don't trigger a rebuild during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.canvasSize != size) {
            controller.setCanvasSize(size);
          }
        });
        return CustomPaint(
          painter: GamePainter(controller),
          size: size,
        );
      },
    );
  }
}

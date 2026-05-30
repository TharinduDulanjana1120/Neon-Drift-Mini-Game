// =============================================================================
// GameController
// Owns the entire game state, the update loop, spawning logic, and collision
// detection. Extends ChangeNotifier so the painter and HUD can listen.
//
// IMPORTANT:
//   - update() must be called every frame with `dt` (seconds since last frame).
//   - All physics use real-world time, so the game feels identical at 60Hz,
//     90Hz and 120Hz.
// =============================================================================

import 'dart:math';

import 'package:flutter/material.dart';

import 'game_objects.dart';

/// Top-level state machine for the game flow.
enum GameState { ready, playing, gameOver }

class GameController extends ChangeNotifier {
  // ------------------------------------------------------------------
  // World constants — tweak to taste.
  // ------------------------------------------------------------------

  /// Number of lanes on the road.
  static const int laneCount = 3;

  /// Fraction of screen width occupied by the road (rest is sidewalk).
  static const double roadWidthFraction = 0.86;

  /// Player starting speed (pixels/second). Speeds up over time.
  static const double baseSpeed = 280.0;

  /// Hard speed cap.
  static const double maxSpeed = 720.0;

  /// How fast the world accelerates (px/s per second of elapsed time).
  static const double acceleration = 6.0;

  /// Snappiness of lane-change easing (higher = faster snap, lower = floatier).
  static const double laneEaseRate = 18.0;

  // ------------------------------------------------------------------
  // Runtime state.
  // ------------------------------------------------------------------

  /// Canvas size in logical pixels. Set by the painter each frame.
  Size canvasSize = Size.zero;

  GameState state = GameState.ready;

  int score = 0;
  int level = 1;
  int coinsCollected = 0;
  double elapsedTime = 0.0;

  /// Current world scroll speed in pixels/second.
  double speed = baseSpeed;

  /// Offset used to animate the scrolling dashed lane dividers.
  double scrollOffset = 0.0;

  /// The player car. Created here so it always exists, even before startGame().
  late PlayerCar player = _makePlayer();

  /// Active obstacles and coins on screen.
  final List<Obstacle> obstacles = <Obstacle>[];
  final List<Coin> coins = <Coin>[];

  // ------------------------------------------------------------------
  // Spawn timers.
  // ------------------------------------------------------------------

  double _obstacleSpawnTimer = 0.0;
  double _coinSpawnTimer = 0.0;
  double _obstacleSpawnInterval = 1.4;
  double _coinSpawnInterval = 1.0;

  final Random _rng = Random();

  // ------------------------------------------------------------------
  // Public API.
  // ------------------------------------------------------------------

  /// Returns normalized X positions for each lane's center.
  /// e.g. for 3 lanes: ~[0.21, 0.50, 0.79].
  List<double> laneCenters() {
    final laneFraction = roadWidthFraction / laneCount;
    final start = (1 - roadWidthFraction) / 2;
    return List<double>.generate(
      laneCount,
      (i) => start + laneFraction * (i + 0.5),
    );
  }

  /// Called by the painter / canvas every layout pass.
  /// Updates the world canvas size and keeps the player anchored to the bottom.
  void setCanvasSize(Size size) {
    canvasSize = size;
    final lanes = laneCenters();
    player.x = lanes[player.lane.clamp(0, laneCount - 1)];
    player.y = size.height - player.height - 60;
  }

  /// (Re)starts a fresh run.
  void startGame() {
    state = GameState.playing;
    score = 0;
    level = 1;
    coinsCollected = 0;
    elapsedTime = 0.0;
    speed = baseSpeed;
    scrollOffset = 0.0;

    obstacles.clear();
    coins.clear();

    _obstacleSpawnTimer = 0.6;
    _coinSpawnTimer = 0.3;
    _obstacleSpawnInterval = 1.4;
    _coinSpawnInterval = 1.0;

    player = _makePlayer();
    if (canvasSize != Size.zero) {
      setCanvasSize(canvasSize);
    }
    notifyListeners();
  }

  /// Move the player one lane to the left (no-op at the leftmost lane).
  void moveLeft() {
    if (state != GameState.playing) return;
    if (player.lane > 0) player.lane--;
  }

  /// Move the player one lane to the right (no-op at the rightmost lane).
  void moveRight() {
    if (state != GameState.playing) return;
    if (player.lane < laneCount - 1) player.lane++;
  }

  /// Main per-frame update. [dt] is the time in seconds since the last frame.
  void update(double dt) {
    if (state != GameState.playing) return;
    if (canvasSize == Size.zero) return;

    elapsedTime += dt;

    // Scrolling background offset (loops every 80 px to keep it tiny).
    scrollOffset = (scrollOffset + speed * dt) % 80.0;

    // ---- Difficulty progression ----
    final newLevel = 1 + (score ~/ 500);
    if (newLevel != level) {
      level = newLevel;
      _obstacleSpawnInterval = max(0.55, 1.4 - (level - 1) * 0.08);
      _coinSpawnInterval = max(0.5, 1.0 - (level - 1) * 0.04);
    }

    // Smooth speed ramp.
    speed = min(maxSpeed, baseSpeed + elapsedTime * acceleration);

    // ---- Survival score (~60 pts/sec) ----
    score += (dt * 60).round();

    // ---- Smooth lane change easing ----
    // Frame-rate-independent exponential decay toward the target lane.
    final lanes = laneCenters();
    final targetX = lanes[player.lane];
    final t = 1.0 - exp(-laneEaseRate * dt);
    player.x = player.x + (targetX - player.x) * t;

    // ---- Move obstacles ----
    for (final o in obstacles) {
      o.y += speed * dt;
      if (o.y > canvasSize.height + 100) o.alive = false;
    }
    obstacles.removeWhere((o) => !o.alive);

    // ---- Move coins (and animate their pulse) ----
    for (final c in coins) {
      c.y += speed * dt;
      c.phase += dt * 6.0;
      if (c.y > canvasSize.height + 60) c.alive = false;
    }
    coins.removeWhere((c) => !c.alive);

    // ---- Spawn new objects ----
    _obstacleSpawnTimer -= dt;
    if (_obstacleSpawnTimer <= 0) {
      _spawnObstacle();
      _obstacleSpawnTimer = _obstacleSpawnInterval *
          (0.85 + _rng.nextDouble() * 0.4); // ±20% jitter
    }
    _coinSpawnTimer -= dt;
    if (_coinSpawnTimer <= 0) {
      _spawnCoin();
      _coinSpawnTimer = _coinSpawnInterval *
          (0.7 + _rng.nextDouble() * 0.8); // ±30% jitter
    }

    // ---- Collision detection ----
    final playerRect = player.getRect(canvasSize);

    for (final o in obstacles) {
      // Slightly forgiving hitbox so brushing-past doesn't kill you.
      if (playerRect.overlaps(o.getRect(canvasSize).deflate(4))) {
        _gameOver();
        return;
      }
    }
    for (final c in coins) {
      if (playerRect.overlaps(c.getRect(canvasSize))) {
        c.alive = false;
        coinsCollected++;
        score += 50;
      }
    }
    coins.removeWhere((c) => !c.alive);

    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Internal helpers.
  // ------------------------------------------------------------------

  PlayerCar _makePlayer() {
    return PlayerCar(
      x: 0.5,
      y: 0,
      width: 54,
      height: 88,
      lane: 1, // start in the middle lane
    );
  }

  void _spawnObstacle() {
    final lanes = laneCenters();

    // Always leave at least one lane open so the player can dodge.
    // From level 2 onward there's an 18% chance of a double-spawn.
    final spawnCount = (_rng.nextDouble() < 0.18 && level >= 2) ? 2 : 1;
    final usedLanes = <int>{};

    for (int i = 0; i < spawnCount; i++) {
      if (usedLanes.length >= laneCount - 1) break; // keep one lane free

      int laneIndex;
      int tries = 0;
      do {
        laneIndex = _rng.nextInt(laneCount);
        tries++;
      } while (usedLanes.contains(laneIndex) && tries < 8);
      usedLanes.add(laneIndex);

      const palette = <Color>[
        Color(0xFFFF2D95), // pink
        Color(0xFF9D00FF), // purple
        Color(0xFF00F0FF), // cyan
        Color(0xFFFFE600), // yellow
      ];

      obstacles.add(Obstacle(
        x: lanes[laneIndex],
        y: -120,
        width: 56,
        height: 92,
        variant: _rng.nextInt(2), // 0 = striped block, 1 = enemy car
        color: palette[_rng.nextInt(palette.length)],
      ));
    }
  }

  void _spawnCoin() {
    final lanes = laneCenters();
    final laneIndex = _rng.nextInt(laneCount);
    coins.add(Coin(
      x: lanes[laneIndex],
      y: -40,
      width: 28,
      height: 28,
      phase: _rng.nextDouble() * pi * 2,
    ));
  }

  void _gameOver() {
    state = GameState.gameOver;
    notifyListeners();
  }
}

// =============================================================================
// Game objects
// Plain data classes describing every entity in the game world.
// Positions use a hybrid coordinate system that keeps code resolution-agnostic:
//   - x is NORMALIZED  (0.0 = left edge, 1.0 = right edge)
//   - y is in LOGICAL PIXELS (top-down, increasing downward)
//   - width/height in LOGICAL PIXELS
// =============================================================================

import 'package:flutter/material.dart';

/// Base class for everything that lives on the road.
abstract class GameObject {
  /// Normalized horizontal center: 0 (left edge) .. 1 (right edge).
  double x;

  /// Top Y coordinate in logical pixels.
  double y;

  /// Visual size in logical pixels.
  double width;
  double height;

  /// `false` means "remove me at the end of this frame".
  bool alive;

  GameObject({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.alive = true,
  });

  /// Hitbox rectangle in absolute screen coordinates.
  Rect getRect(Size canvas) {
    final cx = x * canvas.width;
    return Rect.fromLTWH(cx - width / 2, y, width, height);
  }
}

/// The car the player controls. Movement is lane-based with smooth easing.
class PlayerCar extends GameObject {
  /// Current target lane index (0 .. laneCount-1).
  int lane;

  PlayerCar({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    this.lane = 1,
  });
}

/// Falling hazard. Two visual variants:
///   - variant 0 → striped hazard block
///   - variant 1 → enemy car (drawn with headlights facing the player)
class Obstacle extends GameObject {
  final int variant;
  final Color color;

  Obstacle({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.variant,
    required this.color,
  });
}

/// Collectible. Worth +50 score and counts toward the coin counter.
class Coin extends GameObject {
  /// Phase used for the gentle pulsing animation in the painter.
  double phase;

  Coin({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    this.phase = 0.0,
  });
}

// =============================================================================
// GamePainter
// Single CustomPainter that draws everything: background, road, lane stripes,
// coins, obstacles and the player car. No images are loaded — every visual is
// a code-drawn shape with glow effects for the neon look.
// =============================================================================

import 'dart:math';

import 'package:flutter/material.dart';

import 'game_controller.dart';

class GamePainter extends CustomPainter {
  final GameController controller;

  // Listening to the controller via `repaint:` makes the painter redraw
  // automatically every time GameController.notifyListeners() fires.
  GamePainter(this.controller) : super(repaint: controller);

  // ---- Visual constants (pulled from AppTheme for self-containment) ----
  static const Color bgTop = Color(0xFF1A0033);
  static const Color bgMid = Color(0xFF0A0014);
  static const Color bgBot = Color(0xFF050010);
  static const Color roadDark = Color(0xFF14082A);
  static const Color edgeCyan = Color(0xFF00F0FF);
  static const Color edgePink = Color(0xFFFF2D95);
  static const Color laneStripe = Color(0xFF00F0FF);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawRoad(canvas, size);
    _drawCoins(canvas, size);
    _drawObstacles(canvas, size);
    _drawPlayer(canvas, size);
  }

  // ---------------------------------------------------------------------
  // Background — gradient + soft horizon glow.
  // ---------------------------------------------------------------------
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[bgTop, bgMid, bgBot],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Distant pink glow (think synthwave sun on the horizon).
    final glow = Paint()
      ..color = const Color(0xFFFF2D95).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.2),
      140,
      glow,
    );
  }

  // ---------------------------------------------------------------------
  // Road — surface, glowing edges, scrolling dashed lane dividers.
  // ---------------------------------------------------------------------
  void _drawRoad(Canvas canvas, Size size) {
    const roadFraction = GameController.roadWidthFraction;
    final roadLeft = (1 - roadFraction) * size.width / 2;
    final roadRight = size.width - roadLeft;
    final roadRect = Rect.fromLTRB(roadLeft, 0, roadRight, size.height);

    // Surface.
    canvas.drawRect(roadRect, Paint()..color = roadDark);

    // Soft sidewalk gradient hint on each side of the road.
    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[edgePink.withValues(alpha: 0.05), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, roadLeft, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, roadLeft, size.height), sidePaint);

    // Glowing edges.
    _drawGlowLine(
      canvas,
      Offset(roadLeft, 0),
      Offset(roadLeft, size.height),
      edgePink,
      4,
    );
    _drawGlowLine(
      canvas,
      Offset(roadRight, 0),
      Offset(roadRight, size.height),
      edgeCyan,
      4,
    );

    // Dashed lane dividers that scroll downward to fake forward motion.
    const dashHeight = 36.0;
    const gap = 44.0;
    const period = dashHeight + gap;
    final offset = controller.scrollOffset % period;
    final laneWidth = (roadRight - roadLeft) / GameController.laneCount;

    final dashGlow = Paint()
      ..color = laneStripe.withValues(alpha: 0.35)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final dashCore = Paint()
      ..color = laneStripe.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < GameController.laneCount; i++) {
      final x = roadLeft + laneWidth * i;
      for (double y = -period + offset; y < size.height; y += period) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), dashGlow);
        canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), dashCore);
      }
    }
  }

  /// Draws a vertical neon line by stacking a wide blurred stroke and a thin
  /// solid one on top. Standard trick for cheap neon glow on Flutter canvas.
  void _drawGlowLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Color color,
    double width,
  ) {
    final glow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = width * 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawLine(a, b, glow);

    final core = Paint()
      ..color = color
      ..strokeWidth = width;
    canvas.drawLine(a, b, core);
  }

  // ---------------------------------------------------------------------
  // Player car — bottom of the screen, faces upward.
  // ---------------------------------------------------------------------
  void _drawPlayer(Canvas canvas, Size size) {
    final p = controller.player;
    final cx = p.x * size.width;
    final rect = Rect.fromCenter(
      center: Offset(cx, p.y + p.height / 2),
      width: p.width,
      height: p.height,
    );
    _drawCar(
      canvas,
      rect,
      bodyColor: const Color(0xFF00FF94),
      accentColor: const Color(0xFF00F0FF),
      isPlayer: true,
    );
  }

  // ---------------------------------------------------------------------
  // Obstacles — striped hazard blocks or enemy cars.
  // ---------------------------------------------------------------------
  void _drawObstacles(Canvas canvas, Size size) {
    for (final o in controller.obstacles) {
      final cx = o.x * size.width;
      final rect = Rect.fromLTWH(cx - o.width / 2, o.y, o.width, o.height);
      if (o.variant == 0) {
        _drawHazard(canvas, rect, o.color);
      } else {
        _drawCar(
          canvas,
          rect,
          bodyColor: o.color,
          accentColor: Colors.white,
          isPlayer: false,
        );
      }
    }
  }

  /// Generic car drawing routine. `isPlayer` controls whether headlights /
  /// windshield are at the top (player) or bottom (oncoming traffic).
  void _drawCar(
    Canvas canvas,
    Rect rect, {
    required Color bodyColor,
    required Color accentColor,
    required bool isPlayer,
  }) {
    // Outer glow.
    final glow = Paint()
      ..color = bodyColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(14)),
      glow,
    );

    // Body.
    final body = Paint()..color = bodyColor;
    final bodyRRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(bodyRRect, body);

    // Subtle top highlight gradient (gives a slight 3D feel).
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRRect(bodyRRect, highlight);

    // Windshield (dark tinted glass).
    final shieldRect = Rect.fromLTWH(
      rect.left + rect.width * 0.15,
      isPlayer
          ? rect.top + rect.height * 0.18
          : rect.bottom - rect.height * 0.42,
      rect.width * 0.7,
      rect.height * 0.24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shieldRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF0A0014).withValues(alpha: 0.85),
    );

    // Headlights.
    final lightSize = rect.width * 0.18;
    final lightY = isPlayer ? rect.top + 4 : rect.bottom - 4 - lightSize * 0.55;

    final lightPaint = Paint()..color = accentColor;
    final lightGlow = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final leftLight = Rect.fromLTWH(
      rect.left + rect.width * 0.12,
      lightY,
      lightSize,
      lightSize * 0.55,
    );
    final rightLight = Rect.fromLTWH(
      rect.right - rect.width * 0.12 - lightSize,
      lightY,
      lightSize,
      lightSize * 0.55,
    );
    for (final r in <Rect>[leftLight, rightLight]) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      canvas.drawRRect(rr, lightGlow);
      canvas.drawRRect(rr, lightPaint);
    }

    // Side wheels (just dark vertical strips for a stylized look).
    const wheelW = 5.0;
    final wheelH = rect.height * 0.22;
    final yTop = rect.top + rect.height * 0.20;
    final yBot = rect.bottom - rect.height * 0.20 - wheelH;
    final wheelPaint = Paint()..color = Colors.black87;
    canvas.drawRect(
      Rect.fromLTWH(rect.left - 1, yTop, wheelW, wheelH),
      wheelPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - wheelW + 1, yTop, wheelW, wheelH),
      wheelPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left - 1, yBot, wheelW, wheelH),
      wheelPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - wheelW + 1, yBot, wheelW, wheelH),
      wheelPaint,
    );
  }

  /// Striped hazard block — the "construction barrier" obstacle variant.
  void _drawHazard(Canvas canvas, Rect rect, Color color) {
    // Outer glow.
    final glow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(8)),
      glow,
    );

    // Clipped diagonal stripes.
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1A0033));

    final stripe = Paint()..color = color;
    const stripeWidth = 14.0;
    final diag = rect.height + rect.width;
    for (double i = -diag; i < diag; i += stripeWidth * 2) {
      final path = Path()
        ..moveTo(rect.left + i, rect.bottom)
        ..lineTo(rect.left + i + stripeWidth, rect.bottom)
        ..lineTo(rect.left + i + stripeWidth + rect.height, rect.top)
        ..lineTo(rect.left + i + rect.height, rect.top)
        ..close();
      canvas.drawPath(path, stripe);
    }
    canvas.restore();

    // White border.
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      border,
    );
  }

  // ---------------------------------------------------------------------
  // Coins — gold disc with inner star and pulsing glow.
  // ---------------------------------------------------------------------
  void _drawCoins(Canvas canvas, Size size) {
    for (final c in controller.coins) {
      final cx = c.x * size.width;
      final cy = c.y + c.height / 2;
      final pulse = 1.0 + sin(c.phase) * 0.12;
      final r = (c.width / 2) * pulse;

      // Glow.
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.3,
        Paint()
          ..color = const Color(0xFFFFE600).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );

      // Body (radial gradient).
      final body = Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFFFF59D),
            Color(0xFFFFE600),
            Color(0xFFFFB300),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, body);

      // Inner orange star.
      _drawStar(
        canvas,
        Offset(cx, cy),
        r * 0.55,
        5,
        Paint()..color = const Color(0xFFFF6F00),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, int points, Paint paint) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = -pi / 2 + i * pi / points;
      final radius = i.isEven ? r : r * 0.45;
      final x = c.dx + cos(angle) * radius;
      final y = c.dy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // Repaint every frame — driven by the controller's notifyListeners().
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

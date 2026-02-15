import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template toly_head}
/// Spinning dome-shaped head of Anatoly Yakovenko (Toly), founder of Solana.
/// Replaces the old Android animatronic on the spaceship.
/// {@endtemplate}
class TolyHead extends BodyComponent with InitialPosition, Layered, ZIndex {
  /// {@macro toly_head}
  TolyHead({Iterable<Component>? children})
      : super(
          children: [
            _TolyHeadVisual(),
            BumpingBehavior(strength: 20),
            ...?children,
          ],
          renderBody: false,
        ) {
    layer = Layer.spaceship;
    zIndex = ZIndexes.androidHead;
  }

  @override
  Body createBody() {
    final shape = EllipseShape(
      center: Vector2.zero(),
      majorRadius: 3.1,
      minorRadius: 2,
    )..rotate(1.4);
    final bodyDef = BodyDef(position: initialPosition);

    return world.createBody(bodyDef)..createFixtureFromShape(shape);
  }
}

/// Procedurally drawn spinning Toly head.
class _TolyHeadVisual extends PositionComponent with HasGameRef {
  _TolyHeadVisual()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
          size: Vector2(7.0, 7.0),
        );

  /// Current rotation angle (0 = facing forward, pi = facing away).
  double _angle = 0;

  /// Angular velocity in rad/s.
  static const double _spinSpeed = 2.5;

  /// Wobble amplitude in world units.
  static const double _wobbleAmp = 0.15;

  /// Wobble frequency multiplier.
  static const double _wobbleFreq = 6.0;

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _angle = (_angle + _spinSpeed * dt) % (2 * math.pi);

    // Wobble bounce effect.
    position.y = -2.6 + math.sin(_time * _wobbleFreq) * _wobbleAmp;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawTolyHead(canvas, size.x, size.y, _angle);
  }
}

// ---------------------------------------------------------------------------
// Procedural drawing routines for Toly's head.
// ---------------------------------------------------------------------------

/// The Solana purple/teal palette.
const _solPurple = Color(0xFF9945FF);
const _solTeal = Color(0xFF14F195);
const _skinTone = Color(0xFFE8B89D);
const _skinShadow = Color(0xFFCF9A7B);
const _hairColor = Color(0xFF3B2314);
const _beanieColor = Color(0xFF1E1E2E);
const _beanieBand = Color(0xFF9945FF);
const _beardColor = Color(0xFF4A3322);
const _eyeWhite = Color(0xFFF5F5F5);
const _eyeIris = Color(0xFF3B5998);
const _lipColor = Color(0xFFC27060);

void _drawTolyHead(Canvas canvas, double w, double h, double angle) {
  final cx = w / 2;
  final cy = h / 2;
  final r = w * 0.42; // head radius

  // How much of the face is visible: 1 = full front, 0 = profile, -1 = back.
  final faceFactor = math.cos(angle);
  // Horizontal offset for features based on rotation.
  final xShift = math.sin(angle);

  // ----- Dome / Skull -----
  final headPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset(cx + xShift * r * 0.3, cy - r * 0.1),
      r * 1.3,
      [_skinTone, _skinShadow],
      [0.3, 1.0],
    );

  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 2, height: r * 2.1),
    headPaint,
  );

  // ----- Beanie hat -----
  _drawBeanie(canvas, cx, cy, r, xShift, faceFactor);

  // ----- Face features (only when facing roughly forward) -----
  if (faceFactor > 0.15) {
    final faceAlpha = ((faceFactor - 0.15) / 0.85).clamp(0.0, 1.0);
    _drawFace(canvas, cx, cy, r, xShift, faceFactor, faceAlpha);
  }

  // ----- Back of head (hair) when facing away -----
  if (faceFactor < 0.2) {
    final backAlpha = ((0.2 - faceFactor) / 1.2).clamp(0.0, 1.0);
    _drawBackOfHead(canvas, cx, cy, r, xShift, backAlpha);
  }

  // ----- Beard (visible from the sides too) -----
  if (faceFactor > -0.3) {
    final beardAlpha = ((faceFactor + 0.3) / 1.3).clamp(0.0, 1.0);
    _drawBeard(canvas, cx, cy, r, xShift, faceFactor, beardAlpha);
  }

  // ----- Solana glow ring at base -----
  _drawGlowRing(canvas, cx, cy + r * 0.9, r, angle);
}

void _drawBeanie(Canvas canvas, double cx, double cy, double r,
    double xShift, double faceFactor) {
  final beanieTop = cy - r * 0.95;
  final beanieBottom = cy - r * 0.35;

  // Main beanie body.
  final beaniePaint = Paint()..color = _beanieColor;
  final beanieRect = RRect.fromRectAndCorners(
    Rect.fromLTRB(cx - r * 0.85, beanieTop, cx + r * 0.85, beanieBottom),
    topLeft: Radius.circular(r * 0.9),
    topRight: Radius.circular(r * 0.9),
    bottomLeft: Radius.circular(r * 0.15),
    bottomRight: Radius.circular(r * 0.15),
  );
  canvas.drawRRect(beanieRect, beaniePaint);

  // Solana-colored band.
  final bandPaint = Paint()..color = _beanieBand;
  canvas.drawRect(
    Rect.fromLTRB(cx - r * 0.85, beanieBottom - r * 0.12, cx + r * 0.85, beanieBottom),
    bandPaint,
  );

  // Little nub on top.
  final nubPaint = Paint()..color = _beanieColor;
  canvas.drawCircle(Offset(cx, beanieTop + r * 0.05), r * 0.12, nubPaint);
}

void _drawFace(Canvas canvas, double cx, double cy, double r,
    double xShift, double faceFactor, double alpha) {
  final paint = Paint();

  // Eye positions compress horizontally with rotation.
  final eyeSpacing = r * 0.32 * faceFactor;
  final eyeY = cy - r * 0.15;

  // Eyes.
  final eyeR = r * 0.12;
  for (final sign in [-1.0, 1.0]) {
    final ex = cx + xShift * r * 0.1 + sign * eyeSpacing;

    // White.
    paint.color = _eyeWhite.withValues(alpha: alpha);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ex, eyeY), width: eyeR * 2, height: eyeR * 1.6),
      paint,
    );

    // Iris.
    paint.color = _eyeIris.withValues(alpha: alpha);
    canvas.drawCircle(Offset(ex + xShift * eyeR * 0.2, eyeY), eyeR * 0.55, paint);

    // Pupil.
    paint.color = Colors.black.withValues(alpha: alpha);
    canvas.drawCircle(Offset(ex + xShift * eyeR * 0.3, eyeY), eyeR * 0.25, paint);
  }

  // Eyebrows.
  final browPaint = Paint()
    ..color = _hairColor.withValues(alpha: alpha)
    ..strokeWidth = r * 0.05
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (final sign in [-1.0, 1.0]) {
    final bx = cx + xShift * r * 0.1 + sign * eyeSpacing;
    canvas.drawLine(
      Offset(bx - eyeR * 0.8, eyeY - eyeR * 1.3),
      Offset(bx + eyeR * 0.8, eyeY - eyeR * 1.5),
      browPaint,
    );
  }

  // Nose.
  final nosePaint = Paint()
    ..color = _skinShadow.withValues(alpha: alpha)
    ..strokeWidth = r * 0.04
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final noseX = cx + xShift * r * 0.15;
  final noseY = cy + r * 0.08;
  final nosePath = Path()
    ..moveTo(noseX - r * 0.03, cy - r * 0.05)
    ..quadraticBezierTo(noseX + r * 0.08 * faceFactor, noseY, noseX - r * 0.06, noseY);
  canvas.drawPath(nosePath, nosePaint);

  // Mouth / slight smile.
  final mouthPaint = Paint()
    ..color = _lipColor.withValues(alpha: alpha)
    ..strokeWidth = r * 0.04
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final mx = cx + xShift * r * 0.12;
  final my = cy + r * 0.25;
  canvas.drawArc(
    Rect.fromCenter(center: Offset(mx, my), width: r * 0.4 * faceFactor, height: r * 0.15),
    0.1,
    math.pi - 0.2,
    false,
    mouthPaint,
  );
}

void _drawBeard(Canvas canvas, double cx, double cy, double r,
    double xShift, double faceFactor, double alpha) {
  final beardPaint = Paint()..color = _beardColor.withValues(alpha: alpha * 0.85);

  final bx = cx + xShift * r * 0.1;
  final by = cy + r * 0.3;

  // Beard as a filled rounded shape under the chin.
  final beardPath = Path()
    ..moveTo(bx - r * 0.45 * faceFactor.abs().clamp(0.3, 1.0), by - r * 0.1)
    ..quadraticBezierTo(bx - r * 0.5 * faceFactor.abs().clamp(0.3, 1.0), by + r * 0.35,
        bx, by + r * 0.55)
    ..quadraticBezierTo(bx + r * 0.5 * faceFactor.abs().clamp(0.3, 1.0), by + r * 0.35,
        bx + r * 0.45 * faceFactor.abs().clamp(0.3, 1.0), by - r * 0.1)
    ..close();
  canvas.drawPath(beardPath, beardPaint);

  // Stubble texture lines.
  final stubblePaint = Paint()
    ..color = _hairColor.withValues(alpha: alpha * 0.3)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
  final rng = math.Random(42);
  for (var i = 0; i < 12; i++) {
    final sx = bx + (rng.nextDouble() - 0.5) * r * 0.6 * faceFactor.abs().clamp(0.3, 1.0);
    final sy = by + rng.nextDouble() * r * 0.4;
    canvas.drawLine(Offset(sx, sy), Offset(sx + 0.3, sy + 0.8), stubblePaint);
  }
}

void _drawBackOfHead(Canvas canvas, double cx, double cy, double r,
    double xShift, double alpha) {
  final hairPaint = Paint()..color = _hairColor.withValues(alpha: alpha * 0.9);

  // Dark hair on the back.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(cx, cy + r * 0.1),
      width: r * 1.7,
      height: r * 1.6,
    ),
    hairPaint,
  );
}

void _drawGlowRing(Canvas canvas, double cx, double cy, double r, double angle) {
  // Animated Solana gradient glow ring at the base.
  final ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.08
    ..shader = ui.Gradient.sweep(
      Offset(cx, cy),
      [_solPurple, _solTeal, _solPurple],
      [0.0, 0.5, 1.0],
      TileMode.clamp,
      angle,
      angle + 2 * math.pi,
    );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 0.5),
    ringPaint,
  );
}

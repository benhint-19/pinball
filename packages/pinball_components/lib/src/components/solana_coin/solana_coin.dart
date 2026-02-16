import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template solana_coin}
/// A procedurally-rendered 3D Solana token hovering in Flutter Forest.
/// Draws a perspective-correct coin with the real Solana logo, bobs
/// vertically, and lights up on ball contact.
/// {@endtemplate}
class SolanaCoin extends BodyComponent
    with InitialPosition, ContactCallbacks, ZIndex {
  /// {@macro solana_coin}
  SolanaCoin({Iterable<Component>? children})
      : super(
          children: [
            _SolanaCoinRenderer(),
            BumpingBehavior(strength: 15),
            ...?children,
          ],
          renderBody: false,
        ) {
    zIndex = ZIndexes.flutterForest + 1;
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 4.0;
    final bodyDef = BodyDef(position: initialPosition);
    return world.createBody(bodyDef)
      ..createFixtureFromShape(shape, density: 0);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    final renderer = children.whereType<_SolanaCoinRenderer>().firstOrNull;
    renderer?.triggerGlow();
  }
}

/// Draws a 3D coin with perspective tilt, the real Solana logo, bobbing
/// animation, and a glow effect on contact.
class _SolanaCoinRenderer extends PositionComponent {
  _SolanaCoinRenderer()
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
          size: Vector2(10.0, 10.0),
        );

  // -- animation state --
  double _time = 0;
  bool _glowing = false;
  double _glowTimer = 0;
  static const _glowDuration = 0.8;

  // -- coin geometry --
  // Perspective tilt: the coin face is an ellipse (circle viewed at ~25°).
  // yScale < 1 foreshortens the vertical axis.
  static const double _yScale = 0.55;
  // Visible rim thickness in world-units (the coin edge you see from above).
  static const double _rimDepth = 0.7;

  // -- colours --
  static const _teal = Color(0xFF14F195);
  static const _purple = Color(0xFF9945FF);
  static const _darkFace = Color(0xFF1A1A2E);
  static const _rimLight = Color(0xFFBBBBCC);
  static const _rimDark = Color(0xFF555566);
  static const _rimEdge = Color(0xFF333344);

  void triggerGlow() {
    _glowing = true;
    _glowTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_glowing) {
      _glowTimer += dt;
      if (_glowTimer >= _glowDuration) {
        _glowing = false;
        _glowTimer = 0;
      }
    }

    // Gentle hover bob.
    position.y = math.sin(_time * 0.8 * 2 * math.pi) * 0.35;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cx = size.x / 2;
    final cy = size.y / 2;
    final rx = size.x * 0.42; // horizontal radius of face ellipse
    final ry = rx * _yScale; // vertical radius (foreshortened)

    // Glow intensity ramps up then fades.
    final glowT = _glowing ? (1.0 - (_glowTimer / _glowDuration)) : 0.0;

    // ── ground shadow ──
    _drawShadow(canvas, cx, cy + ry + _rimDepth + 1.2, rx, ry * 0.3, glowT);

    // ── coin rim (visible edge) ──
    _drawRim(canvas, cx, cy, rx, ry, glowT);

    // ── coin face (top ellipse) ──
    _drawFace(canvas, cx, cy, rx, ry, glowT);

    // ── Solana logo on the face ──
    _drawSolanaLogo(canvas, cx, cy, rx, ry, glowT);

    // ── specular highlight ──
    _drawSpecular(canvas, cx, cy, rx, ry);

    // ── outer glow when lit ──
    if (glowT > 0.05) {
      _drawOuterGlow(canvas, cx, cy, rx, ry, glowT);
    }
  }

  void _drawShadow(
      Canvas canvas, double cx, double cy, double rx, double ry, double glow) {
    final shadowColor = glow > 0.05
        ? Color.lerp(
            const Color(0x33000000), const Color(0x5514F195), glow * 0.6)!
        : const Color(0x33000000);
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      shadowPaint,
    );
  }

  void _drawRim(
      Canvas canvas, double cx, double cy, double rx, double ry, double glow) {
    // The rim is a series of thin horizontal slices from bottom to top of the
    // visible edge, drawn as elliptical arcs below the face.
    final steps = (_rimDepth * 6).ceil();
    for (var i = steps; i >= 0; i--) {
      final t = i / steps; // 0 = top (face), 1 = bottom
      final sliceY = cy + t * _rimDepth;
      // Gradient from light at top-rim to dark at bottom
      final c = Color.lerp(_rimLight, _rimDark, t)!;
      final rimColor = glow > 0.05
          ? Color.lerp(c, _teal, glow * 0.35 * (1 - t))!
          : c;
      final paint = Paint()..color = rimColor;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, sliceY), width: rx * 2, height: ry * 2),
        paint,
      );
    }

    // Rim edge outline at the bottom of the visible edge.
    final edgePaint = Paint()
      ..color = glow > 0.05
          ? Color.lerp(_rimEdge, _teal, glow * 0.3)!
          : _rimEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15;
    // Bottom ellipse outline (only bottom half is visible).
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(
        cx - rx - 1, cy, cx + rx + 1, cy + _rimDepth + ry + 1));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + _rimDepth), width: rx * 2, height: ry * 2),
      edgePaint,
    );
    canvas.restore();
  }

  void _drawFace(
      Canvas canvas, double cx, double cy, double rx, double ry, double glow) {
    final faceRect =
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);

    // Dark coin face with subtle radial gradient.
    final faceColor = glow > 0.05
        ? Color.lerp(_darkFace, const Color(0xFF0A2A1A), glow * 0.5)!
        : _darkFace;
    final facePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        rx,
        [
          Color.lerp(faceColor, Colors.white, 0.08)!,
          faceColor,
        ],
        [0.0, 1.0],
      );
    canvas.drawOval(faceRect, facePaint);

    // Thin rim ring on the face edge.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.25
      ..color = glow > 0.05
          ? Color.lerp(_rimLight, _teal, glow * 0.5)!
          : _rimLight.withValues(alpha: 0.6);
    canvas.drawOval(faceRect, ringPaint);

    // Inner ring (slightly smaller).
    final innerRect = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 1.78, height: ry * 1.78);
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.12
      ..color = glow > 0.05
          ? Color.lerp(const Color(0x44AAAAAA), _teal, glow * 0.4)!
          : const Color(0x44AAAAAA);
    canvas.drawOval(innerRect, innerRingPaint);
  }

  /// Draws the real Solana logo: three angled parallelogram bars forming
  /// the distinctive angular "S" shape, with the teal-to-purple gradient.
  void _drawSolanaLogo(
      Canvas canvas, double cx, double cy, double rx, double ry, double glow) {
    // Logo fits inside the inner ring area.
    final logoW = rx * 1.1;
    final logoH = ry * 1.1;

    // The Solana logo has 3 horizontal bars with angled left/right ends.
    // Each bar is a parallelogram. The skew angle for the pointed ends is ~18°.
    //   Top bar:    left pointed right (▷), right flat edge
    //   Mid bar:    left flat edge, right pointed left (◁)
    //   Bot bar:    left pointed right (▷), right flat edge

    final barH = logoH * 0.22; // height of each bar
    final gap = logoH * 0.12; // gap between bars
    final skew = logoW * 0.18; // horizontal skew for the pointed end

    // Vertical centres of the three bars.
    final topY = cy - barH - gap;
    final midY = cy;
    final botY = cy + barH + gap;

    final left = cx - logoW / 2;
    final right = cx + logoW / 2;

    // Gradient from teal (top) to purple (bottom), boosted when glowing.
    Color barColor(double t) {
      final base = Color.lerp(_teal, _purple, t)!;
      if (glow > 0.05) {
        return Color.lerp(base, Colors.white, glow * 0.45)!;
      }
      return base;
    }

    // Top bar: pointed on left, flat on right.
    _drawBar(canvas, barColor(0.0),
        leftTop: Offset(left + skew, topY - barH / 2),
        rightTop: Offset(right, topY - barH / 2),
        rightBot: Offset(right, topY + barH / 2),
        leftBot: Offset(left, topY + barH / 2));

    // Middle bar: flat on left, pointed on right (reversed direction).
    _drawBar(canvas, barColor(0.5),
        leftTop: Offset(left, midY - barH / 2),
        rightTop: Offset(right, midY - barH / 2),
        rightBot: Offset(right - skew, midY + barH / 2),
        leftBot: Offset(left, midY + barH / 2));

    // Bottom bar: pointed on left, flat on right.
    _drawBar(canvas, barColor(1.0),
        leftTop: Offset(left + skew, botY - barH / 2),
        rightTop: Offset(right, botY - barH / 2),
        rightBot: Offset(right, botY + barH / 2),
        leftBot: Offset(left, botY + barH / 2));
  }

  void _drawBar(Canvas canvas, Color color,
      {required Offset leftTop,
      required Offset rightTop,
      required Offset rightBot,
      required Offset leftBot}) {
    final path = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(rightBot.dx, rightBot.dy)
      ..lineTo(leftBot.dx, leftBot.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawSpecular(
      Canvas canvas, double cx, double cy, double rx, double ry) {
    // Subtle specular highlight at upper-left of the face.
    final specRect = Rect.fromCenter(
        center: Offset(cx - rx * 0.25, cy - ry * 0.25),
        width: rx * 0.9,
        height: ry * 0.6);
    final specPaint = Paint()
      ..shader = ui.Gradient.radial(
        specRect.center,
        rx * 0.45,
        [const Color(0x22FFFFFF), const Color(0x00FFFFFF)],
        [0.0, 1.0],
      );
    canvas.drawOval(specRect, specPaint);
  }

  void _drawOuterGlow(Canvas canvas, double cx, double cy, double rx,
      double ry, double glow) {
    // Radial glow that expands outward.
    final glowRadius = rx * (1.3 + glow * 0.3);
    final glowRect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: glowRadius * 2,
        height: glowRadius * 2 * _yScale);
    final glowAlpha = (glow * 0.35).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        glowRadius,
        [
          _teal.withValues(alpha: glowAlpha),
          _purple.withValues(alpha: glowAlpha * 0.5),
          const Color(0x00000000),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawOval(glowRect, glowPaint);
  }
}

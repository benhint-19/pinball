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
/// Static 3D head of Anatoly Yakovenko (Toly), founder of Solana.
/// Front-facing cartoon mapped onto a cylinder+dome surface.
/// Wobbles when hit by the ball via [BumpingBehavior].
/// {@endtemplate}
class TolyHead extends BodyComponent with InitialPosition, Layered, ZIndex {
  /// {@macro toly_head}
  TolyHead({Iterable<Component>? children})
      : super(
          children: [
            _TolyHead3D(),
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

// ============================================================================
// 3D cylinder+dome renderer — static front-facing image with depth shading
// ============================================================================

const int _outW = 80;
const int _outH = 96;

class _TolyHead3D extends PositionComponent with HasGameRef {
  _TolyHead3D()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
          size: Vector2(12.0, 14.4),
        );

  /// Front-facing frame pixel data: [y][x] = ARGB color.
  late List<List<int>> _pixels;
  late int _frameW;
  late int _frameH;

  /// Pre-computed cylinder+dome projection map.
  late List<List<_SurfacePoint?>> _projMap;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = gameRef.images.fromCache(
      Assets.images.android.spaceship.tolyHead.keyName,
    );

    // Use only the first frame (top-left cell = front view).
    final sheetCols = 8;
    _frameW = spriteSheet.width ~/ sheetCols;
    _frameH = spriteSheet.height ~/ 4;

    final sheetData = await spriteSheet.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (sheetData == null) return;

    // Extract just frame 0 (top-left).
    _pixels = List.generate(_frameH, (y) {
      return List.generate(_frameW, (x) {
        final idx = (y * spriteSheet.width + x) * 4;
        final r = sheetData.getUint8(idx);
        final g = sheetData.getUint8(idx + 1);
        final b = sheetData.getUint8(idx + 2);
        final a = sheetData.getUint8(idx + 3);
        return (a << 24) | (r << 16) | (g << 8) | b;
      });
    });

    _projMap = _buildProjectionMap();
  }

  List<List<_SurfacePoint?>> _buildProjectionMap() {
    final map = List.generate(
      _outH,
      (_) => List<_SurfacePoint?>.filled(_outW, null),
    );

    const domeFrac = 0.35;

    for (var py = 0; py < _outH; py++) {
      final fv = py / (_outH - 1);

      for (var px = 0; px < _outW; px++) {
        final nx = (px / (_outW - 1)) * 2.0 - 1.0;

        double lon;
        double ez;

        if (fv < domeFrac) {
          // Dome cap.
          final domeNy = 1.0 - (fv / domeFrac);
          final domeRadius = math.sqrt(math.max(0, 1.0 - domeNy * domeNy));
          final ex = nx / math.max(domeRadius, 0.01);
          if (ex.abs() > 1.0) continue;
          ez = math.sqrt(math.max(0, 1.0 - ex * ex));
          lon = math.atan2(ex, ez);
        } else {
          // Cylinder body.
          if (nx.abs() > 1.0) continue;
          ez = math.sqrt(math.max(0, 1.0 - nx * nx));
          lon = math.atan2(nx, ez);
        }

        map[py][px] = _SurfacePoint(lon, fv, ez);
      }
    }

    return map;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_pixels.isEmpty) return;

    final w = size.x;
    final h = size.y;
    final pxW = w / _outW;
    final pxH = h / _outH;
    final paint = Paint()..isAntiAlias = false;

    for (var py = 0; py < _outH; py++) {
      for (var px = 0; px < _outW; px++) {
        final sp = _projMap[py][px];
        if (sp == null) continue;

        // Map surface longitude to frame X: lon=0 → center, ±visible → edges.
        final visibleArc = math.pi * 0.55;
        final normX = (sp.lon / visibleArc).clamp(-1.0, 1.0);
        final tx = ((_frameW - 1) * (normX + 1.0) / 2.0)
            .round()
            .clamp(0, _frameW - 1);
        final ty = (sp.texV * (_frameH - 1)).round().clamp(0, _frameH - 1);

        final pixel = _pixels[ty][tx];
        final alpha = (pixel >> 24) & 0xFF;
        if (alpha < 10) continue;

        // 3D shading: darken edges.
        final lonAbs = sp.lon.abs();
        final angleFade =
            1.0 - (lonAbs / (math.pi * 0.6)).clamp(0.0, 1.0) * 0.5;
        final depthFade = 0.75 + 0.25 * sp.ez;
        final shade = angleFade * depthFade;

        final r = ((pixel >> 16) & 0xFF) * shade;
        final g = ((pixel >> 8) & 0xFF) * shade;
        final b = (pixel & 0xFF) * shade;

        paint.color = Color.fromARGB(
          alpha,
          r.round().clamp(0, 255),
          g.round().clamp(0, 255),
          b.round().clamp(0, 255),
        );

        canvas.drawRect(
          Rect.fromLTWH(px * pxW, py * pxH, pxW + 0.05, pxH + 0.05),
          paint,
        );
      }
    }

    // Hat brim.
    _drawHatBrim(canvas, w, h);

    // Solana glow ring at base.
    _drawGlowRing(canvas, w / 2, h * 0.92, w * 0.4);
  }

  void _drawHatBrim(Canvas canvas, double w, double h) {
    final brimY = h * 0.28;
    final brimWidth = w * 0.7;
    final brimDepth = w * 0.13;
    final cx = w / 2;

    final brimPath = Path()
      ..moveTo(cx - brimWidth / 2, brimY)
      ..quadraticBezierTo(cx, brimY + brimDepth * 1.5, cx + brimWidth / 2, brimY)
      ..quadraticBezierTo(cx, brimY + brimDepth * 0.3, cx - brimWidth / 2, brimY)
      ..close();

    canvas.drawPath(brimPath, Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawPath(
      brimPath,
      Paint()
        ..color = const Color(0xFF2A2A4E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015,
    );
  }
}

void _drawGlowRing(Canvas canvas, double cx, double cy, double r) {
  final ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.08
    ..shader = ui.Gradient.sweep(
      Offset(cx, cy),
      [
        const Color(0xFF9945FF),
        const Color(0xFF14F195),
        const Color(0xFF9945FF),
      ],
      [0.0, 0.5, 1.0],
    );
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(cx, cy), width: r * 2.0, height: r * 0.5),
    ringPaint,
  );
}

class _SurfacePoint {
  const _SurfacePoint(this.lon, this.texV, this.ez);
  final double lon;
  final double texV;
  final double ez;
}

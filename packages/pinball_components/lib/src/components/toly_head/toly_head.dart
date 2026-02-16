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
/// Spinning 3D head of Anatoly Yakovenko (Toly), founder of Solana.
/// AI-generated frames mapped onto a cylinder+dome surface with protruding
/// hat brim. Rotates around the Y axis.
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
// 3D cylinder+dome renderer that samples from AI-generated sprite frames
// ============================================================================

/// Resolution of the 3D render output.
const int _outW = 80;
const int _outH = 96;

/// Number of key frames in the sprite sheet.
const int _sheetCols = 8;
const int _sheetRows = 4;
const int _totalFrames = _sheetCols * _sheetRows;

class _TolyHead3D extends PositionComponent with HasGameRef {
  _TolyHead3D()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
          size: Vector2(12.0, 14.4),
        );

  double _angle = 0;
  double _time = 0;

  static const double _spinSpeed = 1.5;
  static const double _wobbleAmp = 0.12;
  static const double _wobbleFreq = 4.0;

  /// Pixel data extracted from each sprite frame: [frameIndex][y][x] = color.
  late List<List<List<int>>> _framePixels;
  late int _frameW;
  late int _frameH;

  /// Pre-computed cylinder+dome projection map.
  /// For each output pixel, stores (longitude, v) or null if outside.
  late List<List<_SurfacePoint?>> _projMap;


  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = gameRef.images.fromCache(
      Assets.images.android.spaceship.tolyHead.keyName,
    );

    _frameW = spriteSheet.width ~/ _sheetCols;
    _frameH = spriteSheet.height ~/ _sheetRows;

    // Extract pixel data from each frame.
    final sheetData = await spriteSheet.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (sheetData == null) return;

    _framePixels = List.generate(_totalFrames, (i) {
      final col = i % _sheetCols;
      final row = i ~/ _sheetCols;
      final xOff = col * _frameW;
      final yOff = row * _frameH;

      return List.generate(_frameH, (y) {
        return List.generate(_frameW, (x) {
          final idx = ((yOff + y) * spriteSheet.width + (xOff + x)) * 4;
          final r = sheetData.getUint8(idx);
          final g = sheetData.getUint8(idx + 1);
          final b = sheetData.getUint8(idx + 2);
          final a = sheetData.getUint8(idx + 3);
          return (a << 24) | (r << 16) | (g << 8) | b;
        });
      });
    });

    _projMap = _buildProjectionMap();
  }

  List<List<_SurfacePoint?>> _buildProjectionMap() {
    final map = List.generate(
      _outH,
      (_) => List<_SurfacePoint?>.filled(_outW, null),
    );

    // The shape: cylinder body (bottom 65%) + dome cap (top 35%).
    const domeStart = 0.0;  // top of output
    const domeFrac = 0.35;  // dome takes top 35%
    const cylEnd = 1.0;     // cylinder goes to bottom
    final domeEndY = _outH * domeFrac;

    for (var py = 0; py < _outH; py++) {
      final fv = py / (_outH - 1); // 0=top, 1=bottom

      for (var px = 0; px < _outW; px++) {
        // Horizontal: -1 to 1
        final nx = (px / (_outW - 1)) * 2.0 - 1.0;

        double lon;  // longitude in radians, 0 = front
        double ez;   // z-depth for shading
        double texV; // vertical texture coordinate 0..1

        if (fv < domeFrac) {
          // --- DOME (hemisphere cap) ---
          final domeNy = 1.0 - (fv / domeFrac); // 1=top, 0=equator

          // Dome radius narrows toward the top.
          final domeRadius = math.sqrt(math.max(0, 1.0 - domeNy * domeNy));
          final ex = nx / math.max(domeRadius, 0.01);

          if (ex.abs() > 1.0) continue; // outside dome silhouette

          ez = math.sqrt(math.max(0, 1.0 - ex * ex));
          lon = math.atan2(ex, ez);
          texV = fv / 1.0; // map dome to top portion of texture
        } else {
          // --- CYLINDER body ---
          // Cylinder has constant radius.
          if (nx.abs() > 1.0) continue;

          ez = math.sqrt(math.max(0, 1.0 - nx * nx));
          lon = math.atan2(nx, ez);
          texV = fv;
        }

        map[py][px] = _SurfacePoint(lon, texV, ez);
      }
    }

    return map;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _angle = (_angle + _spinSpeed * dt) % (2 * math.pi);
    position.y = -2.6 + math.sin(_time * _wobbleFreq) * _wobbleAmp;

    // Select the closest frame for the current rotation angle.
    _currentFrame = ((_angle / (2 * math.pi)) * _totalFrames).floor() % _totalFrames;
  }

  /// The current rotation angle selects which frame to show.
  /// The surface longitude maps to the X position within that frame —
  /// center of the cylinder = center of the image, edges = edges.
  int _currentFrame = 0;

  int _sampleTexture(double lon, double v) {
    // lon is already rotated: -π..π, 0 = facing camera.
    // Map lon to horizontal position within the current frame.
    // lon=0 → center of frame, lon=±visible_edge → edges of frame.
    // The visible arc on a cylinder is about ±π/2 (90° each side).
    // Map that to 0..frameW.
    final visibleArc = math.pi * 0.55; // how much of the cylinder is visible
    final nx = (lon / visibleArc).clamp(-1.0, 1.0); // -1..1
    final tx = ((_frameW - 1) * (nx + 1.0) / 2.0).round().clamp(0, _frameW - 1);
    final ty = (v * (_frameH - 1)).round().clamp(0, _frameH - 1);

    return _framePixels[_currentFrame][ty][tx];
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_framePixels.isEmpty) return;

    final w = size.x;
    final h = size.y;
    final pxW = w / _outW;
    final pxH = h / _outH;

    // Draw cylinder+dome surface.
    final paint = Paint()..isAntiAlias = false;

    for (var py = 0; py < _outH; py++) {
      for (var px = 0; px < _outW; px++) {
        final sp = _projMap[py][px];
        if (sp == null) continue;

        // Apply current rotation.
        var lon = sp.lon + _angle;
        while (lon > math.pi) lon -= 2 * math.pi;
        while (lon < -math.pi) lon += 2 * math.pi;

        final pixel = _sampleTexture(lon, sp.texV);
        final alpha = (pixel >> 24) & 0xFF;
        if (alpha < 10) continue;

        // Shading: darken edges for 3D depth.
        var lonFromFront = lon.abs();
        if (lonFromFront > math.pi) lonFromFront = 2 * math.pi - lonFromFront;
        final angleFade = 1.0 - (lonFromFront / (math.pi * 0.6)).clamp(0, 1) * 0.55;
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

    // --- HAT BRIM ---
    _drawHatBrim(canvas, w, h);

    // --- Solana glow ring at base ---
    _drawGlowRing(canvas, w / 2, h * 0.92, w * 0.4, _angle);
  }

  void _drawHatBrim(Canvas canvas, double w, double h) {
    // The brim sits at ~28% from top, protrudes forward.
    final brimY = h * 0.28;
    final brimWidth = w * 0.65;

    // Brim depth varies with rotation: max when facing camera, min at sides.
    var frontness = math.cos(_angle); // 1=front, -1=back
    // Brim visible width based on facing direction.
    final brimDepth = w * 0.12 * frontness.abs();

    // Brim shifts left/right based on rotation.
    final brimShift = math.sin(_angle) * w * 0.15;
    final cx = w / 2 + brimShift;

    if (frontness > 0.1) {
      // Facing camera: brim protrudes downward.
      final brimPath = Path()
        ..moveTo(cx - brimWidth / 2, brimY)
        ..quadraticBezierTo(cx, brimY + brimDepth * 1.5, cx + brimWidth / 2, brimY)
        ..quadraticBezierTo(cx, brimY + brimDepth * 0.3, cx - brimWidth / 2, brimY)
        ..close();

      canvas.drawPath(
        brimPath,
        Paint()..color = const Color(0xFF1A1A2E),
      );
      // Brim edge highlight.
      canvas.drawPath(
        brimPath,
        Paint()
          ..color = const Color(0xFF2A2A4E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.015,
      );
    } else if (frontness < -0.1) {
      // Facing away: brim protrudes upward (we see underside).
      final brimPath = Path()
        ..moveTo(cx - brimWidth / 2, brimY)
        ..quadraticBezierTo(cx, brimY - brimDepth * 1.2, cx + brimWidth / 2, brimY)
        ..quadraticBezierTo(cx, brimY - brimDepth * 0.2, cx - brimWidth / 2, brimY)
        ..close();

      canvas.drawPath(
        brimPath,
        Paint()..color = const Color(0xFF121222),
      );
    }
    // At profile angles, brim is edge-on and barely visible — skip drawing.
  }
}

void _drawGlowRing(
    Canvas canvas, double cx, double cy, double r, double angle) {
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
      TileMode.clamp,
      angle,
      angle + 2 * math.pi,
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

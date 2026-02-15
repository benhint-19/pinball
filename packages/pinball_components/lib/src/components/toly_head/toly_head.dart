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
/// Spinning 3D-rendered head of Anatoly Yakovenko (Toly), founder of Solana.
/// Procedural raycasted sphere with pixel-art texture mapped onto it.
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

// ============================================================================
// Pixel-art sphere renderer with proper Y-axis rotation
// ============================================================================

/// Output pixel resolution (renders as NxN chunky pixels).
const int _res = 64;

/// Texture dimensions: columns = longitude (wraps 360°), rows = latitude.
const int _texW = 128;
const int _texH = 64;

/// Pre-computed UV for one pixel of the output sphere projection.
class _UV {
  const _UV(this.lon, this.lat, this.ez);
  final double lon;
  final double lat;
  final double ez; // z-depth for shading
}

// ---------------------------------------------------------------------------
// Palette (pixel-art Solana/Toly colors)
// ---------------------------------------------------------------------------
const _cTransparent = 0;
const _cSkin = 1;
const _cSkinDark = 2;
const _cHair = 3;
const _cBeanie = 4;
const _cBeanieBand = 5;
const _cEyeWhite = 6;
const _cEyeIris = 7;
const _cPupil = 8;
const _cBeard = 9;
const _cLip = 10;
const _cNose = 11;
const _cBrow = 12;
const _cTeal = 13;
const _cPurple = 14;
const _cEar = 15;
const _cBeanieHighlight = 16;
const _cBeardDark = 17;

const List<Color> _palette = [
  Color(0x00000000), // 0  transparent
  Color(0xFFE8B89D), // 1  skin
  Color(0xFFCF9A7B), // 2  skin dark/shadow
  Color(0xFF3B2314), // 3  hair
  Color(0xFF1E1E2E), // 4  beanie
  Color(0xFF9945FF), // 5  beanie band / solana purple
  Color(0xFFF0F0F0), // 6  eye white
  Color(0xFF3B6BBF), // 7  eye iris
  Color(0xFF111111), // 8  pupil
  Color(0xFF5C3D2E), // 9  beard
  Color(0xFFC27060), // 10 lip
  Color(0xFFBF8A6F), // 11 nose highlight
  Color(0xFF3B2314), // 12 eyebrow
  Color(0xFF14F195), // 13 teal
  Color(0xFF9945FF), // 14 purple
  Color(0xFFD4A080), // 15 ear
  Color(0xFF2A2A3E), // 16 beanie highlight
  Color(0xFF42291A), // 17 beard dark
];

// ---------------------------------------------------------------------------
// Texture map
// ---------------------------------------------------------------------------

int _getTexel(int u, int v) {
  double fu = u / _texW;
  if (fu > 0.5) fu -= 1.0;
  final afu = fu.abs();

  final fv = v / (_texH - 1);

  // --- BEANIE (top 25%) ---
  if (fv < 0.22) {
    if (fv < 0.06) {
      return (afu < 0.12) ? _cBeanie : _cTransparent;
    }
    if (fv < 0.19) {
      if (fu > 0.05 && fu < 0.15 && fv > 0.08) return _cBeanieHighlight;
      return _cBeanie;
    }
    return _cBeanieBand;
  }

  // --- FOREHEAD ---
  if (fv < 0.34) {
    if (afu > 0.42) return _cHair;
    if (afu > 0.35) return _cSkinDark;
    return _cSkin;
  }

  // --- EYEBROWS ---
  if (fv < 0.38) {
    if (fu > -0.20 && fu < -0.06 && fv < 0.37) return _cBrow;
    if (fu > 0.06 && fu < 0.20 && fv < 0.37) return _cBrow;
    if (afu > 0.42) return _cHair;
    if (afu > 0.35) return _cSkinDark;
    return _cSkin;
  }

  // --- EYES ---
  if (fv < 0.46) {
    for (final eyeCenter in [-0.14, 0.14]) {
      final dx = (fu - eyeCenter).abs();
      final dy = (fv - 0.42).abs();
      if (dx < 0.065 && dy < 0.028) {
        if (dx < 0.02 && dy < 0.018) return _cPupil;
        if (dx < 0.04 && dy < 0.024) return _cEyeIris;
        return _cEyeWhite;
      }
    }
    if (afu > 0.38 && afu < 0.48) return _cEar;
    if (afu > 0.48) return _cHair;
    return _cSkin;
  }

  // --- NOSE ---
  if (fv < 0.55) {
    if (afu < 0.04 && fv > 0.48) return _cNose;
    if (afu < 0.025 && fv < 0.52) return _cSkinDark;
    if (afu > 0.42) return _cHair;
    if (afu > 0.36) return _cSkinDark;
    return _cSkin;
  }

  // --- MOUTH ---
  if (fv < 0.62) {
    if (afu < 0.08 && fv > 0.57 && fv < 0.60) return _cLip;
    if (afu > 0.40) return _cHair;
    if (afu > 0.34) return _cSkinDark;
    return _cSkin;
  }

  // --- BEARD ---
  if (fv < 0.85) {
    if (afu > 0.42) return _cHair;
    if (afu < 0.35) {
      final hash = ((fu * 173.7 + fv * 311.1).abs() * 999).toInt() % 5;
      return hash == 0 ? _cBeardDark : _cBeard;
    }
    return _cSkinDark;
  }

  // --- CHIN / BOTTOM ---
  if (afu < 0.25) {
    final hash = ((fu * 173.7 + fv * 311.1).abs() * 999).toInt() % 4;
    return hash == 0 ? _cBeardDark : _cBeard;
  }
  if (afu < 0.35) return _cSkinDark;
  return _cHair;
}

// ---------------------------------------------------------------------------
// Pre-computed sphere projection lookup
// ---------------------------------------------------------------------------

late final List<List<_UV?>> _uvMap = _buildUVMap();

List<List<_UV?>> _buildUVMap() {
  final map = List.generate(_res, (_) => List<_UV?>.filled(_res, null));

  for (var py = 0; py < _res; py++) {
    final ny = (py / (_res - 1)) * 2.0 - 1.0;

    for (var px = 0; px < _res; px++) {
      final nx = (px / (_res - 1)) * 2.0 - 1.0;

      final ex = nx / 1.0;
      final ey = ny / 1.15;
      final r2 = ex * ex + ey * ey;
      if (r2 > 1.0) continue;

      final ez = math.sqrt(1.0 - r2);
      final lon = math.atan2(ex, ez);
      final lat = (ey + 1.0) / 2.0 * (_texH - 1);

      map[py][px] = _UV(lon, lat, ez);
    }
  }
  return map;
}

// ---------------------------------------------------------------------------
// Visual component
// ---------------------------------------------------------------------------

class _TolyHeadVisual extends PositionComponent {
  _TolyHeadVisual()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
          size: Vector2(10.0, 10.0),
        );

  double _angle = 0;
  double _time = 0;

  static const double _spinSpeed = 1.5;
  static const double _wobbleAmp = 0.12;
  static const double _wobbleFreq = 4.0;

  late final double _px = size.x / _res;
  late final double _py = size.y / _res;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _angle = (_angle + _spinSpeed * dt) % (2 * math.pi);
    position.y = -2.6 + math.sin(_time * _wobbleFreq) * _wobbleAmp;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..isAntiAlias = false;

    for (var py = 0; py < _res; py++) {
      for (var px = 0; px < _res; px++) {
        final uv = _uvMap[py][px];
        if (uv == null) continue;

        var lon = uv.lon + _angle;
        while (lon > math.pi) lon -= 2 * math.pi;
        while (lon < -math.pi) lon += 2 * math.pi;

        final tu = ((lon / math.pi + 1.0) / 2.0 * _texW).round() % _texW;
        final tv = uv.lat.round().clamp(0, _texH - 1);

        final ci = _getTexel(tu, tv);
        if (ci == _cTransparent) continue;

        // Shading based on angle from camera and surface normal.
        var lonFromFront = lon.abs();
        if (lonFromFront > math.pi) lonFromFront = 2 * math.pi - lonFromFront;
        final angleFade = 1.0 - (lonFromFront / math.pi) * 0.5;
        final depthFade = 0.7 + 0.3 * uv.ez;
        final shade = angleFade * depthFade;

        final baseColor = _palette[ci];
        paint.color = Color.fromARGB(
          baseColor.alpha.toInt(),
          (baseColor.red * shade).round().clamp(0, 255),
          (baseColor.green * shade).round().clamp(0, 255),
          (baseColor.blue * shade).round().clamp(0, 255),
        );

        canvas.drawRect(
          Rect.fromLTWH(px * _px, py * _py, _px + 0.02, _py + 0.02),
          paint,
        );
      }
    }

    // Solana glow ring at base.
    _drawGlowRing(canvas, size.x / 2, size.y * 0.88, size.x * 0.42, _angle);
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

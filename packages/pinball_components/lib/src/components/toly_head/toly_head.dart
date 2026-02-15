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
/// Pixel-art sphere with proper single-axis Y rotation via raycasting.
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
const int _res = 32;

/// Texture dimensions: columns = longitude (wraps 360°), rows = latitude.
const int _texW = 64;
const int _texH = 32;

/// Pre-computed UV for one pixel of the output sphere projection.
class _UV {
  const _UV(this.lon, this.lat);
  /// Longitude in radians (0 = front center, wraps ±π).
  final double lon;
  /// Latitude row in texture space (0..texH-1).
  final double lat;
}

// ---------------------------------------------------------------------------
// Palette (pixel-art Solana/Toly colors)
// ---------------------------------------------------------------------------
const _cTransparent = 0;
const _cSkin = 1;
const _cSkinDark = 2;
const _cHair = 3;
const _cBeanie = 4;
const _cBeanieBand = 5; // solana purple
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
// Texture map: procedurally defines what's painted on the sphere.
//
// Coordinate system:
//   u = 0..texW-1  (longitude, wrapping: 0 = front center)
//   v = 0..texH-1  (latitude: 0 = top, texH-1 = bottom)
//
// The face points outward at u ≈ texW/2 (center). Back of head at u ≈ 0.
// ---------------------------------------------------------------------------

int _getTexel(int u, int v) {
  // Normalize: fu in [-0.5, 0.5] where 0 = front center.
  // u=0 is front, u=texW/2 is back.
  double fu = u / _texW; // 0..1
  if (fu > 0.5) fu -= 1.0; // -0.5..0.5
  final afu = fu.abs(); // 0 = front, 0.5 = back

  final fv = v / (_texH - 1); // 0..1 top to bottom

  // --- BEANIE (top 25%) ---
  if (fv < 0.22) {
    // Nub at very top.
    if (fv < 0.06) {
      return (afu < 0.12) ? _cBeanie : _cTransparent;
    }
    // Main beanie body.
    if (fv < 0.19) {
      // Highlight stripe on one side for 3D feel.
      if (fu > 0.05 && fu < 0.15 && fv > 0.08) return _cBeanieHighlight;
      return _cBeanie;
    }
    // Purple band.
    return _cBeanieBand;
  }

  // --- FOREHEAD (22% - 34%) ---
  if (fv < 0.34) {
    if (afu > 0.42) return _cHair; // hair at sides
    if (afu > 0.35) return _cSkinDark; // temple shadow
    return _cSkin;
  }

  // --- EYEBROWS (34% - 38%) ---
  if (fv < 0.38) {
    // Left eyebrow: fu ~ -0.18 to -0.08
    if (fu > -0.20 && fu < -0.06 && fv < 0.37) return _cBrow;
    // Right eyebrow: fu ~ 0.08 to 0.18
    if (fu > 0.06 && fu < 0.20 && fv < 0.37) return _cBrow;
    if (afu > 0.42) return _cHair;
    if (afu > 0.35) return _cSkinDark;
    return _cSkin;
  }

  // --- EYES (38% - 46%) ---
  if (fv < 0.46) {
    // Left eye center at fu ≈ -0.14, right eye at fu ≈ 0.14
    for (final eyeCenter in [-0.14, 0.14]) {
      final dx = (fu - eyeCenter).abs();
      final dy = (fv - 0.42).abs();
      // Oval eye shape.
      if (dx < 0.065 && dy < 0.028) {
        // Pupil.
        if (dx < 0.02 && dy < 0.018) return _cPupil;
        // Iris.
        if (dx < 0.04 && dy < 0.024) return _cEyeIris;
        return _cEyeWhite;
      }
    }
    // Ears at extreme sides.
    if (afu > 0.38 && afu < 0.48) return _cEar;
    if (afu > 0.48) return _cHair;
    return _cSkin;
  }

  // --- NOSE (46% - 55%) ---
  if (fv < 0.55) {
    if (afu < 0.04 && fv > 0.48) return _cNose; // nose tip highlight
    if (afu < 0.025 && fv < 0.52) return _cSkinDark; // nose bridge shadow
    if (afu > 0.42) return _cHair;
    if (afu > 0.36) return _cSkinDark;
    return _cSkin;
  }

  // --- MOUTH (55% - 62%) ---
  if (fv < 0.62) {
    if (afu < 0.08 && fv > 0.57 && fv < 0.60) return _cLip;
    if (afu > 0.40) return _cHair;
    if (afu > 0.34) return _cSkinDark;
    return _cSkin;
  }

  // --- BEARD (62% - 85%) ---
  if (fv < 0.85) {
    if (afu > 0.42) return _cHair;
    // Beard covers the front and sides.
    if (afu < 0.35) {
      // Darker streaks for texture.
      final hash = ((fu * 173.7 + fv * 311.1).abs() * 999).toInt() % 5;
      return hash == 0 ? _cBeardDark : _cBeard;
    }
    return _cSkinDark;
  }

  // --- CHIN / BOTTOM (85%+) ---
  if (afu < 0.25) {
    final hash = ((fu * 173.7 + fv * 311.1).abs() * 999).toInt() % 4;
    return hash == 0 ? _cBeardDark : _cBeard;
  }
  if (afu < 0.35) return _cSkinDark;
  return _cHair;
}

// ---------------------------------------------------------------------------
// Pre-computed sphere projection lookup.
// ---------------------------------------------------------------------------

/// For each output pixel (px, py), stores the UV on the sphere surface,
/// or null if outside the sphere silhouette.
late final List<List<_UV?>> _uvMap = _buildUVMap();

List<List<_UV?>> _buildUVMap() {
  final map = List.generate(_res, (_) => List<_UV?>.filled(_res, null));

  for (var py = 0; py < _res; py++) {
    // Vertical: -1 (top) to +1 (bottom), stretched slightly for dome shape.
    final ny = (py / (_res - 1)) * 2.0 - 1.0;

    for (var px = 0; px < _res; px++) {
      final nx = (px / (_res - 1)) * 2.0 - 1.0;

      // Ellipsoid: wider horizontally, taller vertically (dome + chin).
      final ex = nx / 1.0;
      final ey = ny / 1.15;
      final r2 = ex * ex + ey * ey;
      if (r2 > 1.0) continue; // outside silhouette

      final ez = math.sqrt(1.0 - r2);

      // Longitude: angle around Y axis. atan2(x, z) gives 0 at front.
      final lon = math.atan2(ex, ez);
      // Latitude: map ey from [-1,1] to [0, texH-1].
      final lat = (ey + 1.0) / 2.0 * (_texH - 1);

      map[py][px] = _UV(lon, lat);
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
          size: Vector2(7.0, 7.0),
        );

  double _angle = 0;
  double _time = 0;

  static const double _spinSpeed = 1.8; // rad/s
  static const double _wobbleAmp = 0.12;
  static const double _wobbleFreq = 5.0;

  /// Cached pixel size (world units per pixel).
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

        // Apply Y-axis rotation: shift longitude by current angle.
        var lon = uv.lon + _angle;
        // Wrap to [-π, π].
        while (lon > math.pi) lon -= 2 * math.pi;
        while (lon < -math.pi) lon += 2 * math.pi;

        // Back-face: skip pixels facing away (lon beyond ±π/2 visible range).
        // For a full wrap we render all – the texture itself has hair on the back.

        // Convert longitude to texture column.
        // lon = 0 → front center (texW/2), lon = ±π → back center (0).
        final tu = ((lon / math.pi + 1.0) / 2.0 * _texW).round() % _texW;
        final tv = uv.lat.round().clamp(0, _texH - 1);

        final ci = _getTexel(tu, tv);
        if (ci == _cTransparent) continue;

        // Simple shading: darken pixels facing away from camera.
        var lonFromFront = lon.abs();
        if (lonFromFront > math.pi) lonFromFront = 2 * math.pi - lonFromFront;
        final shade = 1.0 - (lonFromFront / math.pi) * 0.45;

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

void _drawGlowRing(Canvas canvas, double cx, double cy, double r, double angle) {
  final ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.08
    ..shader = ui.Gradient.sweep(
      Offset(cx, cy),
      [const Color(0xFF9945FF), const Color(0xFF14F195), const Color(0xFF9945FF)],
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

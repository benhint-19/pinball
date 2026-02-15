import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template seeker_phone}
/// A smartphone that slides out from the right edge, pauses, then retracts.
/// Displays the Solana logo on screen. Replaces ChromeDino in Dino Desert.
/// {@endtemplate}
class SeekerPhone extends BodyComponent with InitialPosition, ZIndex {
  /// {@macro seeker_phone}
  SeekerPhone({Iterable<Component>? children})
      : super(
          children: [
            _SeekerPhoneVisual(),
            BumpingBehavior(strength: 15),
            ...?children,
          ],
          renderBody: false,
        ) {
    zIndex = ZIndexes.dino;
  }

  /// Horizontal slide distance in world units.
  static const slideDistance = 10.0;

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(4.0, 5.5, Vector2.zero(), 0);

    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      gravityScale: Vector2.zero(),
    );

    return world.createBody(bodyDef)
      ..createFixture(FixtureDef(shape, density: 80));
  }
}

/// Behavior that creates a PrismaticJoint for horizontal sliding.
/// The phone slides out, then back in on each tick.
class SeekerPhoneSlidingBehavior extends TimerComponent
    with ParentIsA<SeekerPhone> {
  SeekerPhoneSlidingBehavior()
      : super(
          period: 2.5,
          repeat: true,
        );

  late final PrismaticJoint _joint;

  @override
  Future<void> onLoad() async {
    final anchor = JointAnchor()
      ..initialPosition =
          parent.initialPosition + Vector2(SeekerPhone.slideDistance, 0);
    await add(anchor);

    final jointDef = _SeekerPhonePrismaticJointDef(
      phone: parent,
      anchor: anchor,
    );
    _joint = PrismaticJoint(jointDef);
    parent.world.createJoint(_joint);
  }

  @override
  void onTick() {
    super.onTick();
    _joint.motorSpeed = -_joint.motorSpeed;
  }
}

class _SeekerPhonePrismaticJointDef extends PrismaticJointDef {
  _SeekerPhonePrismaticJointDef({
    required SeekerPhone phone,
    required BodyComponent anchor,
  }) {
    initialize(
      phone.body,
      anchor.body,
      phone.body.position,
      Vector2(1, 0),
    );
    enableLimit = true;
    lowerTranslation = -SeekerPhone.slideDistance;
    upperTranslation = 0;
    enableMotor = true;
    maxMotorForce = phone.body.mass * 200;
    motorSpeed = 5.0;
  }
}

// ---------------------------------------------------------------------------
// Procedural phone visual with Solana logo
// ---------------------------------------------------------------------------

class _SeekerPhoneVisual extends PositionComponent {
  _SeekerPhoneVisual()
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
          size: Vector2(9.0, 14.0),
        );

  double _time = 0;
  double _screenGlow = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _screenGlow = 0.8 + 0.2 * math.sin(_time * 3.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;

    // Phone body (dark rounded rectangle).
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Phone bezel highlight (subtle edge).
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF3A3A5E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );

    // Screen area.
    final screenMargin = w * 0.1;
    final screenTop = h * 0.08;
    final screenBottom = h * 0.92;
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(screenMargin, screenTop, w - screenMargin, screenBottom),
      Radius.circular(w * 0.06),
    );

    // Screen background with glow.
    canvas.drawRRect(
      screenRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, screenTop),
          Offset(w / 2, screenBottom),
          [
            Color.lerp(
                const Color(0xFF0A0A1A), const Color(0xFF1A0A2A), _screenGlow)!,
            Color.lerp(
                const Color(0xFF0A1A1A), const Color(0xFF0A2A1A), _screenGlow)!,
          ],
        ),
    );

    // Draw Solana logo on screen.
    _drawSolanaLogo(
      canvas,
      w / 2,
      (screenTop + screenBottom) / 2,
      w * 0.28,
    );

    // "SEEKER" text below logo.
    final textPaint = Paint()
      ..color = Color.fromARGB((200 * _screenGlow).round(), 255, 255, 255);
    final textY = (screenTop + screenBottom) / 2 + w * 0.38;
    final letterW = w * 0.065;
    final startX = w / 2 - letterW * 3;
    // Simple block letters: S E E K E R
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(startX + letterW * i * 1.05 + letterW / 2, textY),
          width: letterW * 0.8,
          height: letterW * 1.2,
        ),
        textPaint,
      );
    }
  }

  void _drawSolanaLogo(Canvas canvas, double cx, double cy, double size) {
    // Solana "S" shape: three parallelogram bars.
    final barH = size * 0.22;
    final barW = size * 1.8;
    final gap = size * 0.35;
    final skew = size * 0.3;

    final colors = [
      Color.lerp(
          const Color(0xFF14F195), const Color(0xFF19FFB0), _screenGlow)!,
      Color.lerp(
          const Color(0xFF9945FF), const Color(0xFFBB66FF), _screenGlow)!,
      Color.lerp(
          const Color(0xFF14F195), const Color(0xFF19FFB0), _screenGlow)!,
    ];

    for (var i = 0; i < 3; i++) {
      final y = cy - gap + gap * i;
      final dir = (i == 1) ? -1.0 : 1.0; // middle bar skews opposite
      final path = Path()
        ..moveTo(cx - barW / 2, y - barH / 2)
        ..lineTo(cx + barW / 2 + skew * dir, y - barH / 2)
        ..lineTo(cx + barW / 2, y + barH / 2)
        ..lineTo(cx - barW / 2 - skew * dir, y + barH / 2)
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = colors[i],
      );
    }
  }
}

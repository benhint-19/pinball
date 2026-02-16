import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template seeker_phone}
/// A 3D robotic arm holding a smartphone with the Solana logo.
/// Slides out from the left, pauses, then retracts. Replaces ChromeDino.
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
      ..setAsBox(5.0, 5.0, Vector2.zero(), 0);

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
// 3D sprite visual - robotic arm holding phone with Solana logo
// ---------------------------------------------------------------------------

class _SeekerPhoneVisual extends SpriteComponent with HasGameRef {
  _SeekerPhoneVisual()
      : super(
          anchor: Anchor.center,
          position: Vector2(0, -1.0),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = gameRef.images.fromCache(
      Assets.images.seekerPhone.retracted.keyName,
    );

    sprite = Sprite(image);
    size = Vector2(14.0, 14.0);
  }
}

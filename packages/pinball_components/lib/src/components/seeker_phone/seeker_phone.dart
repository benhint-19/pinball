import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template seeker_phone}
/// A smartphone that slides in and out of a gap in the Dino Desert area.
/// Uses a PrismaticJoint for horizontal sliding motion with a motor.
/// {@endtemplate}
class SeekerPhone extends BodyComponent with InitialPosition, ZIndex {
  /// {@macro seeker_phone}
  SeekerPhone({Iterable<Component>? children})
      : super(
          children: [
            _SeekerPhoneSprite(),
            BumpingBehavior(strength: 15),
            ...?children,
          ],
          renderBody: false,
        ) {
    zIndex = ZIndexes.dino;
  }

  /// Horizontal slide distance in world units.
  static const slideDistance = 8.0;

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(3.0, 4.5, Vector2.zero(), 0);

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
class SeekerPhoneSlidingBehavior extends TimerComponent
    with ParentIsA<SeekerPhone> {
  SeekerPhoneSlidingBehavior()
      : super(
          period: 2.0,
          repeat: true,
        );

  late final PrismaticJoint _joint;

  @override
  Future<void> onLoad() async {
    final anchor = JointAnchor()
      ..initialPosition = parent.initialPosition + Vector2(SeekerPhone.slideDistance, 0);
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
      Vector2(1, 0), // horizontal axis
    );
    enableLimit = true;
    lowerTranslation = -SeekerPhone.slideDistance;
    upperTranslation = 0;
    enableMotor = true;
    maxMotorForce = phone.body.mass * 200;
    motorSpeed = 4.0;
  }
}

class _SeekerPhoneSprite extends SpriteAnimationComponent with HasGameRef {
  _SeekerPhoneSprite()
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
          playing: true,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = gameRef.images.fromCache(
      Assets.images.seekerPhone.slide.keyName,
    );

    const framesPerRow = 8;
    const framesPerColumn = 2;
    final textureSize = Vector2(
      spriteSheet.width / framesPerRow,
      spriteSheet.height / framesPerColumn,
    );
    // 1600x600 sheet, 200x300 per frame. /15 ≈ 13.3x20 world units.
    size = textureSize / 20;

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: framesPerRow * framesPerColumn,
        amountPerRow: framesPerRow,
        stepTime: 4.0 / (framesPerRow * framesPerColumn), // sync with slide period
        textureSize: textureSize,
      ),
    );
  }
}

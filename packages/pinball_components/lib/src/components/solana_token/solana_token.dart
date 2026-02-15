import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template solana_token}
/// Large spinning Solana token that swings in the Dino Desert area.
/// Pivots on the right edge with the left side swinging up and down.
/// {@endtemplate}
class SolanaToken extends BodyComponent
    with InitialPosition, ContactCallbacks, ZIndex {
  /// {@macro solana_token}
  SolanaToken({Iterable<Component>? children})
      : super(
          children: [
            _SolanaTokenSprite(),
            BumpingBehavior(strength: 20),
            ...?children,
          ],
          renderBody: false,
        ) {
    zIndex = ZIndexes.dino;
  }

  /// Half sweep angle for the pendulum motion.
  static const halfSweepAngle = 0.18; // ~10.3 degrees

  @override
  Body createBody() {
    // Collision shape: wide flat box offset left of pivot.
    final shape = PolygonShape()
      ..setAsBox(5.0, 2.5, Vector2(-3.0, 0), 0);

    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      gravityScale: Vector2.zero(),
    );

    return world.createBody(bodyDef)
      ..createFixture(FixtureDef(shape, density: 100));
  }
}

/// Behavior that creates a revolute joint and drives the swinging motion.
/// Follows the same pattern as [ChromeDinoSwivelingBehavior].
class SolanaTokenSwingingBehavior extends TimerComponent
    with ParentIsA<SolanaToken> {
  SolanaTokenSwingingBehavior()
      : super(
          period: 2.0, // seconds per half-cycle
          repeat: true,
        );

  late final RevoluteJoint _joint;

  @override
  Future<void> onLoad() async {
    // Pivot anchor at the right edge of the token.
    final anchor = _SolanaTokenAnchor()
      ..initialPosition = parent.initialPosition + Vector2(5.0, 0);
    await add(anchor);

    final jointDef = _SolanaTokenRevoluteJointDef(
      token: parent,
      anchor: anchor,
    );
    _joint = RevoluteJoint(jointDef);
    parent.world.createJoint(_joint);
  }

  @override
  void onTick() {
    super.onTick();
    _joint.motorSpeed = -_joint.motorSpeed;
  }
}

class _SolanaTokenAnchor extends JointAnchor {}

class _SolanaTokenRevoluteJointDef extends RevoluteJointDef {
  _SolanaTokenRevoluteJointDef({
    required SolanaToken token,
    required _SolanaTokenAnchor anchor,
  }) {
    initialize(
      token.body,
      anchor.body,
      anchor.body.position,
    );
    enableLimit = true;
    lowerAngle = -SolanaToken.halfSweepAngle;
    upperAngle = SolanaToken.halfSweepAngle;
    enableMotor = true;
    maxMotorTorque = token.body.mass * 300;
    motorSpeed = 1.5;
  }
}

/// Animated Solana token sprite.
class _SolanaTokenSprite extends SpriteAnimationComponent with HasGameRef {
  _SolanaTokenSprite()
      : super(
          anchor: Anchor.center,
          position: Vector2(-3.0, 0),
          playing: true,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = gameRef.images.fromCache(
      Assets.images.dino.solanaToken.keyName,
    );

    const framesPerRow = 16;
    const framesPerColumn = 1;
    final textureSize = Vector2(
      spriteSheet.width / framesPerRow,
      spriteSheet.height / framesPerColumn,
    );
    // 2048x128 sheet, 128x128 per frame. /10 = 12.8 world units.
    size = textureSize / 10;

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: framesPerRow * framesPerColumn,
        amountPerRow: framesPerRow,
        stepTime: 1 / 14,
        textureSize: textureSize,
      ),
    );
  }
}

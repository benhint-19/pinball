import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template toly_head}
/// Spinning 3D-rendered head of Anatoly Yakovenko (Toly), founder of Solana.
/// Uses a 32-frame Y-axis rotation sprite sheet (8x4 grid, 256x256 per frame).
/// {@endtemplate}
class TolyHead extends BodyComponent with InitialPosition, Layered, ZIndex {
  /// {@macro toly_head}
  TolyHead({Iterable<Component>? children})
      : super(
          children: [
            _TolyHeadSpriteAnimation(),
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

class _TolyHeadSpriteAnimation extends SpriteAnimationComponent
    with HasGameRef {
  _TolyHeadSpriteAnimation()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
          playing: true,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = gameRef.images.fromCache(
      Assets.images.android.spaceship.tolyHead.keyName,
    );

    const framesPerRow = 8;
    const framesPerColumn = 4;
    final textureSize = Vector2(
      spriteSheet.width / framesPerRow,
      spriteSheet.height / framesPerColumn,
    );
    // 2048x1024 sheet, 256x256 per frame. /20 = 12.8 world units.
    size = textureSize / 20;

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: framesPerRow * framesPerColumn,
        amountPerRow: framesPerRow,
        stepTime: 1 / 16,
        textureSize: textureSize,
      ),
    );
  }
}

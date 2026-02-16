import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template toly_head}
/// 3D figurine bust of Anatoly Yakovenko (Toly), founder of Solana.
/// Static sprite that wobbles when hit by the ball.
/// {@endtemplate}
class TolyHead extends BodyComponent with InitialPosition, Layered, ZIndex {
  /// {@macro toly_head}
  TolyHead({Iterable<Component>? children})
      : super(
          children: [
            _TolyHeadSprite(),
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

class _TolyHeadSprite extends SpriteComponent with HasGameRef {
  _TolyHeadSprite()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = gameRef.images.fromCache(
      Assets.images.android.spaceship.tolyHead.keyName,
    );

    sprite = Sprite(image);
    // 512x512 image, scale to ~13 world units.
    size = Vector2(13.0, 13.0);
  }
}

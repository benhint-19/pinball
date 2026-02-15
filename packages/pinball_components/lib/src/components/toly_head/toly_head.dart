import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template toly_head}
/// Spinning dome-shaped head of Anatoly Yakovenko (Toly), founder of Solana.
/// Uses a Nano-Banana-generated pixel art sprite sheet with 8 rotation frames.
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

/// Sprite-sheet-based spinning head with wobble.
class _TolyHeadSpriteAnimation extends SpriteAnimationComponent
    with HasGameRef {
  _TolyHeadSpriteAnimation()
      : super(
          anchor: Anchor.center,
          position: Vector2(-0.24, -2.6),
          playing: true,
        );

  double _time = 0;

  static const double _wobbleAmp = 0.12;
  static const double _wobbleFreq = 5.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = gameRef.images.fromCache(
      Assets.images.android.spaceship.tolyHead.keyName,
    );

    const framesPerRow = 16;
    const framesPerColumn = 1;
    final textureSize = Vector2(
      spriteSheet.width / framesPerRow,
      spriteSheet.height / framesPerColumn,
    );
    // Scale: 2048x128 sheet, each frame 128x128.
    // /10 = 12.8 world units – good visible size on the spaceship.
    size = textureSize / 10;

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: framesPerRow * framesPerColumn,
        amountPerRow: framesPerRow,
        stepTime: 1 / 12, // 12 FPS = smooth spin in ~1.3s
        textureSize: textureSize,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // Wobble bounce effect.
    position.y = -2.6 + math.sin(_time * _wobbleFreq) * _wobbleAmp;
  }
}

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template solana_coin}
/// A 3D-rendered Solana coin in Flutter Forest / Shiba's Park.
/// Bobs gently when idle, flips end-over-end when hit by the ball.
/// {@endtemplate}
class SolanaCoin extends BodyComponent with InitialPosition, ContactCallbacks, ZIndex {
  /// {@macro solana_coin}
  SolanaCoin({Iterable<Component>? children})
      : super(
          children: [
            _SolanaCoinSprite(),
            BumpingBehavior(strength: 15),
            ...?children,
          ],
          renderBody: false,
        ) {
    zIndex = ZIndexes.flutterForest + 1;
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 4.0;
    final bodyDef = BodyDef(position: initialPosition);
    return world.createBody(bodyDef)
      ..createFixtureFromShape(shape, density: 0);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    final sprite = children.whereType<_SolanaCoinSprite>().firstOrNull;
    sprite?.triggerFlip();
  }
}

/// Manages idle bob + flip animation states for the coin.
class _SolanaCoinSprite extends PositionComponent with HasGameRef {
  _SolanaCoinSprite()
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
        );

  late final SpriteAnimationComponent _idleSprite;
  late final SpriteAnimationComponent _flipSprite;

  double _time = 0;
  bool _flipping = false;
  double _flipTimer = 0;

  static const double _bobAmplitude = 0.3;
  static const double _bobFrequency = 2.0;
  static const double _flipDuration = 1.0; // seconds for full flip animation

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load idle sprite sheet (4x1 grid, 200x200)
    final idleSheet = gameRef.images.fromCache(
      Assets.images.solanaCoin.idle.keyName,
    );
    const idleCols = 4;
    final idleFrameSize = Vector2(
      idleSheet.width / idleCols,
      idleSheet.height.toDouble(),
    );
    final displaySize = idleFrameSize / 15;

    _idleSprite = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        idleSheet,
        SpriteAnimationData.sequenced(
          amount: idleCols,
          amountPerRow: idleCols,
          stepTime: 0.25,
          textureSize: idleFrameSize,
        ),
      ),
      size: displaySize,
      anchor: Anchor.center,
      playing: true,
    );

    // Load flip sprite sheet (6x4 grid, 200x200)
    final flipSheet = gameRef.images.fromCache(
      Assets.images.solanaCoin.flip.keyName,
    );
    const flipCols = 6;
    const flipRows = 4;
    final flipFrameSize = Vector2(
      flipSheet.width / flipCols,
      flipSheet.height / flipRows,
    );

    _flipSprite = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        flipSheet,
        SpriteAnimationData.sequenced(
          amount: flipCols * flipRows,
          amountPerRow: flipCols,
          stepTime: _flipDuration / (flipCols * flipRows),
          textureSize: flipFrameSize,
          loop: false,
        ),
      ),
      size: displaySize,
      anchor: Anchor.center,
      playing: false,
    );

    size = displaySize;
    await add(_idleSprite);
    await add(_flipSprite);
    _flipSprite.opacity = 0;
  }

  /// Trigger the flip animation (called on ball contact).
  void triggerFlip() {
    if (_flipping) return;
    _flipping = true;
    _flipTimer = 0;
    _idleSprite.opacity = 0;
    _flipSprite.opacity = 1;
    _flipSprite.animationTicker?.reset();
    _flipSprite.playing = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_flipping) {
      _flipTimer += dt;
      // Rise and fall during flip
      final t = _flipTimer / _flipDuration;
      position.y = -3.0 * math.sin(t * math.pi);

      if (_flipTimer >= _flipDuration) {
        _flipping = false;
        _flipTimer = 0;
        _flipSprite.playing = false;
        _flipSprite.opacity = 0;
        _idleSprite.opacity = 1;
        position.y = 0;
      }
    } else {
      // Gentle bob
      position.y = math.sin(_time * _bobFrequency * 2 * math.pi) * _bobAmplitude;
    }
  }
}


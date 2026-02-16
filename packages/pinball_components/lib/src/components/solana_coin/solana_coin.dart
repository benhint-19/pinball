import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template solana_coin}
/// A 3D Solana token hovering in Flutter Forest / Shiba's Park.
/// Bobs gently when idle. Lights up when hit by the ball.
/// {@endtemplate}
class SolanaCoin extends BodyComponent
    with InitialPosition, ContactCallbacks, ZIndex {
  /// {@macro solana_coin}
  SolanaCoin({Iterable<Component>? children})
      : super(
          children: [
            _SolanaCoinVisual(),
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
    final visual = children.whereType<_SolanaCoinVisual>().firstOrNull;
    visual?.triggerGlow();
  }
}

class _SolanaCoinVisual extends PositionComponent with HasGameRef {
  _SolanaCoinVisual()
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
          size: Vector2(10.0, 10.0),
        );

  late final SpriteComponent _idleSprite;
  late final SpriteComponent _litSprite;

  double _time = 0;
  bool _glowing = false;
  double _glowTimer = 0;

  static const double _bobAmplitude = 0.4;
  static const double _bobFrequency = 1.5;
  static const double _glowDuration = 0.8;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final idleImage = gameRef.images.fromCache(
      Assets.images.solanaCoin.idle.keyName,
    );
    final litImage = gameRef.images.fromCache(
      Assets.images.solanaCoin.lit.keyName,
    );

    _idleSprite = SpriteComponent(
      sprite: Sprite(idleImage),
      size: size,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );

    _litSprite = SpriteComponent(
      sprite: Sprite(litImage),
      size: size,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    )..opacity = 0;

    await add(_idleSprite);
    await add(_litSprite);
  }

  void triggerGlow() {
    if (_glowing) return;
    _glowing = true;
    _glowTimer = 0;
    _litSprite.opacity = 1;
    _idleSprite.opacity = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_glowing) {
      _glowTimer += dt;
      if (_glowTimer >= _glowDuration) {
        _glowing = false;
        _glowTimer = 0;
        _litSprite.opacity = 0;
        _idleSprite.opacity = 1;
      } else {
        // Pulse the lit sprite opacity.
        final t = _glowTimer / _glowDuration;
        _litSprite.opacity = 1.0 - t * t; // fade out
        _idleSprite.opacity = t * t;
      }
    }

    // Gentle bob.
    position.y = math.sin(_time * _bobFrequency * 2 * math.pi) * _bobAmplitude;
  }
}

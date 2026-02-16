import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_components/src/components/bumping_behavior.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template solana_coin}
/// A 3D-rendered Solana token hovering in Flutter Forest.
/// Uses Gemini-generated sprites for idle and lit states,
/// bobs vertically, and lights up on ball contact.
/// {@endtemplate}
class SolanaCoin extends BodyComponent
    with InitialPosition, ContactCallbacks, ZIndex {
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
    zIndex = ZIndexes.score;
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 5.0;
    final bodyDef = BodyDef(position: initialPosition);
    return world.createBody(bodyDef)
      ..createFixtureFromShape(shape, density: 0);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    final sprite = children.whereType<_SolanaCoinSprite>().firstOrNull;
    sprite?.triggerGlow();
  }
}

class _SolanaCoinSprite extends SpriteComponent with HasGameRef {
  _SolanaCoinSprite()
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
          size: Vector2(13.0, 13.0),
        );

  late final Sprite _idleSprite;
  late final Sprite _litSprite;

  bool _glowing = false;
  double _glowTimer = 0;
  double _time = 0;
  static const _glowDuration = 0.8;

  void triggerGlow() {
    _glowing = true;
    _glowTimer = 0;
    sprite = _litSprite;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final idleImage = gameRef.images.fromCache(
      Assets.images.solanaCoin.idle.keyName,
    );
    final litImage = gameRef.images.fromCache(
      Assets.images.solanaCoin.lit.keyName,
    );

    _idleSprite = Sprite(idleImage);
    _litSprite = Sprite(litImage);

    sprite = _idleSprite;
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
        sprite = _idleSprite;
      }
    }

    // Gentle hover bob.
    position.y = math.sin(_time * 0.8 * 2 * math.pi) * 0.4;
  }
}

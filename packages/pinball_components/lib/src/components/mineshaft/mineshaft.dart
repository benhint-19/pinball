import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template mineshaft}
/// Decorative mine entrance sprite positioned above the spaceship
/// in Android Acres / Miner's Mine. Purely visual, no physics body.
/// {@endtemplate}
class Mineshaft extends SpriteComponent with HasGameRef, ZIndex {
  /// {@macro mineshaft}
  Mineshaft({required Vector2 position})
      : super(
          anchor: Anchor.center,
          position: position,
        ) {
    zIndex = ZIndexes.spaceshipRampBoardOpening;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = gameRef.images.fromCache(
      Assets.images.android.mineshaft.keyName,
    );

    sprite = Sprite(image);

    // 200x300 raw / 15 ≈ 13.3x20 world units. Scale to fit above saucer.
    size = Vector2(image.width / 15, image.height / 15);
  }
}

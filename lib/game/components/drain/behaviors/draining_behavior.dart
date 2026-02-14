import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:pinball/game/game.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// Handles removing a [Ball] from the game.
class DrainingBehavior extends ContactBehavior<Drain> with HasGameRef {
  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is! Ball) return;

    other.removeFromParent();

    // Count balls *excluding* the one being removed (it hasn't been removed
    // from the tree yet since removeFromParent is async).
    final ballsLeft =
        gameRef.descendants().whereType<Ball>().where((b) => b != other).length;
    if (ballsLeft == 0) {
      try {
        ancestors()
            .whereType<FlameBlocProvider<GameBloc, GameState>>()
            .first
            .bloc
            .add(const RoundLost());
      } catch (_) {
        // Guard against missing ancestor during teardown.
      }
    }
  }
}

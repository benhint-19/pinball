import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template bumping_behavior}
/// Makes any [BodyComponent] that contacts with [parent] bounce off.
/// {@endtemplate}
class BumpingBehavior extends ContactBehavior {
  /// {@macro bumping_behavior}
  BumpingBehavior({required double strength})
      : assert(strength >= 0, "Strength can't be negative."),
        _strength = strength;

  /// Determines how strong the bump is.
  final double _strength;

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    if (other is! BodyComponent) return;

    // Push the ball directly away from the parent body center.
    // Using position delta instead of contact normal avoids trapping
    // at multi-fixture junctions (e.g. slingshot circle/edge seams)
    // where opposing normals cancel each other out.
    final direction = other.body.position - parent.body.position;
    final length = direction.length;
    if (length == 0) return;
    direction.scale(1 / length); // normalize

    other.body.applyLinearImpulse(
      direction..scale(other.body.mass * _strength),
    );
  }
}

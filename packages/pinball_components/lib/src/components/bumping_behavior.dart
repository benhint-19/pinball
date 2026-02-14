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

  final WorldManifold _worldManifold = WorldManifold();

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    if (other is! BodyComponent) return;

    contact.getWorldManifold(_worldManifold);
    final normal = _worldManifold.normal;

    // WorldManifold.normal points from bodyA → bodyB.
    // We want it pointing from parent → other (pushing other away).
    // If parent is bodyB, the normal points the wrong way — negate it.
    if (contact.bodyB == parent.body) {
      normal.negate();
    }

    other.body.applyLinearImpulse(
      normal..scale(other.body.mass * _strength),
    );
  }
}

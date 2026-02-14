import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:pinball_components/pinball_components.dart';

/// Scales the ball's gravity according to its position on the board.
class BallGravitatingBehavior extends Component
    with ParentIsA<Ball>, HasGameRef<Forge2DGame> {
  @override
  void update(double dt) {
    super.update(dt);
    if (!isMounted || !parent.isMounted) return;

    final defaultGravity = gameRef.world.gravity.y;

    final maxXDeviationFromCenter = BoardDimensions.bounds.width / 2;
    const maxXGravityPercentage =
        (1 - BoardDimensions.perspectiveShrinkFactor) / 2;
    final xDeviationFromCenter = parent.body.position.x;

    final positionalXForce = ((xDeviationFromCenter / maxXDeviationFromCenter) *
            maxXGravityPercentage) *
        defaultGravity;

    // Guard: if positionalXForce exceeds defaultGravity (ball beyond board
    // bounds), the sqrt argument goes negative → NaN → poisons the physics
    // solver → entire game freezes. Clamp to keep the value valid.
    final sqArg =
        math.pow(defaultGravity, 2) - math.pow(positionalXForce, 2);
    final positionalYForce = math.sqrt(math.max(0, sqArg));

    final gravityOverride = parent.body.gravityOverride;
    if (gravityOverride != null) {
      gravityOverride.setValues(positionalXForce, positionalYForce);
    } else {
      parent.body.gravityOverride = Vector2(positionalXForce, positionalYForce);
    }
  }
}

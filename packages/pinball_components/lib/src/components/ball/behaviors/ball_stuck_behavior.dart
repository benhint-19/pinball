import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';

/// Detects when the [Ball] is stuck (near-zero velocity) and applies a
/// small random impulse to free it.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  static const _velocityThreshold = 2.0;
  static const _stuckDuration = 1.5;

  final _random = math.Random();
  double _stuckTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final velocity = parent.body.linearVelocity;
    if (velocity.length2 < _velocityThreshold * _velocityThreshold) {
      _stuckTimer += dt;
      if (_stuckTimer >= _stuckDuration) {
        // Kick the ball in a random-ish downward direction.
        final xKick = (_random.nextDouble() - 0.5) * 20;
        parent.body.linearVelocity = Vector2(xKick, 15);
        _stuckTimer = 0;
      }
    } else {
      _stuckTimer = 0;
    }
  }
}

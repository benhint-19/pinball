import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';

/// Detects when the [Ball] is stuck and nudges it free.
///
/// Checks ball displacement over a time window. If the ball hasn't moved
/// far enough, it is considered stuck and gets a gentle downward kick.
/// This mirrors real pinball machines' "ball search" mechanism.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  // Must exceed SparkyComputer's 1.5s hold time to avoid false triggers.
  static const _checkInterval = 2.5;
  static const _minDisplacement = 2.0;

  final _random = math.Random();
  double _timer = 0;
  double _lastX = 0;
  double _lastY = 0;
  bool _initialized = false;

  @override
  void update(double dt) {
    super.update(dt);
    final pos = parent.body.position;

    if (!_initialized) {
      _lastX = pos.x;
      _lastY = pos.y;
      _initialized = true;
      return;
    }

    _timer += dt;
    if (_timer >= _checkInterval) {
      final dx = pos.x - _lastX;
      final dy = pos.y - _lastY;
      final distSq = dx * dx + dy * dy;

      if (distSq < _minDisplacement * _minDisplacement) {
        // Restore gravity in case stop() was called without resume().
        parent.resume();
        // Nudge downward with slight horizontal randomness.
        final xKick = (_random.nextDouble() - 0.5) * 20;
        parent.body.linearVelocity = Vector2(xKick, 15);
      }

      _lastX = pos.x;
      _lastY = pos.y;
      _timer = 0;
    }
  }
}

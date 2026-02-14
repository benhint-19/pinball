import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';

/// Detects when the [Ball] is stuck and applies an impulse to free it.
///
/// Tracks the ball's position over a window of time. If the ball hasn't
/// moved far enough, it is considered stuck and gets a kick.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  static const _checkInterval = 0.8;
  static const _minDisplacement = 3.0;

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
      final displacement = dx * dx + dy * dy;

      if (displacement < _minDisplacement * _minDisplacement) {
        // Restore gravity in case stop() was called without resume().
        parent.resume();
        // Kick the ball downward with some randomness.
        final xKick = (_random.nextDouble() - 0.5) * 30;
        parent.body.linearVelocity = Vector2(xKick, 20);
      }

      _lastX = pos.x;
      _lastY = pos.y;
      _timer = 0;
    }
  }
}

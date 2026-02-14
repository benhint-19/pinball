import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';

/// Detects when the [Ball] is stuck and nudges it free.
///
/// Checks ball displacement over a short window. If the ball hasn't moved
/// far enough, it gets a kick. Skips checks while the ball is intentionally
/// stopped (gravityScale zero, e.g. during SparkyComputer turbo charge).
///
/// Each consecutive stuck detection escalates the kick strength.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  static const _checkInterval = 0.5;
  static const _minDisplacement = 1.5;

  final _random = math.Random();
  double _timer = 0;
  double _lastX = 0;
  double _lastY = 0;
  bool _initialized = false;
  int _consecutiveStucks = 0;

  @override
  void update(double dt) {
    super.update(dt);

    // Skip while ball is intentionally stopped (stop() zeroes gravityScale).
    final gs = parent.body.gravityScale;
    if (gs != null && gs.x == 0 && gs.y == 0) {
      _timer = 0;
      return;
    }

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
        _consecutiveStucks++;
        parent.resume();
        final strength = 20.0 + (_consecutiveStucks * 10);
        final xKick = (_random.nextDouble() - 0.5) * strength;
        parent.body.linearVelocity = Vector2(xKick, strength);
      } else {
        _consecutiveStucks = 0;
      }

      _lastX = pos.x;
      _lastY = pos.y;
      _timer = 0;
    }
  }
}

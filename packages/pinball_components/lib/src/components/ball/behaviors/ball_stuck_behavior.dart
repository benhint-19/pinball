import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';

/// Detects when the [Ball] is stuck and nudges it free.
///
/// Checks ball displacement over a time window. If the ball hasn't moved
/// far enough, it is considered stuck and gets a strong kick.
/// This mirrors real pinball machines' "ball search" mechanism.
///
/// Each consecutive stuck detection escalates the kick strength to break
/// free from deeper geometry traps.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  // Must exceed SparkyComputer's 1.5s hold time to avoid false triggers.
  static const _checkInterval = 2.0;
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
        // Restore gravity in case stop() was called without resume().
        parent.resume();
        // Escalate kick strength each consecutive stuck detection.
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

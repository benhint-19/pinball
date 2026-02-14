import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// Safety net that nudges the [Ball] when it hasn't moved in a while.
///
/// Samples position every [_sampleInterval] into a ring buffer spanning
/// [_windowSeconds]. When net displacement over that window is below
/// [_stuckThreshold], applies a random impulse to free the ball.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  static const _sampleInterval = 0.1;
  static const _windowSeconds = 2.0;
  static const _stuckThreshold = 2.0;
  static const _bufferSize = 20; // _windowSeconds / _sampleInterval
  static const _kickStrength = 40.0;

  final _random = math.Random();
  final List<double> _xBuf = List.filled(_bufferSize, 0);
  final List<double> _yBuf = List.filled(_bufferSize, 0);
  int _head = 0;
  int _sampleCount = 0;
  double _sampleTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (!isMounted || !parent.isMounted) return;

    final gs = parent.body.gravityScale;
    if (gs != null && gs.x == 0 && gs.y == 0) {
      _resetBuffer();
      return;
    }

    if (parent.layer == Layer.launcher) {
      _resetBuffer();
      return;
    }

    _sampleTimer += dt;
    if (_sampleTimer < _sampleInterval) return;
    _sampleTimer -= _sampleInterval;

    final pos = parent.body.position;

    _xBuf[_head] = pos.x;
    _yBuf[_head] = pos.y;
    _head = (_head + 1) % _bufferSize;
    _sampleCount++;

    if (_sampleCount < _bufferSize) return;

    final oldX = _xBuf[_head % _bufferSize];
    final oldY = _yBuf[_head % _bufferSize];
    final dx = pos.x - oldX;
    final dy = pos.y - oldY;

    if (dx * dx + dy * dy < _stuckThreshold * _stuckThreshold) {
      parent.resume();
      // Random direction kick biased upward (negative Y).
      final angle = _random.nextDouble() * math.pi; // 0 to π (upper half)
      parent.body.linearVelocity = Vector2(
        math.cos(angle) * _kickStrength,
        -math.sin(angle) * _kickStrength,
      );
    }
  }

  void _resetBuffer() {
    _sampleCount = 0;
    _head = 0;
    _sampleTimer = 0;
  }
}

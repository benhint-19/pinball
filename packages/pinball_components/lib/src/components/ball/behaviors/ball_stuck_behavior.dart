import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// Detects when the [Ball] is stuck and frees it.
///
/// Samples the ball position every [_sampleInterval] seconds into a ring
/// buffer.  When the buffer is full, compares the current position to the
/// oldest sample.  If net displacement is below [_stuckThreshold] over the
/// full [_windowSeconds] window, the ball is considered stuck.
///
/// Recovery: first two detections apply a random kick; third and subsequent
/// detections teleport the ball to a safe position above the flippers.
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  static const _sampleInterval = 0.1;
  static const _windowSeconds = 2.0;
  static const _stuckThreshold = 2.0; // units
  static const _kicksBeforeTeleport = 2;

  // Above the flippers (Y=43.6), centered on the board.
  static final _safePosition = Vector2(0, 35);

  static const _bufferSize = 20; // _windowSeconds / _sampleInterval

  final _random = math.Random();
  final List<double> _xBuf = List.filled(_bufferSize, 0);
  final List<double> _yBuf = List.filled(_bufferSize, 0);
  int _head = 0;
  int _sampleCount = 0;
  double _sampleTimer = 0;
  int _stuckCount = 0;

  @override
  void update(double dt) {
    super.update(dt);

    // Skip while intentionally stopped.
    final gs = parent.body.gravityScale;
    if (gs != null && gs.x == 0 && gs.y == 0) {
      _resetBuffer();
      return;
    }

    // Skip while on the launcher (waiting for plunger).
    if (parent.layer == Layer.launcher) {
      _resetBuffer();
      return;
    }

    _sampleTimer += dt;
    if (_sampleTimer < _sampleInterval) return;
    _sampleTimer -= _sampleInterval;

    final pos = parent.body.position;

    // Write current position into the ring buffer.
    _xBuf[_head] = pos.x;
    _yBuf[_head] = pos.y;
    _head = (_head + 1) % _bufferSize;
    _sampleCount++;

    // Need a full window before we can judge.
    if (_sampleCount < _bufferSize) return;

    // Oldest sample is at _head (it just got overwritten above, so the
    // oldest surviving sample is at _head which now points to the slot
    // we're about to overwrite next time — but we already incremented,
    // so _head IS the oldest).
    final oldX = _xBuf[_head % _bufferSize];
    final oldY = _yBuf[_head % _bufferSize];
    final dx = pos.x - oldX;
    final dy = pos.y - oldY;

    if (dx * dx + dy * dy < _stuckThreshold * _stuckThreshold) {
      _stuckCount++;
      parent.resume();

      if (_stuckCount >= _kicksBeforeTeleport) {
        _teleport();
      } else {
        _kick();
      }
    } else {
      _stuckCount = 0;
    }
  }

  void _kick() {
    final strength = 30.0 + (_stuckCount * 15);
    final xKick = (_random.nextDouble() - 0.5) * strength;
    parent.body.linearVelocity = Vector2(xKick, -strength);
  }

  void _teleport() {
    parent.resume();
    parent.body.setTransform(_safePosition, parent.body.angle);
    // Negative Y = upward on screen, but we want it to fall down toward
    // flippers, so give it a small positive-Y (downward) velocity.
    parent.body.linearVelocity = Vector2(0, 10);
    parent.body.angularVelocity = 0;
    _resetBuffer();
    _stuckCount = 0;
  }

  void _resetBuffer() {
    _sampleCount = 0;
    _head = 0;
    _sampleTimer = 0;
  }
}

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// Detects when the [Ball] is stuck and nudges it free.
///
/// Uses two-tier detection:
/// - **Fast** (0.3 s, 0.5 unit threshold): catches truly stationary balls and
///   kicks them. After 3 consecutive kicks, teleports.
/// - **Slow** (1.5 s, 3.0 unit threshold): catches balls that are vibrating /
///   oscillating between surfaces but not making real progress. Teleports
///   immediately.
///
/// Skips checks while the ball is intentionally stopped (gravityScale zero).
class BallStuckBehavior extends Component with ParentIsA<Ball> {
  // ── Fast tier ──
  static const _fastInterval = 0.3;
  static const _fastThreshold = 0.5;
  static const _fastTeleportAfter = 3; // kicks before teleport

  // ── Slow tier ──
  static const _slowInterval = 1.5;
  static const _slowThreshold = 3.0;

  // ── Teleport target: above the flippers ──
  static final _safePosition = Vector2(0, 55);

  final _random = math.Random();

  double _fastTimer = 0;
  double _slowTimer = 0;
  double _fastX = 0;
  double _fastY = 0;
  double _slowX = 0;
  double _slowY = 0;
  bool _initialized = false;
  int _kickCount = 0;

  @override
  void update(double dt) {
    super.update(dt);

    // Skip while ball is intentionally stopped (stop() zeroes gravityScale).
    final gs = parent.body.gravityScale;
    if (gs != null && gs.x == 0 && gs.y == 0) {
      _reset();
      return;
    }

    // Skip while ball is on the launcher (waiting for plunger pull).
    if (parent.layer == Layer.launcher) {
      _reset();
      return;
    }

    final pos = parent.body.position;

    if (!_initialized) {
      _fastX = pos.x;
      _fastY = pos.y;
      _slowX = pos.x;
      _slowY = pos.y;
      _initialized = true;
      return;
    }

    _fastTimer += dt;
    _slowTimer += dt;

    // ── Slow tier: catches oscillating/vibrating stuck balls ──
    if (_slowTimer >= _slowInterval) {
      final dx = pos.x - _slowX;
      final dy = pos.y - _slowY;
      if (dx * dx + dy * dy < _slowThreshold * _slowThreshold) {
        _teleport();
        return;
      }
      _slowX = pos.x;
      _slowY = pos.y;
      _slowTimer = 0;
    }

    // ── Fast tier: catches truly stationary balls ──
    if (_fastTimer >= _fastInterval) {
      final dx = pos.x - _fastX;
      final dy = pos.y - _fastY;
      if (dx * dx + dy * dy < _fastThreshold * _fastThreshold) {
        _kickCount++;
        parent.resume();
        if (_kickCount >= _fastTeleportAfter) {
          _teleport();
        } else {
          _kick();
        }
      } else {
        _kickCount = 0;
      }
      _fastX = pos.x;
      _fastY = pos.y;
      _fastTimer = 0;
    }
  }

  void _reset() {
    _fastTimer = 0;
    _slowTimer = 0;
    _kickCount = 0;
    _initialized = false;
  }

  void _kick() {
    final strength = 30.0 + (_kickCount * 15);
    final xKick = (_random.nextDouble() - 0.5) * strength;
    parent.body.linearVelocity = Vector2(xKick, strength);
  }

  void _teleport() {
    parent.resume();
    parent.body.setTransform(_safePosition, parent.body.angle);
    parent.body.linearVelocity = Vector2(0, 15);
    parent.body.angularVelocity = 0;
    _kickCount = 0;
    // Reset both tiers so we don't immediately re-trigger.
    _fastX = _safePosition.x;
    _fastY = _safePosition.y;
    _slowX = _safePosition.x;
    _slowY = _safePosition.y;
    _fastTimer = 0;
    _slowTimer = 0;
  }
}

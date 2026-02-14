import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:geometry/geometry.dart';

/// {@template arc_shape}
/// Creates an arc.
/// {@endtemplate}
class ArcShape extends ChainShape {
  /// {@macro arc_shape}
  ArcShape({
    required this.center,
    required this.arcRadius,
    required this.angle,
    this.rotation = 0,
  }) {
    createChain(
      calculateArc(
        center: center,
        radius: arcRadius,
        angle: angle,
        offsetAngle: rotation,
      ),
    );
    _setGhostVertices();
  }

  /// The center of the arc.
  final Vector2 center;

  /// The radius of the arc.
  final double arcRadius;

  /// Specifies the size of the arc, in radians.
  ///
  /// For example, two pi returns a complete circumference.
  final double angle;

  /// Angle in radians to rotate the arc around its [center].
  final double rotation;

  /// Extrapolate ghost vertices from the chain endpoints so the contact
  /// solver can filter out internal-edge ghost collisions at junctions
  /// with adjacent fixtures.
  void _setGhostVertices() {
    if (vertices.length >= 2) {
      prevVertex = vertices[0] * 2 - vertices[1];
      nextVertex = vertices.last * 2 - vertices[vertices.length - 2];
    }
  }
}

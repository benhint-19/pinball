import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:geometry/geometry.dart';

/// {@template bezier_curve_shape}
/// Creates a bezier curve.
/// {@endtemplate}
class BezierCurveShape extends ChainShape {
  /// {@macro bezier_curve_shape}
  BezierCurveShape({
    required this.controlPoints,
  }) {
    createChain(calculateBezierCurve(controlPoints: controlPoints));
    _setGhostVertices();
  }

  /// Specifies the control points of the curve.
  ///
  /// First and last [controlPoints] set the beginning and end of the curve,
  /// inner points between them set its final shape.
  final List<Vector2> controlPoints;

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

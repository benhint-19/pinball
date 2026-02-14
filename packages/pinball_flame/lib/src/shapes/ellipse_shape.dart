import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:geometry/geometry.dart';

/// {@template ellipse_shape}
/// Creates an ellipse.
/// {@endtemplate}
class EllipseShape extends ChainShape {
  /// {@macro ellipse_shape}
  EllipseShape({
    required this.center,
    required this.majorRadius,
    required this.minorRadius,
  }) {
    final points = calculateEllipse(
      center: center,
      majorRadius: majorRadius,
      minorRadius: minorRadius,
    );
    // calculateEllipse sweeps 0..2π inclusive, so the first and last points
    // are identical. Remove the duplicate so createLoop can properly close
    // the chain with correct ghost vertices at the seam.
    points.removeLast();
    createLoop(points);
  }

  /// The top left corner of the ellipse.
  ///
  /// Where the initial painting begins.
  final Vector2 center;

  /// Major radius is specified by [majorRadius].
  final double majorRadius;

  /// Minor radius is specified by [minorRadius].
  final double minorRadius;

  /// Rotates the ellipse by a given [angle] in radians.
  void rotate(double angle) {
    for (final vector in vertices) {
      vector.rotate(angle);
    }
  }
}

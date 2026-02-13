import 'package:flutter/material.dart';

/// 8-bit pixel art Solana logo with gradient from purple to green.
class SolanaPixelLogo extends StatelessWidget {
  const SolanaPixelLogo({Key? key, this.width = 180}) : super(key: key);

  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 16 / 22),
      painter: const _SolanaLogoPainter(),
    );
  }
}

class _SolanaLogoPainter extends CustomPainter {
  const _SolanaLogoPainter();

  static const _purple = Color(0xFF9945FF);
  static const _green = Color(0xFF14F195);

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 22;
    final mid = Color.lerp(_purple, _green, 0.5)!;

    // Three bars forming the Solana "S" logo
    // Top bar: / slope on left, flat right edge
    _drawBar(canvas, px, 0, _purple, slopeOnLeft: true);
    // Middle bar: flat left edge, \ slope on right
    _drawBar(canvas, px, 6, mid, slopeOnLeft: false);
    // Bottom bar: / slope on left, flat right edge
    _drawBar(canvas, px, 12, _green, slopeOnLeft: true);
  }

  void _drawBar(
    Canvas canvas,
    double px,
    int startRow,
    Color color, {
    required bool slopeOnLeft,
  }) {
    final paint = Paint()..color = color;

    for (var row = 0; row < 4; row++) {
      final double left;
      final double right;
      if (slopeOnLeft) {
        left = (3 - row) * px;
        right = 22 * px;
      } else {
        left = 0;
        right = (19 + row) * px;
      }
      canvas.drawRect(
        Rect.fromLTWH(left, (startRow + row) * px, right - left, px),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

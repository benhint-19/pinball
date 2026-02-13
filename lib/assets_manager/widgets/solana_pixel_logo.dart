import 'package:flutter/material.dart';

/// 8-bit pixel art Solana logo with official gradient (purple → green).
///
/// Uses [ShaderMask] to apply a diagonal gradient from purple (bottom-left)
/// to green (top-right) matching official Solana branding.
class SolanaPixelLogo extends StatelessWidget {
  const SolanaPixelLogo({Key? key, this.width = 180}) : super(key: key);

  final double width;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF9945FF), Color(0xFF14F195)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: CustomPaint(
        size: Size(width, width * 16 / 22),
        painter: const _SolanaLogoPainter(),
      ),
    );
  }
}

class _SolanaLogoPainter extends CustomPainter {
  const _SolanaLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 22;
    final paint = Paint()..color = const Color(0xFFFFFFFF);

    // Grid: 22 cols x 16 rows
    // Each bar: 4 rows tall, 19 cols wide, slant offset = 3 cols
    // Bars are parallelograms (constant width, shifted per row)

    // Top bar: / slant (rows 0-3) — shifts left going down
    for (var row = 0; row < 4; row++) {
      final left = (3 - row) * px;
      final right = (22 - row) * px;
      canvas.drawRect(
        Rect.fromLTWH(left, row * px, right - left, px),
        paint,
      );
    }

    // Middle bar: \ slant (rows 6-9) — shifts right going down
    for (var row = 0; row < 4; row++) {
      final left = row * px;
      final right = (19 + row) * px;
      canvas.drawRect(
        Rect.fromLTWH(left, (6 + row) * px, right - left, px),
        paint,
      );
    }

    // Bottom bar: / slant (rows 12-15) — shifts left going down
    for (var row = 0; row < 4; row++) {
      final left = (3 - row) * px;
      final right = (22 - row) * px;
      canvas.drawRect(
        Rect.fromLTWH(left, (12 + row) * px, right - left, px),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

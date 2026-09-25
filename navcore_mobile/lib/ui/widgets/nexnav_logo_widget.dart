import 'dart:math' as math;
import 'package:flutter/material.dart';

class NexNavLogoWidget extends StatelessWidget {
  final double size;
  final bool showBackground;

  const NexNavLogoWidget({
    super.key,
    this.size = 38,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _NexNavLogoPainter(),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _NexNavLogoPainter(),
      ),
    );
  }
}

class _NexNavLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Skewed Horizontal Floor Layers (3D Stacked Planes)
    final layerPaintTop = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final layerPaintMid = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    final layerPaintBot = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final skew = w * 0.10;

    // Top Layer (Light Slate)
    final pathTop = Path()
      ..moveTo(w * 0.18 + skew, h * 0.36)
      ..lineTo(w * 0.82 + skew, h * 0.36)
      ..lineTo(w * 0.82 - skew, h * 0.43)
      ..lineTo(w * 0.18 - skew, h * 0.43)
      ..close();
    canvas.drawPath(pathTop, layerPaintTop);

    // Middle Layer (Medium Slate)
    final pathMid = Path()
      ..moveTo(w * 0.14 + skew, h * 0.52)
      ..lineTo(w * 0.86 + skew, h * 0.52)
      ..lineTo(w * 0.86 - skew, h * 0.59)
      ..lineTo(w * 0.14 - skew, h * 0.59)
      ..close();
    canvas.drawPath(pathMid, layerPaintMid);

    // Bottom Layer (Vivid Blue)
    final pathBot = Path()
      ..moveTo(w * 0.08 + skew, h * 0.68)
      ..lineTo(w * 0.92 + skew, h * 0.68)
      ..lineTo(w * 0.92 - skew, h * 0.76)
      ..lineTo(w * 0.08 - skew, h * 0.76)
      ..close();
    canvas.drawPath(pathBot, layerPaintBot);

    // 2. Ripple Ring beneath Map Pin Base
    final ringPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.80),
        width: w * 0.32,
        height: h * 0.10,
      ),
      ringPaint,
    );

    // 3. Central Blue Location Map Pin Body
    final pinPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final pinCenter = Offset(w * 0.50, h * 0.34);
    final pinRadius = w * 0.22;

    final pinPath = Path();
    pinPath.addArc(
      Rect.fromCircle(center: pinCenter, radius: pinRadius),
      math.pi * 0.8,
      math.pi * 1.4,
    );
    pinPath.lineTo(w * 0.50, h * 0.78);
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // 4. White Inner Circle
    final whiteCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pinCenter, pinRadius * 0.52, whiteCirclePaint);

    // 5. Blue Inner Dot
    final blueDotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pinCenter, pinRadius * 0.26, blueDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

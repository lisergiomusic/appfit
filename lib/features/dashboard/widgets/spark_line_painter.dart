import 'package:flutter/material.dart';

class SparkLinePainter extends CustomPainter {
  final List<double> pesos;
  final Color color;

  SparkLinePainter({required this.pesos, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pesos.isEmpty) return;

    final min = pesos.reduce((a, b) => a < b ? a : b);
    final max = pesos.reduce((a, b) => a > b ? a : b);
    final range = max - min > 0 ? max - min : 1.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = <Offset>[];
    for (int i = 0; i < pesos.length; i++) {
      final x = (i / (pesos.length - 1)) * size.width;
      final normalized = (pesos[i] - min) / range;
      final y = size.height - (normalized * size.height * 0.8);
      points.add(Offset(x, y));
    }

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw dots at each point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(SparkLinePainter oldDelegate) {
    return oldDelegate.pesos != pesos || oldDelegate.color != color;
  }
}

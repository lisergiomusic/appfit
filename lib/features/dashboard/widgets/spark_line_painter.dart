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

    final points = <Offset>[];
    for (int i = 0; i < pesos.length; i++) {
      final x = pesos.length == 1 ? size.width / 2 : (i / (pesos.length - 1)) * size.width;
      final normalized = (pesos[i] - min) / range;
      final y = size.height - (normalized * size.height * 0.8);
      points.add(Offset(x, y));
    }

    // Draw gradient fill under curve
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    _addBezierPath(fillPath, points);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(50), color.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw line with bezier curve
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    _addBezierPath(linePath, points);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    // Draw dots at each point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      final radius = isLast ? 4.5 : 3.0;
      canvas.drawCircle(points[i], radius, dotPaint);
    }

    // Draw white border on last dot
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(lastPoint, 4.5, borderPaint);
    }
  }

  void _addBezierPath(Path path, List<Offset> points) {
    if (points.length < 2) return;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = i < points.length - 1 ? points[i + 1] : curr;

      // Control points for smooth bezier curve
      final cp1x = prev.dx + (curr.dx - prev.dx) / 3;
      final cp1y = prev.dy;
      final cp2x = curr.dx - (next.dx - prev.dx) / 3;
      final cp2y = curr.dy;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, curr.dx, curr.dy);
    }
  }

  @override
  bool shouldRepaint(SparkLinePainter oldDelegate) {
    return oldDelegate.pesos != pesos || oldDelegate.color != color;
  }
}

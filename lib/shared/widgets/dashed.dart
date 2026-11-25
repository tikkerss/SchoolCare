import 'package:material_ui/material_ui.dart';

/// Garis putus-putus mengelilingi [child] (dipakai chip Alpa/Dibatalkan).
class DashedOutline extends StatelessWidget {
  const DashedOutline({
    super.key,
    required this.child,
    required this.color,
    this.radius = 8,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedRRectPainter(color: color, radius: radius, strokeWidth: strokeWidth),
        child: child,
      );
}

/// Garis tegak putus-putus, mengisi seluruh tinggi yang tersedia.
class DashedVerticalLine extends StatelessWidget {
  const DashedVerticalLine({super.key, required this.color, this.strokeWidth = 1.5});

  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: strokeWidth,
        child: CustomPaint(painter: _DashedLinePainter(color: color, strokeWidth: strokeWidth)),
      );
}

const _dash = 4.0;
const _gap = 3.0;

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius, required this.strokeWidth});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + _dash).clamp(0, size.height)), paint);
      y += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color || old.strokeWidth != strokeWidth;
}

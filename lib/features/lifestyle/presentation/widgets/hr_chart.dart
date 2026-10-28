import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// One point of the heart-rate history (a daily or weekly average, with the range's min/max when the backend sent them).
class HrChartPoint {
  final DateTime day;
  final double avg;

  const HrChartPoint({required this.day, required this.avg});
}

/// Average heart rate over a range: a soft area line for up to ~3 months, bars for weekly buckets (1 year). Draws the
/// user's own numbers only - no thresholds, no zones, no colours that judge a value. Time runs left to right.
class HrChart extends StatelessWidget {
  final List<HrChartPoint> points;
  final bool bars;
  final String semanticsLabel;

  const HrChart({
    super.key,
    required this.points,
    required this.bars,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CustomPaint(painter: _HrChartPainter(points: points, bars: bars)),
        ),
      ),
    );
  }
}

class _HrChartPainter extends CustomPainter {
  final List<HrChartPoint> points;
  final bool bars;

  _HrChartPainter({required this.points, required this.bars});

  static const double _left = 34;
  static const double _top = 10;
  static const double _bottom = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final values = points.map((p) => p.avg);
    var lo = (values.reduce((a, b) => a < b ? a : b) / 5).floor() * 5.0 - 5;
    var hi = (values.reduce((a, b) => a > b ? a : b) / 5).ceil() * 5.0 + 5;
    if (hi - lo < 20) {
      final mid = (hi + lo) / 2;
      lo = mid - 10;
      hi = mid + 10;
    }
    final plot = Rect.fromLTRB(_left, _top, size.width - 6, size.height - _bottom);
    double y(double v) => plot.bottom - (v - lo) / (hi - lo) * plot.height;

    final grid = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.25)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final v = lo + (hi - lo) * i / 2;
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: v.round().toString(),
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y(v) - tp.height / 2));
    }

    final n = points.length;
    double x(int i) => n == 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1);

    if (bars) {
      final slot = plot.width / n;
      final w = (slot * 0.62).clamp(3.0, 16.0);
      final fill = Paint()..color = AppTheme.pistachioGreen;
      final edge = Paint()
        ..color = AppTheme.gate2ButtonOlive
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var i = 0; i < n; i++) {
        final cx = plot.left + slot * (i + 0.5);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - w / 2, y(points[i].avg), cx + w / 2, plot.bottom),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, i == n - 1 ? (Paint()..color = AppTheme.gate2ButtonOlive) : fill);
        canvas.drawRRect(rect, edge);
      }
      return;
    }

    final line = Path()..moveTo(x(0), y(points[0].avg));
    for (var i = 1; i < n; i++) {
      line.lineTo(x(i), y(points[i].avg));
    }
    final area = Path.from(line)
      ..lineTo(x(n - 1), plot.bottom)
      ..lineTo(x(0), plot.bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = AppTheme.pistachioGreen.withOpacity(0.35));
    canvas.drawPath(
      line,
      Paint()
        ..color = AppTheme.gate2ButtonOlive
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (n <= 31) {
      final dot = Paint()..color = AppTheme.gate2ButtonOlive;
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(Offset(x(i), y(points[i].avg)), i == n - 1 ? 5 : 3.5, i == n - 1 ? (Paint()..color = AppTheme.textPrimary) : dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HrChartPainter old) => old.points != points || old.bars != bars;
}

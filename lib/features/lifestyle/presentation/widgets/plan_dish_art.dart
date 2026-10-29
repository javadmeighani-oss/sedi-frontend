import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small vector illustrations for the plan coach screen (pilot V1 screen 6): a dish per meal slot, a symbol per exercise
/// kind. Drawn with paths - no photos, no assets, so they stay crisp, light and themeable.
class PlanDishArt extends StatelessWidget {
  /// `breakfast` | `lunch` | `dinner` | `snack` | `walk` | `strength` | `stretch` | `rest` | anything else (generic).
  final String kind;
  final double size;

  const PlanDishArt({super.key, required this.kind, this.size = 52});

  /// Meal slot / activity type of a plan action -> the illustration key.
  static String kindFor({String? mealSlot, String? activityType}) {
    final slot = (mealSlot ?? '').toLowerCase();
    if (slot.isNotEmpty) return slot;
    final a = (activityType ?? '').toLowerCase();
    if (a.contains('walk')) return 'walk';
    if (a.contains('strength') || a.contains('band') || a.contains('resist')) return 'strength';
    if (a.contains('stretch') || a.contains('mobil') || a.contains('yoga') || a.contains('balance')) return 'stretch';
    if (a.contains('rest')) return 'rest';
    return 'exercise';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ArtPainter(kind)),
    );
  }
}

class _ArtPainter extends CustomPainter {
  final String kind;

  const _ArtPainter(this.kind);

  static const Color _leaf = Color(0xFF7F9E32);
  static const Color _leafDark = Color(0xFF5E7A22);
  static const Color _tomato = Color(0xFFD9604C);
  static const Color _yolk = Color(0xFFF3B93C);
  static const Color _toast = Color(0xFFE3B76B);
  static const Color _crust = Color(0xFFC98F3D);
  static const Color _broth = Color(0xFFE9A64F);
  static const Color _ink = Color(0xFF48551F);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    switch (kind) {
      case 'breakfast':
        _plate(canvas, c, r);
        _egg(canvas, c.translate(-r * 0.16, r * 0.04), r * 0.42);
        _toastSlice(canvas, c.translate(r * 0.34, -r * 0.14), r * 0.34);
        break;
      case 'lunch':
        _plate(canvas, c, r);
        _rice(canvas, c, r * 0.6);
        _leaves(canvas, c.translate(-r * 0.12, -r * 0.06), r * 0.46);
        canvas.drawCircle(c.translate(r * 0.26, r * 0.2), r * 0.11, Paint()..color = _tomato);
        canvas.drawCircle(c.translate(r * 0.1, r * 0.34), r * 0.08, Paint()..color = _tomato);
        break;
      case 'dinner':
        _plate(canvas, c, r);
        canvas.drawCircle(c, r * 0.55, Paint()..color = const Color(0xFFF7F0DD));
        canvas.drawCircle(c, r * 0.46, Paint()..color = _broth);
        for (final p in const [Offset(-0.18, -0.1), Offset(0.14, -0.2), Offset(0.2, 0.12), Offset(-0.1, 0.2)]) {
          canvas.drawCircle(c.translate(r * p.dx, r * p.dy), r * 0.06, Paint()..color = _leaf);
        }
        _spoon(canvas, c.translate(r * 0.5, r * 0.5), r * 0.5);
        break;
      case 'snack':
        _plate(canvas, c, r);
        _apple(canvas, c, r * 0.5);
        break;
      case 'walk':
        _disc(canvas, c, r);
        _foot(canvas, c.translate(-r * 0.22, r * 0.12), r * 0.26, -0.25);
        _foot(canvas, c.translate(r * 0.22, -r * 0.16), r * 0.26, 0.25);
        break;
      case 'strength':
        _disc(canvas, c, r);
        _dumbbell(canvas, c, r * 0.62);
        break;
      case 'stretch':
        _disc(canvas, c, r);
        _stretch(canvas, c, r * 0.6);
        break;
      case 'rest':
        _disc(canvas, c, r);
        _moon(canvas, c, r * 0.4);
        break;
      default:
        _disc(canvas, c, r);
        _pulse(canvas, c, r * 0.58);
    }
  }

  void _plate(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c.translate(0, r * 0.06), r * 0.96, Paint()..color = _ink.withOpacity(0.14));
    canvas.drawCircle(c, r * 0.96, Paint()..color = Colors.white.withOpacity(0.92));
    canvas.drawCircle(
      c,
      r * 0.96,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = const Color(0xFFDCE6B0),
    );
    canvas.drawCircle(c, r * 0.72, Paint()..color = const Color(0xFFF4F7E6));
  }

  void _disc(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r * 0.96, Paint()..color = Colors.white.withOpacity(0.78));
    canvas.drawCircle(
      c,
      r * 0.96,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..color = const Color(0xFFCFE27C),
    );
  }

  void _egg(Canvas canvas, Offset c, double r) {
    final white = Path()
      ..moveTo(c.dx - r, c.dy)
      ..cubicTo(c.dx - r, c.dy - r * 1.1, c.dx + r * 0.2, c.dy - r * 1.2, c.dx + r * 0.9, c.dy - r * 0.3)
      ..cubicTo(c.dx + r * 1.3, c.dy + r * 0.4, c.dx + r * 0.2, c.dy + r * 1.1, c.dx - r * 0.5, c.dy + r * 0.8)
      ..cubicTo(c.dx - r * 0.9, c.dy + r * 0.6, c.dx - r, c.dy + r * 0.3, c.dx - r, c.dy)
      ..close();
    canvas.drawPath(white, Paint()..color = Colors.white);
    canvas.drawPath(
      white,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = const Color(0xFFE3E8CF),
    );
    canvas.drawCircle(c.translate(r * 0.1, r * 0.02), r * 0.36, Paint()..color = _yolk);
    canvas.drawCircle(c.translate(r * 0.0, -r * 0.1), r * 0.1, Paint()..color = Colors.white.withOpacity(0.7));
  }

  void _toastSlice(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.35);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 1.55),
      Radius.circular(r * 0.42),
    );
    canvas.drawRRect(rect, Paint()..color = _crust);
    canvas.drawRRect(rect.deflate(r * 0.1), Paint()..color = _toast);
    canvas.restore();
  }

  void _rice(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF7F0DD));
    final dot = Paint()..color = const Color(0xFFE6DCB8);
    for (var i = 0; i < 9; i++) {
      final a = i * 2.4;
      canvas.drawCircle(c.translate(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55), r * 0.06, dot);
    }
  }

  void _leaves(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.9 + i * 0.9);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(r * 0.55, -r * 0.35, r, 0)
        ..quadraticBezierTo(r * 0.55, r * 0.35, 0, 0)
        ..close();
      canvas.drawPath(leaf, Paint()..color = i.isEven ? _leaf : _leafDark);
      canvas.restore();
    }
  }

  void _spoon(Canvas canvas, Offset c, double len) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-len * 0.05, -len * 0.6, len * 0.1, len * 0.6), Radius.circular(len * 0.05)),
      Paint()..color = const Color(0xFFB9C28E),
    );
    canvas.restore();
  }

  void _apple(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c.translate(-r * 0.28, r * 0.05), r * 0.72, Paint()..color = _tomato);
    canvas.drawCircle(c.translate(r * 0.28, r * 0.05), r * 0.72, Paint()..color = _tomato);
    canvas.drawCircle(c.translate(-r * 0.4, -r * 0.18), r * 0.14, Paint()..color = Colors.white.withOpacity(0.55));
    final leaf = Path()
      ..moveTo(c.dx + r * 0.05, c.dy - r * 0.55)
      ..quadraticBezierTo(c.dx + r * 0.5, c.dy - r * 1.1, c.dx + r * 0.85, c.dy - r * 0.7)
      ..quadraticBezierTo(c.dx + r * 0.45, c.dy - r * 0.45, c.dx + r * 0.05, c.dy - r * 0.55)
      ..close();
    canvas.drawPath(leaf, Paint()..color = _leaf);
    canvas.drawLine(
      c.translate(0, -r * 0.5),
      c.translate(-r * 0.05, -r * 0.95),
      Paint()
        ..color = _crust
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round,
    );
  }

  Paint get _stroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;

  void _foot(Canvas canvas, Offset c, double r, double angle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.1, height: r * 1.7), Paint()..color = _leaf);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -r * 1.05), width: r * 0.8, height: r * 0.7),
      Paint()..color = _leaf,
    );
    canvas.restore();
  }

  void _dumbbell(Canvas canvas, Offset c, double r) {
    final p = Paint()..color = _ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 1.3, height: r * 0.16), Radius.circular(r * 0.08)),
      p,
    );
    for (final dx in const [-0.55, 0.55]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(r * dx, 0), width: r * 0.3, height: r * 0.75),
          Radius.circular(r * 0.1),
        ),
        Paint()..color = _leaf,
      );
    }
  }

  void _stretch(Canvas canvas, Offset c, double r) {
    final s = _stroke..strokeWidth = r * 0.16;
    canvas.drawCircle(c.translate(-r * 0.05, -r * 0.62), r * 0.2, Paint()..color = _leaf);
    final body = Path()
      ..moveTo(c.dx - r * 0.05, c.dy - r * 0.35)
      ..quadraticBezierTo(c.dx + r * 0.1, c.dy + r * 0.1, c.dx - r * 0.1, c.dy + r * 0.5);
    canvas.drawPath(body, s);
    canvas.drawLine(c.translate(-r * 0.05, -r * 0.25), c.translate(r * 0.6, -r * 0.6), s);
    canvas.drawLine(c.translate(-r * 0.05, -r * 0.25), c.translate(-r * 0.62, -r * 0.5), s);
  }

  void _moon(Canvas canvas, Offset c, double r) {
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final cut = Path()..addOval(Rect.fromCircle(center: c.translate(r * 0.5, -r * 0.2), radius: r * 0.85));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, cut), Paint()..color = _leaf);
  }

  void _pulse(Canvas canvas, Offset c, double r) {
    final s = _stroke..strokeWidth = r * 0.14;
    final p = Path()
      ..moveTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.45, c.dy)
      ..lineTo(c.dx - r * 0.2, c.dy - r * 0.6)
      ..lineTo(c.dx + r * 0.15, c.dy + r * 0.6)
      ..lineTo(c.dx + r * 0.4, c.dy)
      ..lineTo(c.dx + r, c.dy);
    canvas.drawPath(p, s);
  }

  @override
  bool shouldRepaint(covariant _ArtPainter oldDelegate) => oldDelegate.kind != kind;
}

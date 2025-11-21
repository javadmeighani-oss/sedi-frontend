import 'package:flutter/material.dart';
import 'dart:math' as math;

class RotaryScrollbar extends StatelessWidget {
  final ScrollController controller;
  final double height;

  const RotaryScrollbar({
    Key? key,
    required this.controller,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 36,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          controller.jumpTo(
            controller.offset + details.delta.dy * 4,
          );
        },
        child: CustomPaint(
          painter: _RotaryPainter(),
        ),
      ),
    );
  }
}

class _RotaryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // Base circle
    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, basePaint);

    // Knob pointer
    final pointerPaint = Paint()
      ..color = Colors.green.shade500
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final angle = math.pi / 2;
    final knobX = center.dx + radius * math.cos(angle);
    final knobY = center.dy + radius * math.sin(angle);

    canvas.drawLine(center, Offset(knobX, knobY), pointerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

class RotaryScrollbar extends StatefulWidget {
  final ScrollController controller; // کنترل اسکرول پیام‌ها
  final double height; // ارتفاع ناحیه اسکرول‌بار
  final Color color; // رنگ برند (سبز پسته‌ای)

  const RotaryScrollbar({
    super.key,
    required this.controller,
    required this.height,
    required this.color,
  });

  @override
  State<RotaryScrollbar> createState() => _RotaryScrollbarState();
}

class _RotaryScrollbarState extends State<RotaryScrollbar> {
  double position = 0.0; // موقعیت چرخنده
  double rotation = 0.0; // چرخش برای حالت چرخشی

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updatePosition);
  }

  void _updatePosition() {
    if (!mounted) return;

    final maxScroll = widget.controller.position.maxScrollExtent;
    final offset = widget.controller.offset;

    setState(() {
      // نسبت اسکرول پیام‌ها → حرکت اسکرول‌بار
      position = maxScroll == 0 ? 0 : offset / maxScroll;

      // چرخش اضافه برای حس چرخنده
      rotation = (offset / 60) % (2 * math.pi);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updatePosition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: 35, // پهن‌تر از اسکرول معمول
      child: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // اندازه چرخنده
            const ballSize = 26.0;

            // موقعیت چرخنده
            final y = (constraints.maxHeight - ballSize) * position;

            return Stack(
              children: [
                // مسیر اسکرول
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 6,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // چرخنده
                Positioned(
                  top: y,
                  left: 4,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: ballSize,
                      height: ballSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

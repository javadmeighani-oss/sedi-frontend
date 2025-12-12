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
  double scrollPosition = 0.0; // موقعیت اسکرول (0 تا 1)
  double rotationAngle = 0.0; // زاویه چرخش

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
      // محاسبه موقعیت اسکرول (0 تا 1)
      scrollPosition = maxScroll == 0 ? 0 : (offset / maxScroll).clamp(0.0, 1.0);

      // محاسبه زاویه چرخش بر اساس اسکرول (چرخش 360 درجه)
      rotationAngle = (offset / 10) % (2 * math.pi);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updatePosition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تعداد مستطیل‌های چرخشی (بیشتر = نرم‌تر)
    const int rectangleCount = 12;
    const double rectangleWidth = 3.0;
    const double rectangleHeight = 8.0;
    const double spacing = 2.5;

    return SizedBox(
      height: widget.height,
      width: 20, // عرض اسکرول
      child: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;
            final centerY = totalHeight / 2;

            return Stack(
              children: List.generate(rectangleCount, (index) {
                // فاصله از مرکز برای هر مستطیل
                final distanceFromCenter = (index - rectangleCount / 2) * spacing;
                final baseY = centerY + distanceFromCenter;

                // محاسبه موقعیت Y با چرخش
                final rotationOffset = math.sin(rotationAngle + (index * math.pi / 6)) * 15;
                final currentY = baseY + rotationOffset + (scrollPosition * (totalHeight - rectangleHeight * rectangleCount));

                // محاسبه opacity و رنگ بر اساس موقعیت
                final distanceFromViewport = (currentY - centerY).abs() / (totalHeight / 2);
                final opacity = (1.0 - distanceFromViewport.clamp(0.0, 1.0)) * 0.6 + 0.2;
                final grayShade = (1.0 - distanceFromViewport.clamp(0.0, 1.0)) * 255;

                return Positioned(
                  top: currentY.clamp(0.0, totalHeight - rectangleHeight),
                  left: (20 - rectangleWidth) / 2,
                  child: Transform.rotate(
                    angle: rotationAngle + (index * 0.1),
                    alignment: Alignment.center,
                    child: Container(
                      width: rectangleWidth,
                      height: rectangleHeight,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          grayShade.toInt(),
                          grayShade.toInt(),
                          grayShade.toInt(),
                          opacity,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

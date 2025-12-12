import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// منحنی سفارشی شبیه ضربان قلب
/// beat سریع در ابتدا (systole) و سپس pause (diastole)
class _HeartbeatCurve extends Curve {
  const _HeartbeatCurve();

  @override
  double transformInternal(double t) {
    // 0.0-0.25: beat سریع (systole) - از 0.0 به 1.0
    // 0.25-1.0: pause (diastole) - از 1.0 به 0.0
    if (t < 0.25) {
      // beat سریع با منحنی easeOut برای طبیعی‌تر شدن
      final normalizedT = t / 0.25;
      return Curves.easeOut.transform(normalizedT);
    } else {
      // pause با منحنی easeIn برای بازگشت نرم
      final normalizedT = (t - 0.25) / 0.75;
      return 1.0 - Curves.easeIn.transform(normalizedT);
    }
  }
}

/// ویجت انیمیشن رینگ صدی - شبیه ضربان قلب
class SediRingAnim extends StatefulWidget {
  final bool active; // آیا انیمیشن فعال است؟
  final double size; // اندازه رینگ
  final double ringThickness; // ضخامت رینگ

  const SediRingAnim({
    super.key,
    required this.active,
    this.size = 140,
    this.ringThickness = 2.5,
  });

  @override
  State<SediRingAnim> createState() => _SediRingAnimState();
}

class _SediRingAnimState extends State<SediRingAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // انیمیشن تپش قلب - شبیه ضربان قلب واقعی
    // یک beat سریع (systole) و سپس pause (diastole)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1100), // یک چرخه کامل تپش (شبیه ضربان قلب)
    );

    // انیمیشن با منحنی شبیه ضربان قلب: beat سریع در ابتدا، سپس pause
    // 0.0-0.25: beat سریع (systole) - از 1.0 به 1.08
    // 0.25-1.0: pause (diastole) - از 1.08 به 1.0
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _HeartbeatCurve(), // منحنی سفارشی شبیه ضربان قلب
      ),
    );

    // شروع تپش اگر فعال است
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.repeat();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SediRingAnim oldWidget) {
    super.didUpdateWidget(oldWidget);

    // کنترل انیمیشن بر اساس وضعیت
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        // شروع تپش (repeat بدون reverse برای انیمیشن طبیعی‌تر)
        _controller.repeat();
      } else {
        // توقف تپش
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // فقط رینگ scale می‌شود
        final ringScale = widget.active ? _pulse.value : 1.0;

        // محاسبه opacity برای انیمیشن طبیعی (بین 0.5 تا 0.95)
        // در ابتدای beat (systole) opacity بیشتر، سپس کمتر می‌شود
        final progress = _controller.value;
        final opacity = widget.active
            ? (progress < 0.25)
                ? 0.5 + (progress / 0.25) * 0.45 // از 0.5 به 0.95 در beat
                : 0.95 -
                    ((progress - 0.25) / 0.75) * 0.45 // از 0.95 به 0.5 در pause
            : 0.3;

        return Transform.scale(
          scale: ringScale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.pistachioGreen
                    .withOpacity(opacity.clamp(0.3, 1.0)),
                width: widget.ringThickness,
              ),
              boxShadow: widget.active
                  ? [
                      // سایه اول - نزدیک به حلقه (با انیمیشن)
                      BoxShadow(
                        color: AppTheme.pistachioGreen.withOpacity(
                          0.3 + (ringScale - 1.0) * 0.4,
                        ),
                        blurRadius: 8 + (ringScale - 1.0) * 25,
                        spreadRadius: 0.5 + (ringScale - 1.0) * 2,
                      ),
                      // سایه دوم - دورتر (با انیمیشن)
                      BoxShadow(
                        color: AppTheme.pistachioGreen.withOpacity(
                          0.15 + (ringScale - 1.0) * 0.25,
                        ),
                        blurRadius: 20 + (ringScale - 1.0) * 35,
                        spreadRadius: 1 + (ringScale - 1.0) * 3,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

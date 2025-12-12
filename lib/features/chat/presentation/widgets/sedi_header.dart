import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SediHeader extends StatefulWidget {
  final bool isThinking; // آیا صدی در حال فکر کردن است؟
  final bool isAlert; // آیا هشدار وجود دارد؟
  final double size; // اندازه لوگو

  const SediHeader({
    super.key,
    required this.isThinking,
    required this.isAlert,
    this.size = 140,
  });

  @override
  State<SediHeader> createState() => _SediHeaderState();
}

class _SediHeaderState extends State<SediHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // انیمیشن تپش قلب - نرم‌تر و طبیعی‌تر (مثل ضربان قلب)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // سرعت تپش طبیعی
    );

    _pulse = Tween<double>(begin: 0.97, end: 1.06).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // شروع تپش اگر صدی در حال فکر کردن است
    if (widget.isThinking || widget.isAlert) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SediHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // کنترل انیمیشن بر اساس وضعیت - بهبود یافته
    final shouldAnimate = widget.isThinking || widget.isAlert;
    final wasAnimating = oldWidget.isThinking || oldWidget.isAlert;

    // اگر وضعیت تغییر کرده
    if (shouldAnimate != wasAnimating) {
      if (shouldAnimate) {
        // شروع تپش
        _controller.repeat(reverse: true);
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
    final ringThickness = 2.5; // حلقه نازک‌تر (2.5px)
    final logoSize = widget.size - (ringThickness * 2) - 12;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isActive = widget.isThinking || widget.isAlert;
          final scale = isActive ? _pulse.value : 1.0;
          // محاسبه opacity برای انیمیشن نرم (بین 0.4 تا 0.8)
          final opacity = isActive 
              ? 0.4 + ((_pulse.value - 0.97) / (1.06 - 0.97)) * 0.4
              : 0.3;

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ============================================
                // حلقه سبز پسته‌ای (تپنده) - نازک و زیبا
                // ============================================
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pistachioGreen.withOpacity(opacity.clamp(0.3, 1.0)),
                      width: ringThickness,
                    ),
                    boxShadow: isActive
                        ? [
                            // سایه اول - نزدیک به حلقه (با انیمیشن)
                            BoxShadow(
                              color: AppTheme.pistachioGreen.withOpacity(0.35 + (scale - 1.0) * 0.3),
                              blurRadius: 12 + (scale - 1.0) * 30,
                              spreadRadius: 1 + (scale - 1.0) * 2,
                            ),
                            // سایه دوم - دورتر (با انیمیشن)
                            BoxShadow(
                              color: AppTheme.pistachioGreen.withOpacity(0.2 + (scale - 1.0) * 0.2),
                              blurRadius: 25 + (scale - 1.0) * 30,
                              spreadRadius: 2 + (scale - 1.0) * 3,
                            ),
                          ]
                        : null,
                  ),
                ),

                // ============================================
                // لوگوی صدی (وسط) - با سایه ملایم
                // ============================================
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.backgroundWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/sedi_logo_1024.png',
                      fit: BoxFit.contain,
                      width: logoSize * 0.7,
                      height: logoSize * 0.7,
                      errorBuilder: (context, error, stackTrace) {
                        // اگر لوگو پیدا نشد، متن نمایش داده می‌شود
                        return Text(
                          'Sedi.',
                          style: TextStyle(
                            fontSize: logoSize * 0.25,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pistachioGreen,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

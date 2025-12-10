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

    // انیمیشن تپش قلب
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // سرعت تپش
    );

    _pulse = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // شروع تپش اگر صدی در حال فکر کردن است
    if (widget.isThinking || widget.isAlert) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SediHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // کنترل انیمیشن بر اساس وضعیت
    if ((widget.isThinking || widget.isAlert) && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isThinking &&
        !widget.isAlert &&
        _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringThickness = widget.size * 0.06; // حلقه نازک
    final logoSize = widget.size - ringThickness * 2 - 8;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = (widget.isThinking || widget.isAlert) 
              ? _pulse.value 
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ============================================
                // حلقه سبز پسته‌ای (تپنده)
                // ============================================
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pistachioGreen,
                      width: ringThickness,
                    ),
                    boxShadow: (widget.isThinking || widget.isAlert)
                        ? [
                            BoxShadow(
                              color: AppTheme.pistachioGreen.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),

                // ============================================
                // لوگوی صدی (وسط)
                // ============================================
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.backgroundWhite,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/sedi_logo_1024.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // اگر لوگو پیدا نشد، متن نمایش داده می‌شود
                        return const Text(
                          'Sedi.',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pistachioGreen,
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

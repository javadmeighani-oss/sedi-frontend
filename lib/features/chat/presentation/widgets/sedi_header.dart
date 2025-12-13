import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// منحنی سفارشی شبیه ضربان قلب
/// beat سریع در ابتدا (systole) و سپس pause (diastole)
class _HeartbeatCurve extends Curve {
  const _HeartbeatCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.25) {
      final normalizedT = t / 0.25;
      return Curves.easeOut.transform(normalizedT);
    } else {
      final normalizedT = (t - 0.25) / 0.75;
      return 1.0 - Curves.easeIn.transform(normalizedT);
    }
  }
}

class SediHeader extends StatefulWidget {
  final bool isThinking;
  final bool isAlert;
  final double size;

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _HeartbeatCurve(),
      ),
    );

    if (widget.isThinking || widget.isAlert) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.repeat();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SediHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldAnimate = widget.isThinking || widget.isAlert;
    final wasAnimating = oldWidget.isThinking || oldWidget.isAlert;

    if (shouldAnimate != wasAnimating) {
      if (shouldAnimate) {
        _controller.repeat();
      } else {
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
    final ringThickness = 2.5;
    final logoSize = widget.size - (ringThickness * 2) - 12;

    return IgnorePointer(
      ignoring: true, // 🔑 کلید حل مشکل تایپ
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // =============================
            // حلقه تپنده
            // =============================
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final isActive = widget.isThinking || widget.isAlert;
                final ringScale = isActive ? _pulse.value : 1.0;

                final progress = _controller.value;
                final opacity = isActive
                    ? (progress < 0.25)
                        ? 0.5 + (progress / 0.25) * 0.45
                        : 0.95 - ((progress - 0.25) / 0.75) * 0.45
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
                        width: ringThickness,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.pistachioGreen.withOpacity(
                                  0.3 + (ringScale - 1.0) * 0.4,
                                ),
                                blurRadius: 8 + (ringScale - 1.0) * 25,
                                spreadRadius: 0.5 + (ringScale - 1.0) * 2,
                              ),
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
            ),

            // =============================
            // لوگوی صدی (ثابت)
            // =============================
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
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/sedi_logo_1024.png',
                  fit: BoxFit.contain,
                  width: logoSize * 0.7,
                  height: logoSize * 0.7,
                  errorBuilder: (_, __, ___) => Text(
                    'Sedi.',
                    style: TextStyle(
                      fontSize: logoSize * 0.25,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pistachioGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

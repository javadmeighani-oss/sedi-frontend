import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ------------------------------------------------------------
/// SediRingAnim
///
/// RESPONSIBILITY:
/// - Draw and animate ONLY the pistachio ring
/// - Heartbeat-like pulse when active
/// - Logo remains static in SediHeader
/// ------------------------------------------------------------
class SediRingAnim extends StatefulWidget {
  final bool active;
  final double size;
  final double thickness;

  const SediRingAnim({
    super.key,
    required this.active,
    required this.size,
    this.thickness = 2.5,
  });

  @override
  State<SediRingAnim> createState() => _SediRingAnimState();
}

/// Custom heartbeat curve:
/// Fast beat (0..0.25) + slow relax (0.25..1.0)
class _HeartbeatCurve extends Curve {
  const _HeartbeatCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.25) {
      final n = t / 0.25;
      return Curves.easeOut.transform(n);
    } else {
      final n = (t - 0.25) / 0.75;
      return 1.0 - Curves.easeIn.transform(n);
    }
  }
}

class _SediRingAnimState extends State<SediRingAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

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

    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 1.0; // reset to stable state
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _ringOpacity(double t, bool active) {
    if (!active) return 0.30;

    if (t < 0.25) {
      return 0.50 + (t / 0.25) * 0.45; // 0.50 → 0.95
    }
    return 0.95 - ((t - 0.25) / 0.75) * 0.45; // 0.95 → 0.50
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = widget.active ? _pulse.value : 1.0;
        final opacity = _ringOpacity(
          _controller.value,
          widget.active,
        ).clamp(0.30, 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.pistachioGreen.withOpacity(opacity),
                width: widget.thickness,
              ),
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: AppTheme.pistachioGreen.withOpacity(
                          (0.20 + (scale - 1.0) * 0.35).clamp(0.0, 0.6),
                        ),
                        blurRadius: 10 + (scale - 1.0) * 25,
                        spreadRadius: 1 + (scale - 1.0) * 2,
                      ),
                    ]
                  : const [],
            ),
          ),
        );
      },
    );
  }
}

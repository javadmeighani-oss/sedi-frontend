import 'package:flutter/material.dart';

class SediHeader extends StatefulWidget {
  final double size;
  final bool isThinking;

  const SediHeader({
    super.key,
    required this.size,
    required this.isThinking,
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
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isThinking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SediHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isThinking && _controller.isAnimating) {
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
    const base = Color(0xFF7CCF81); // سبز پسته‌ای اصلی
    const light = Color(0xFFAEEFC0); // سبز پسته‌ای روشن

    final outerSize = widget.size;
    final ringThickness = outerSize * 0.08;
    final logoSize = outerSize - ringThickness * 2 - 12;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = widget.isThinking ? _pulse.value : 1.0;
          final glowOpacity = widget.isThinking ? 0.7 : 0.35;

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [base, light, base],
                ),
                boxShadow: [
                  BoxShadow(
                    color: base.withOpacity(glowOpacity),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: outerSize - ringThickness * 2,
                  height: outerSize - ringThickness * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: base.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'assets/images/sedi_logo_1024.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

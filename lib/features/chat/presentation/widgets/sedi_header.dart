import 'package:flutter/material.dart';

class SediHeader extends StatefulWidget {
  final bool isThinking; // از کنترلر می‌آید
  final bool isAlert; // 🔥 این اضافه شد تا با ChatPage هماهنگ شود
  final double size;

  const SediHeader({
    super.key,
    this.size = 120,
    required this.isThinking,
    required this.isAlert,
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
      duration: const Duration(milliseconds: 1600),
    );

    _pulse = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isThinking || widget.isAlert) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SediHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

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
    const base = Color(0xFF7CCF81); // سبز پسته‌ای اصلی
    const alertColor = Color(0xFFFF6464); // رنگ هشدار
    const light = Color(0xFFAEEFC0);

    final outerSize = widget.size;
    final ringThickness = outerSize * 0.08;
    final logoSize = outerSize - ringThickness * 2 - 12;

    final ringColor = widget.isAlert ? alertColor : base; // 🔥 انتخاب رنگ هشدار

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale =
              (widget.isThinking || widget.isAlert) ? _pulse.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    ringColor,
                    widget.isAlert ? Colors.redAccent : light,
                    ringColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withOpacity(widget.isAlert ? 0.8 : 0.4),
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
                    border: Border.all(
                      color: ringColor.withOpacity(0.35),
                      width: 1,
                    ),
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

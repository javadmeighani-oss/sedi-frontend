import 'package:flutter/material.dart';

class SediRingAnim extends StatefulWidget {
  final double size; // اندازه کل دایره (لوگو + حلقه)
  final bool isThinking; // حالت تفکر صدی
  final bool isAlert; // حالت هشدار
  final Color ringColor; // رنگ حلقه (سبز پسته‌ای)
  final Widget child; // خود لوگو داخل حلقه

  const SediRingAnim({
    super.key,
    required this.size,
    required this.isThinking,
    required this.isAlert,
    required this.ringColor,
    required this.child,
  });

  @override
  State<SediRingAnim> createState() => _SediRingAnimState();
}

class _SediRingAnimState extends State<SediRingAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // اگر هشدار باشد، رنگ قرمز می‌شود
    final Color finalColor =
        widget.isAlert ? Colors.redAccent : widget.ringColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final bool active = widget.isThinking || widget.isAlert;

        return Transform.scale(
          scale: active ? _scaleAnim.value : 1.0,
          child: Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (active)
                  BoxShadow(
                    color: finalColor.withOpacity(_glowAnim.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
              border: Border.all(
                color: finalColor,
                width: widget.isAlert ? 5 : 3,
              ),
            ),
            child: ClipOval(
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';

class SediHeader extends StatefulWidget {
  final double size;
  final bool isThinking;

  const SediHeader({
    Key? key,
    required this.size,
    required this.isThinking,
  }) : super(key: key);

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

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    /// انیمیشن فقط وقتی صدی فکر می‌کند فعال شود
    if (widget.isThinking) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SediHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isThinking) {
      _controller.repeat(reverse: true);
    } else {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.scale(
          scale: widget.isThinking ? _pulse.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7CCF81), // سبز پسته‌ای اصلی
                width: widget.isThinking ? 10 : 8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA6E8B0)
                      .withOpacity(widget.isThinking ? 0.9 : 0.35),
                  blurRadius: widget.isThinking ? 40 : 20,
                  spreadRadius: widget.isThinking ? 6 : 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/images/sedi_logo_1024.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

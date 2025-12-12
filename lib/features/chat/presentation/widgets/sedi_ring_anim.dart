import 'package:flutter/material.dart';

class SediRingAnim extends StatefulWidget {
  final bool active;

  const SediRingAnim({super.key, required this.active});

  @override
  State<SediRingAnim> createState() => _SediRingAnimState();
}

class _SediRingAnimState extends State<SediRingAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 1.0,
      upperBound: 1.08,
    );
  }

  @override
  void didUpdateWidget(covariant SediRingAnim oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.green.shade300,
            width: 3,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

/// ------------------------------------------------------------
/// RotaryScrollbar
///
/// RESPONSIBILITY:
/// - Visual scroll indicator for chat list
/// - No dependency on chat models or state
/// - Reads scroll position ONLY from ScrollController
/// ------------------------------------------------------------
class RotaryScrollbar extends StatefulWidget {
  final ScrollController controller;
  final double height;

  const RotaryScrollbar({
    super.key,
    required this.controller,
    required this.height,
  });

  @override
  State<RotaryScrollbar> createState() => _RotaryScrollbarState();
}

class _RotaryScrollbarState extends State<RotaryScrollbar> {
  double _positionRatio = 0.0;
  double _rotation = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncWithScroll);
  }

  void _syncWithScroll() {
    if (!mounted || !widget.controller.hasClients) return;

    final maxScroll = widget.controller.position.maxScrollExtent;
    final offset = widget.controller.offset;

    setState(() {
      _positionRatio = maxScroll == 0 ? 0 : offset / maxScroll;
      _rotation = (offset / 80) % (2 * math.pi);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncWithScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double knobSize = 26;

          final double y = (constraints.maxHeight - knobSize) * _positionRatio;

          return Stack(
            children: [
              // --------------------------
              // Scroll Track
              // --------------------------
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 6,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.metalGrey.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // --------------------------
              // Rotary Knob
              // --------------------------
              Positioned(
                top: y,
                left: (constraints.maxWidth - knobSize) / 2,
                child: Transform.rotate(
                  angle: _rotation,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pistachioGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.pistachioGreen.withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

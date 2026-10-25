import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// Presentation-only collapsible tray around the A3 destination icon row.
/// Hologram redesign: a glass tray that floats over the scene (same API).
class Gate3TopNavigationTray extends StatefulWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String expandLabel;
  final String collapseLabel;

  static const Duration toggleDuration = Duration(milliseconds: 240);
  static const Curve toggleCurve = Curves.easeOutCubic;
  static const double handleHeight = 44;

  const Gate3TopNavigationTray({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.child,
    required this.expandLabel,
    required this.collapseLabel,
  });

  @override
  State<Gate3TopNavigationTray> createState() => _Gate3TopNavigationTrayState();
}

class _Gate3TopNavigationTrayState extends State<Gate3TopNavigationTray>
    with SingleTickerProviderStateMixin {
  late final AnimationController _size;

  @override
  void initState() {
    super.initState();
    _size = AnimationController(
      vsync: this,
      duration: Gate3TopNavigationTray.toggleDuration,
      value: widget.expanded ? 1 : 0,
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant Gate3TopNavigationTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      _size.animateTo(
        widget.expanded ? 1 : 0,
        curve: Gate3TopNavigationTray.toggleCurve,
      );
    }
  }

  @override
  void dispose() {
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showIcons = widget.expanded || _size.value > 0.001;
    const radius = BorderRadius.vertical(bottom: Radius.circular(22));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SediPalette.shell100.withOpacity(0.90),
                SediPalette.shell100.withOpacity(0.72),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: SediPalette.pistachio700.withOpacity(0.20),
                width: 0.8,
              ),
            ),
            borderRadius: radius,
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggle,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _size.value,
                child: showIcons
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: widget.child,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),
          ),
          Semantics(
            key: const ValueKey('a3-top-tray-semantics'),
            button: true,
            label: widget.expanded
                ? widget.collapseLabel
                : widget.expandLabel,
            child: Material(
              color: const Color(0x00000000),
              child: InkWell(
                key: const ValueKey('a3-top-tray-toggle'),
                onTap: widget.onToggle,
                child: SizedBox(
                  width: double.infinity,
                  height: Gate3TopNavigationTray.handleHeight,
                  child: Center(
                    child: _TrayChevron(expanded: widget.expanded),
                  ),
                ),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

/// Visible chevron only. Handle tap target stays [Gate3TopNavigationTray.handleHeight].
class _TrayChevron extends StatelessWidget {
  static const double visualSize = 18 * 1.30;
  static const double strokeWidth = 1.5 * 1.10;

  final bool expanded;

  const _TrayChevron({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(visualSize),
      painter: _TrayChevronPainter(
        pointingUp: expanded,
        color: SediPalette.pistachio700,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _TrayChevronPainter extends CustomPainter {
  final bool pointingUp;
  final Color color;
  final double strokeWidth;

  const _TrayChevronPainter({
    required this.pointingUp,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final insetX = size.width * 0.28;
    final top = size.height * 0.38;
    final bottom = size.height * 0.58;
    final midX = size.width / 2;
    final apexY = pointingUp ? top : bottom;
    final wingY = pointingUp ? bottom : top;

    final path = Path()
      ..moveTo(insetX, wingY)
      ..lineTo(midX, apexY)
      ..lineTo(size.width - insetX, wingY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrayChevronPainter oldDelegate) =>
      oldDelegate.pointingUp != pointingUp ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

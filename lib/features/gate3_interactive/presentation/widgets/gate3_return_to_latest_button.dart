import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';

/// Single attached [ScrollPosition] only after content dimensions exist.
///
/// `hasClients` is not enough: `.position` requires exactly one position,
/// and `maxScrollExtent`/`pixels` are invalid before [ScrollPosition.hasContentDimensions].
ScrollPosition? gate3SingleReadyScrollPosition(ScrollController controller) {
  final positions = controller.positions;
  if (positions.length != 1) return null;
  final pos = positions.single;
  if (!pos.hasContentDimensions) return null;
  return pos;
}

/// Shown when the chat list is scrolled away from the latest messages.
class Gate3ReturnToLatestButton extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onTap;
  final String tooltip;

  const Gate3ReturnToLatestButton({
    super.key,
    required this.scrollController,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<Gate3ReturnToLatestButton> createState() =>
      _Gate3ReturnToLatestButtonState();
}

class _Gate3ReturnToLatestButtonState extends State<Gate3ReturnToLatestButton> {
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  /// Top-anchored list: latest is at maxScrollExtent; show when scrolled up.
  bool get _visible {
    final pos = gate3SingleReadyScrollPosition(widget.scrollController);
    if (pos == null) return false;
    return (pos.maxScrollExtent - pos.pixels) > 72;
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? SediPalette.charcoal700.withOpacity(0.85)
                : SediPalette.charcoal900.withOpacity(0.72),
            border: Border.all(
              color: SediPalette.skin300.withOpacity(0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: SediPalette.skin500.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: SediPalette.pistachio300,
            size: 24,
          ),
        ),
      ),
    );
  }
}

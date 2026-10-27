import 'package:flutter/material.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isSedi;
  final bool isFailed;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final String? editLabel;
  final bool showTyping;

  /// Localized labels (EN defaults keep older call sites unchanged).
  final String? readMoreLabel;
  final String? readLessLabel;
  final String? retryLabel;

  /// Soft halo so assistant text stays readable over the background hologram.
  static const List<Shadow> _sediTextShadows = [
    Shadow(color: Color(0xF2DCE0C0), blurRadius: 12),
    Shadow(color: Color(0xCCDCE0C0), blurRadius: 3),
  ];

  /// Sedi's logo sphere diameter and the text metrics of a message line. The first line of text is centred on the
  /// logo's centre (D-102) so the logo, the text and the typing dots share one visual line.
  static const double sediLogoDiameter = 34;
  static const double _fontSize = 15;
  static const double _lineHeight = 1.45;
  static const double sediTextTopInset =
      (sediLogoDiameter - _fontSize * _lineHeight) / 2;

  /// First-strong-character direction for bidi-safe user text.
  static TextDirection resolveTextDirection(String text) {
    for (final rune in text.runes) {
      if (_isRtlLetter(rune)) return TextDirection.rtl;
      if (_isLtrLetter(rune)) return TextDirection.ltr;
    }
    return TextDirection.ltr;
  }

  static bool _isRtlLetter(int rune) {
    return (rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  static bool _isLtrLetter(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A);
  }

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSedi,
    this.isFailed = false,
    this.onRetry,
    this.onEdit,
    this.editLabel,
    this.showTyping = false,
    this.readMoreLabel,
    this.readLessLabel,
    this.retryLabel,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _expanded = false;

  bool get _canCollapseUserMessage {
    if (widget.isSedi || widget.showTyping) return false;
    return widget.message.split('\n').length > 2 || widget.message.length > 120;
  }

  @override
  Widget build(BuildContext context) {
    // Physical sides, not locale-dependent directional START/END.
    final alignment =
        widget.isSedi ? Alignment.centerLeft : Alignment.centerRight;
    final shouldCollapse = _canCollapseUserMessage && !_expanded;
    // Sedi replies follow the app language (fa/ar are right-to-left even when a line starts with Latin text);
    // the user's own text keeps first-strong-character direction.
    final textDirection = widget.isSedi && SediLocaleController.instance.isRtl
        ? TextDirection.rtl
        : MessageBubble.resolveTextDirection(widget.message);
    final textAlign =
        textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;

    final text = widget.showTyping
        ? const _TypingDots()
        : Text(
            widget.message,
            maxLines: shouldCollapse ? 2 : null,
            overflow: shouldCollapse ? TextOverflow.ellipsis : null,
            textDirection: textDirection,
            textAlign: textAlign,
            style: TextStyle(
              color: widget.isSedi
                  ? SediPalette.charcoal950
                  : SediPalette.shell100,
              fontSize: MessageBubble._fontSize,
              height: MessageBubble._lineHeight,
              // ~20 % heavier strokes than before (D-097) for easier reading.
              fontWeight: FontWeight.w500,
              shadows: widget.isSedi ? MessageBubble._sediTextShadows : null,
            ),
          );

    final column = Column(
      crossAxisAlignment:
          widget.isSedi ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        if (_canCollapseUserMessage) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? (widget.readLessLabel ?? 'Read less')
                  : (widget.readMoreLabel ?? 'Read more'),
              style: const TextStyle(
                color: SediPalette.pistachio300,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (widget.isFailed && widget.onRetry != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.onRetry,
            child: Text(
              widget.retryLabel ?? 'Tap to retry',
              style: const TextStyle(
                color: SediPalette.skin100,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );

    final body = widget.isSedi
        ? column
        : Directionality(
            textDirection: textDirection,
            child: column,
          );

    final showEdit = !widget.isSedi &&
        !widget.showTyping &&
        widget.onEdit != null &&
        widget.message.trim().isNotEmpty;

    Widget? editAction;
    if (showEdit) {
      editAction = Tooltip(
        message: widget.editLabel ?? 'Edit',
        child: GestureDetector(
          onTap: widget.onEdit,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Align(
              alignment: Alignment.topLeft,
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: SediPalette.sageMuted,
              ),
            ),
          ),
        ),
      );
    }

    // Assistant: plain text in chat space — no bubble/card/container.
    if (widget.isSedi) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            // Every Sedi message starts with her small hologram sphere (D-097).
            // The typing dots sit on the SAME line as her icon (D-101).
            child: Row(
              crossAxisAlignment: widget.showTyping
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: const SediHologramOrb(
                    state: Gate3InteractionState.idle,
                    diameter: MessageBubble.sediLogoDiameter,
                    showRings: false,
                    animate: false,
                    keyedLogo: false,
                  ),
                ),
                Flexible(
                  child: widget.showTyping
                      ? body
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: MessageBubble.sediTextTopInset,
                          ),
                          child: body,
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User only: visual container/bubble with collapse + retry.
    // The group stays physical-right for all locales. Edit sits fully
    // outside, below the bubble, aligned to the physical bottom-left.
    // Compact visual icon; 44dp hit target. Edit width is
    // not subtracted from the approved bubble max width.
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
            final bubbleMax = available.clamp(0.0, 300.0).toDouble();

            final bubble = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: bubbleMax),
              child: IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: SediPalette.pistachio900,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      topRight: Radius.circular(AppTheme.radiusLarge),
                      bottomLeft: Radius.circular(AppTheme.radiusLarge),
                      bottomRight: Radius.circular(AppTheme.radiusSmall),
                    ),
                    border: Border.all(
                      color: SediPalette.pistachio900,
                      width: 1,
                    ),
                  ),
                  child: body,
                ),
              ),
            );

            if (editAction == null) return bubble;

            return Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bubble,
                  const SizedBox(height: 4),
                  editAction!,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        );
      },
    );
  }

  Widget _dot(int index) {
    final phase = (_controller.value + (index * 0.2)) % 1.0;
    final pulse = 1 - ((phase - 0.5).abs() * 2);
    final opacity = 0.35 + (0.65 * pulse.clamp(0.0, 1.0).toDouble());
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: SediPalette.pistachio900,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

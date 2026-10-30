import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import 'gate3_attachment_flow.dart';
import 'gate3_attachment_menu.dart';
import 'gate3_composer_action_button.dart';

/// The room maths of the chat page (kept pure so it can be tested): how tall may the text area be so that the tray
/// spacer, the header, the resonance and the composer still fit above the keyboard?
class Gate3ComposerFit {
  Gate3ComposerFit._();

  /// Outer padding 18 + inner padding 16 + the button row 52.
  static const double chrome = 86;

  /// Estimation error we never want to pay for with a yellow overflow bar.
  static const double safety = 8;

  static const double minField = 44;

  /// Largest text-area height that keeps everything in view; below [minField] the page must make room first.
  static double maxField({required double available, required double above}) =>
      available - above - chrome - safety;

  /// The whole decision: the text-area cap and whether the header must give way on a very small screen.
  static ({double maxField, bool hideEcho}) plan({
    required double available,
    required double trayExtra,
    required double echoHeight,
    required double dockHeight,
    required double bannerHeight,
  }) {
    final withoutEcho = trayExtra + dockHeight + bannerHeight;
    final withEcho = maxField(available: available, above: withoutEcho + echoHeight);
    if (withEcho >= minField) return (maxField: withEcho, hideEcho: false);
    return (maxField: maxField(available: available, above: withoutEcho), hideEcho: true);
  }
}

/// Gate 3 composer. Pilot V1 (R-034): a liquid-glass capsule [attach] [text field] [mic / send / stop] with a
/// round pistachio 3D mic and a bare thin-line attach icon. Behaviour is unchanged.
class Gate3Composer extends StatefulWidget {
  final ValueChanged<String> onSendText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecordingAndSend;
  final bool isRecording;
  final String recordingTime;
  final String placeholder;
  final String lang;
  final bool isRtl;
  final ValueChanged<bool>? onListeningChanged;
  /// Populates the text field only. Does not send or insert transcript.
  final String? initialText;

  /// The most height the text area may take (the page knows what the keyboard and the header leave). The text then
  /// scrolls inside the field while the buttons stay in view. Null = the six-line cap only.
  final double? maxFieldHeight;

  const Gate3Composer({
    super.key,
    required this.onSendText,
    required this.onStartRecording,
    required this.onStopRecordingAndSend,
    required this.isRecording,
    required this.recordingTime,
    required this.placeholder,
    required this.lang,
    required this.isRtl,
    this.onListeningChanged,
    this.initialText,
    this.maxFieldHeight,
  });

  @override
  State<Gate3Composer> createState() => _Gate3ComposerState();
}

class _Gate3ComposerState extends State<Gate3Composer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _fieldScroll = ScrollController();
  // Keeps the TextField's element alive when the layout flips between the one-line row and the wide column;
  // without it the field is rebuilt, the input connection drops and the keyboard closes/opens while typing.
  final GlobalKey _fieldKey = GlobalKey(debugLabel: 'gate3ComposerField');
  // The paperclip: the attach icons rise from its top edge.
  final GlobalKey _attachKey = GlobalKey(debugLabel: 'gate3ComposerAttach');
  final Gate3AttachmentFlow _attachmentFlow = Gate3AttachmentFlow();

  // eight lines of the field style: 2 x 11 content padding + 8 x (16.2 x 1.35); then the text scrolls (with a scrollbar)
  static const double _maxTextHeight = 197;

  /// How visible the placeholder is (1 = like typed text).
  static const double hintVisibility = 0.40;
  static const double _minTextHeight = 44;
  static const double _capsuleRadius = 34;
  static const double _primarySize = 52;
  static const double _attachSize = 48;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialText?.trim();
    if (seed != null && seed.isNotEmpty) {
      _controller.text = seed;
      _controller.selection = TextSelection.collapsed(offset: seed.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
      });
    }
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_notifyListening);
    _onTextChanged();
  }

  @override
  void didUpdateWidget(covariant Gate3Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording) {
      _notifyListening();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_notifyListening);
    _controller.dispose();
    _focusNode.dispose();
    _fieldScroll.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
    // Defer parent listening callback so initState seeding never calls
    // setState on an ancestor during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyListening();
      setState(() {}); // the scroll thumb reads the field's extents, known only after layout
    });
  }

  void _notifyListening() {
    final listening = widget.isRecording ||
        _focusNode.hasFocus ||
        _controller.text.trim().isNotEmpty;
    widget.onListeningChanged?.call(listening);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
    _focusNode.unfocus();
    _notifyListening();
  }

  void _handleMic() {
    if (widget.isRecording) {
      widget.onStopRecordingAndSend();
    } else {
      widget.onStartRecording();
    }
  }

  Rect? _attachRect() {
    final box = _attachKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _openAttachmentMenu() {
    _focusNode.unfocus();
    Gate3AttachmentMenu.show(
      context,
      widget.lang,
      flow: _attachmentFlow,
      onTalk: widget.onSendText,
      anchor: _attachRect(),
    );
  }

  Widget _buildAttachButton() {
    return Gate3ComposerActionButton(
      key: _attachKey,
      icon: Icons.attach_file_rounded,
      size: _attachSize,
      iconSize: 28,
      bare: true,
      onTap: widget.isRecording ? null : _openAttachmentMenu,
    );
  }

  Widget _buildTextField({
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    // The button row is forced left-to-right (paperclip left, mic right), but the field keeps the
    // language's own direction: the placeholder is laid out with the AMBIENT direction, so without this
    // it jumped to the left in Persian/Arabic instead of sitting where typing starts.
    final cap = math.max(
      _minTextHeight,
      math.min(_maxTextHeight, widget.maxFieldHeight ?? _maxTextHeight),
    );
    return Directionality(
      textDirection: textDirection,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _minTextHeight,
          maxHeight: cap,
        ),
        // a thin, short scroll thumb appears beside the text as soon as it is longer than the box
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            TextField(
          scrollController: _fieldScroll,
          controller: _controller,
          focusNode: _focusNode,
          enabled: !widget.isRecording,
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textDirection: textDirection,
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          scrollPhysics: const BouncingScrollPhysics(),
          cursorColor: SediPalette.pistachio700,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 11, 8, 11),
            border: InputBorder.none,
            hintText: widget.placeholder,
            hintTextDirection: textDirection,
            // same size as the typed text, but only 40% visible (Javad 2026-10-30): it hints, it does not compete
            hintStyle: TextStyle(
              color: SediPalette.sageMuted.withOpacity(hintVisibility),
              fontSize: 16.2,
              height: 1.35,
            ),
            alignLabelWithHint: true,
          ),
          style: _fieldStyle,
          onSubmitted: (_) => _send(),
            ),
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: IgnorePointer(child: _FieldScrollThumb(controller: _fieldScroll)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBody() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minTextHeight),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SediPalette.skin700,
              boxShadow: [
                BoxShadow(
                  color: SediPalette.skin700.withOpacity(0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.recordingTime,
            style: const TextStyle(
              color: SediPalette.skin700,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(bool hasText) {
    if (widget.isRecording) {
      return Gate3ComposerActionButton(
        icon: Icons.stop_rounded,
        size: _primarySize,
        iconSize: 24,
        backgroundColor: SediPalette.skin700,
        iconColor: Colors.white,
        glowColor: SediPalette.skin700,
        onTap: _handleMic,
      );
    }
    if (hasText) {
      return Gate3ComposerActionButton(
        icon: Icons.arrow_upward_rounded,
        size: _primarySize,
        iconSize: 24,
        sphere: true,
        onTap: _send,
      );
    }
    return Gate3ComposerActionButton(
      icon: Icons.mic_rounded,
      size: _primarySize,
      iconSize: 24,
      sphere: true,
      onTap: _handleMic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    // From the first typed character the buttons sit BELOW the text, for any number of lines (Javad 2026-10-30).
    final buttonsBelow = !widget.isRecording && _controller.text.isNotEmpty;
    final textDirection =
        widget.isRtl ? TextDirection.rtl : TextDirection.ltr;
    // Typed lines are justified like the chat text: every wrapped line the same width.
    const textAlign = TextAlign.justify;
    const radius = BorderRadius.all(Radius.circular(_capsuleRadius));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SediGlass.blur(
        radius: radius,
        sigma: 20,
        child: DecoratedBox(
          decoration: SediGlass.capsule(radius),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
              builder: (context, box) {
                final field = KeyedSubtree(
                  key: _fieldKey,
                  child: widget.isRecording
                      ? _buildRecordingBody()
                      : _buildTextField(
                          textDirection: textDirection,
                          textAlign: textAlign,
                        ),
                );
                // Typing: the field sits on top with the WHOLE width and the buttons move below it - never the text
                // wrapping early between two buttons (Javad 2026-10-28, 2026-10-30).
                if (buttonsBelow) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: field,
                      ),
                      // the button order is physical, not language-bound: paperclip left, mic / send right
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            _buildAttachButton(),
                            const Spacer(),
                            _buildPrimaryAction(hasText),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    // empty box: the placeholder is level with the paperclip and the mic
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAttachButton(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: field,
                        ),
                      ),
                      _buildPrimaryAction(hasText),
                    ],
                  ),
                );
              },
            ),
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _fieldStyle = TextStyle(
    color: SediPalette.charcoal950,
    fontSize: 16.2,
    height: 1.35,
  );
}


/// The scroll thumb of the text area: a thin pistachio-dark pill, 40% of the length Flutter's own thumb would have
/// (Javad 2026-10-30), drawn only while the text is longer than the box.
class _FieldScrollThumb extends StatelessWidget {
  final ScrollController controller;

  const _FieldScrollThumb({required this.controller});

  /// Share of the usual thumb length.
  static const double lengthShare = 0.4;
  static const double minLength = 14;

  /// The field's own vertical content padding (the scroll viewport sits inside it).
  static const double inset = 11;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.hasClients) return const SizedBox.shrink();
        final position = controller.position;
        if (!position.hasContentDimensions) return const SizedBox.shrink();
        final max = position.maxScrollExtent;
        if (max <= 0.5) return const SizedBox.shrink();
        final viewport = position.viewportDimension;
        final natural = viewport * viewport / (viewport + max);
        final length = math.max(minLength, natural * lengthShare);
        final fraction = (position.pixels / max).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned(
              top: inset + (viewport - length) * fraction,
              left: 0,
              right: 0,
              height: length,
              child: DecoratedBox(
                key: const ValueKey('composerScrollThumb'),
                decoration: BoxDecoration(
                  color: const Color(0x8048551F),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

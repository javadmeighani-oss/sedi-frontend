import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import 'gate3_attachment_flow.dart';
import 'gate3_attachment_menu.dart';
import 'gate3_composer_action_button.dart';

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
  });

  @override
  State<Gate3Composer> createState() => _Gate3ComposerState();
}

class _Gate3ComposerState extends State<Gate3Composer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  // Keeps the TextField's element alive when the layout flips between the one-line row and the wide column;
  // without it the field is rebuilt, the input connection drops and the keyboard closes/opens while typing.
  final GlobalKey _fieldKey = GlobalKey(debugLabel: 'gate3ComposerField');
  // The paperclip: the attach icons rise from its top edge.
  final GlobalKey _attachKey = GlobalKey(debugLabel: 'gate3ComposerAttach');
  final Gate3AttachmentFlow _attachmentFlow = Gate3AttachmentFlow();

  static const double _maxTextHeight = 168;
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
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
    // Defer parent listening callback so initState seeding never calls
    // setState on an ancestor during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyListening();
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
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: _minTextHeight,
        maxHeight: _maxTextHeight,
      ),
      child: TextField(
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
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: InputBorder.none,
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: SediPalette.sageMuted,
            fontSize: 12.8,
            height: 1.35,
          ),
          alignLabelWithHint: true,
        ),
        style: _fieldStyle,
        onSubmitted: (_) => _send(),
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
                // A long message gets the WHOLE width: the field sits on top and the buttons move below it,
                // instead of the text wrapping early between two buttons (Javad 2026-10-28).
                if (!widget.isRecording &&
                    _needsWideField(box.maxWidth, textDirection)) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: field,
                      ),
                      Row(
                        children: [
                          _buildAttachButton(),
                          const Spacer(),
                          _buildPrimaryAction(hasText),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                );
              },
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

  /// True when the current text does not fit one line between the two buttons (or has a line break).
  bool _needsWideField(double rowWidth, TextDirection direction) {
    final text = _controller.text;
    if (text.trim().isEmpty) return false;
    if (text.contains('\n')) return true;
    // the attach and primary buttons + the field's horizontal padding
    final narrow = rowWidth - (_attachSize + _primarySize) - 20;
    if (narrow <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: _fieldStyle),
      textDirection: direction,
    )..layout(maxWidth: narrow);
    return painter.computeLineMetrics().length > 1;
  }
}

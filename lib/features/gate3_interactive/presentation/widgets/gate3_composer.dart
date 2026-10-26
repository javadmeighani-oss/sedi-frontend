import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';
import 'gate3_attachment_flow.dart';
import 'gate3_attachment_menu.dart';
import 'gate3_composer_action_button.dart';

/// Gate 3 composer. Hologram redesign: a floating glass capsule
/// [+] [text field] [mic / send / stop]. Behaviour is unchanged.
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
  final Gate3AttachmentFlow _attachmentFlow = Gate3AttachmentFlow();

  static const double _maxTextHeight = 168;
  static const double _minTextHeight = 44;
  static const double _capsuleRadius = 29;

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

  void _openAttachmentMenu() {
    _focusNode.unfocus();
    Gate3AttachmentMenu.show(
      context,
      widget.lang,
      flow: _attachmentFlow,
      onTalk: widget.onSendText,
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
        style: const TextStyle(
          color: SediPalette.charcoal950,
          fontSize: 16.2,
          height: 1.35,
        ),
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
        size: 44,
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
        size: 44,
        iconSize: 24,
        backgroundColor: SediPalette.pistachio500,
        iconColor: SediPalette.charcoal950,
        glowColor: SediPalette.pistachio300,
        onTap: _send,
      );
    }
    return Gate3ComposerActionButton(
      icon: Icons.mic_rounded,
      size: 44,
      iconSize: 24,
      backgroundColor: SediPalette.pistachio500,
      iconColor: SediPalette.charcoal950,
      glowColor: SediPalette.pistachio300,
      onTap: _handleMic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final textDirection =
        widget.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = widget.isRtl ? TextAlign.right : TextAlign.left;
    const radius = BorderRadius.all(Radius.circular(_capsuleRadius));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: SediPalette.sageSurface.withOpacity(0.96),
              border: Border.all(
                color: SediPalette.sageLine,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Gate3ComposerActionButton(
                    icon: Icons.add_rounded,
                    size: 44,
                    iconSize: 22,
                    onTap: widget.isRecording ? null : _openAttachmentMenu,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: widget.isRecording
                          ? _buildRecordingBody()
                          : _buildTextField(
                              textDirection: textDirection,
                              textAlign: textAlign,
                            ),
                    ),
                  ),
                  _buildPrimaryAction(hasText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

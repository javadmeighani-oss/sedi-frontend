import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================
/// InputBar - چت باکس صدی
/// ============================================
///
/// CONTRACT:
/// - Full width (edge-to-edge within SafeArea); pill shape; Apple-like.
/// - Border: subtle neutral (AppTheme). Icons: neutral when disabled, accent when enabled.
/// - RTL: mic on start side, send on end side; tap targets >= 44x44.
/// ============================================
class InputBar extends StatefulWidget {
  final String hintText;
  final bool isRecording;
  final String recordingTime;
  final ValueChanged<String> onSendText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecordingAndSend;

  const InputBar({
    super.key,
    required this.hintText,
    required this.isRecording,
    required this.recordingTime,
    required this.onSendText,
    required this.onStartRecording,
    required this.onStopRecordingAndSend,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const double _pillMinHeight = 56.0;

  /// Max height for multi-line input (~6 lines at 16px font + line spacing)
  static const double _pillMaxHeight = 140.0;
  static const double _pillRadius = 18.0;
  static const double _internalPadding = 16.0;
  static const double _iconTapSize = 44.0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _textController.clear();
    _focusNode.unfocus();
  }

  void _handleMicTap() {
    if (widget.isRecording) {
      widget.onStopRecordingAndSend();
    } else {
      widget.onStartRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(_internalPadding, 8, _internalPadding, 8),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: _pillMinHeight,
          maxHeight: _pillMaxHeight,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(_pillRadius),
          border: Border.all(
            color: AppTheme.borderInactive.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Material(
          color: AppTheme.backgroundWhite.withOpacity(0),
          child: InkWell(
            borderRadius: BorderRadius.circular(_pillRadius),
            onTap: () {
              if (!widget.isRecording)
                FocusScope.of(context).requestFocus(_focusNode);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: widget.isRecording
                        ? _buildRecordingContent()
                        : ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: _pillMaxHeight - 16),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              enabled: !widget.isRecording,
                              minLines: 1,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration.collapsed(
                                hintText: widget.hintText,
                                hintStyle: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                              onSubmitted: (_) => _sendText(),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  if (isRtl) ...[
                    _buildSendButton(hasText),
                    const SizedBox(width: 4),
                    _buildMicButton()
                  ] else ...[
                    _buildMicButton(),
                    const SizedBox(width: 4),
                    _buildSendButton(hasText)
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.recordingTime,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton(bool hasText) {
    return SizedBox(
      width: _iconTapSize,
      height: _iconTapSize,
      child: InkResponse(
        onTap: hasText ? _sendText : null,
        radius: _iconTapSize / 2,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasText ? AppTheme.pistachioGreen : AppTheme.iconInactive,
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              size: 22,
              color: AppTheme.backgroundWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return SizedBox(
      width: _iconTapSize,
      height: _iconTapSize,
      child: InkResponse(
        onTap: _handleMicTap,
        radius: _iconTapSize / 2,
        child: Center(
          child: Icon(
            Icons.mic_rounded,
            size: 26,
            color: widget.isRecording
                ? AppTheme.iconInactive
                : AppTheme.primaryBlack,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================
/// InputBar - چت باکس صدی
/// ============================================
/// 
/// CONTRACT:
/// - ChatGPT-style input box
/// - Border: primaryBlack (always)
/// - Icons: primaryBlack (default)
/// - Clean, medical-grade UI
/// - NO pistachio green, NO opacity hacks, NO glow effects
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
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          // Only expand when typing, NOT when recording
          _isExpanded = _focusNode.hasFocus && !widget.isRecording;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording) {
      setState(() {
        // Prevent expansion during recording
        _isExpanded = _focusNode.hasFocus && !widget.isRecording;
      });
    }
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
      // Second tap: stop recording
      widget.onStopRecordingAndSend();
    } else {
      // First tap: start recording
      widget.onStartRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;
    // Compact height when not expanded or recording
    final height = (_isExpanded && !widget.isRecording) ? 120.0 : 56.0;

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.primaryBlack, // Always primaryBlack
            width: 1.5,
          ),
        ),
        child: _isExpanded && !widget.isRecording
            ? _buildExpandedLayout(hasText)
            : _buildCompactLayout(hasText),
      ),
    );
  }

  /// Compact layout (default state)
  /// Icon order from RIGHT to LEFT: [SEND] [TIMER (if recording)] [SPEAKER] [TEXT FIELD]
  Widget _buildCompactLayout(bool hasText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LEFT SIDE: TextField (empty when recording)
        Expanded(
          child: widget.isRecording
              ? const SizedBox.shrink() // Empty when recording
              : TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: !widget.isRecording,
                  maxLines: 1,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: AppTheme.metalGrey,
                      fontSize: 15,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 15,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendText(),
                ),
        ),

        const SizedBox(width: 12),

        // RIGHT SIDE: Icons in correct order
        // From RIGHT edge: [SEND] [TIMER (if recording)] [SPEAKER]
        _buildSendIcon(hasText),
        if (widget.isRecording) ...[
          const SizedBox(width: 8),
          _buildRecordingTimer(),
        ],
        const SizedBox(width: 8),
        _buildSpeakerIcon(),
      ],
    );
  }

  /// Expanded layout (typing state)
  /// Same icon order as compact
  Widget _buildExpandedLayout(bool hasText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Text field at top
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            enabled: !widget.isRecording,
            maxLines: null,
            decoration: InputDecoration.collapsed(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: AppTheme.metalGrey,
                fontSize: 15,
              ),
            ),
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 15,
            ),
            textInputAction: TextInputAction.newline,
          ),
        ),

        // Icons at bottom-right (same order as compact)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSendIcon(hasText),
            if (widget.isRecording) ...[
              const SizedBox(width: 8),
              _buildRecordingTimer(),
            ],
            const SizedBox(width: 8),
            _buildSpeakerIcon(),
          ],
        ),
      ],
    );
  }

  /// Recording timer (appears between SEND and SPEAKER when recording)
  Widget _buildRecordingTimer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recording indicator (red dot)
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        // Timer text from recordingTimeFormatted
        Text(
          widget.recordingTime,
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Send icon (ChatGPT-style: white arrow inside black circle)
  /// Always: primaryBlack circle with white arrow
  Widget _buildSendIcon(bool hasText) {
    return GestureDetector(
      onTap: hasText ? _sendText : () {},
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryBlack, // Always black circle
        ),
        child: const Icon(
          Icons.arrow_upward_rounded,
          size: 20,
          color: AppTheme.backgroundWhite, // Always white arrow
        ),
      ),
    );
  }

  /// Speaker (mic) icon (simple mic without circle)
  /// Default: primaryBlack
  /// When recording: metalGrey
  Widget _buildSpeakerIcon() {
    return GestureDetector(
      onTap: _handleMicTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.mic_rounded,
          size: 28,
          color: widget.isRecording
              ? AppTheme.metalGrey // Lighter when recording
              : AppTheme.primaryBlack, // Normal when idle (default black)
        ),
      ),
    );
  }
}

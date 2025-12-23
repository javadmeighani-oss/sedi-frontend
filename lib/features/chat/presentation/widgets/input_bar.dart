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
    // Height reduced by 20%: 112.0 * 0.8 = 89.6 ≈ 90.0
    const height = 90.0;

    // Calculate width: 2.5x the original width
    // Original: screenWidth - 16 (8px margin on each side)
    // New: screenWidth - 6 (3px margin on each side) ≈ 2.5x wider
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth =
        screenWidth - 6; // 2.5x wider than original (screenWidth - 16)

    // Remove SafeArea from InputBar - ChatPage handles it
    return Container(
      width: containerWidth,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.borderActive, // Using AppTheme semantic color
          width: 1.5,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Capture all taps in the container
        onTap: () {
          // When user taps anywhere on InputBar, focus TextField to open keyboard
          if (!widget.isRecording) {
            FocusScope.of(context).requestFocus(_focusNode);
          }
        },
        child: _buildNewLayout(hasText),
      ),
    );
  }

  /// New layout with reduced height (20% smaller)
  /// - TextField: top-left
  /// - Recording text: bottom-left (when recording)
  /// - Icons (bottom-right): [SEND] [SPEAKER] [TIMER (if recording)]
  Widget _buildNewLayout(bool hasText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // TOP-LEFT: TextField
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
            ),
          ],
        ),

        // BOTTOM ROW: Recording text on left, Icons on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // LEFT SIDE: Recording text (when recording)
            if (widget.isRecording)
              Text(
                'مکالمه با صدا', // Short text for voice conversation
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const SizedBox.shrink(),

            const Spacer(),

            // BOTTOM-RIGHT: Icons order from right to left
            // Order: [SEND] (bottom-right) → [SPEAKER] (middle) → [TIMER] (leftmost, if recording)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Send icon (bottom-right, rightmost position)
                _buildSendIcon(hasText),
                const SizedBox(width: 8),
                // 2. Speaker icon (middle)
                _buildSpeakerIcon(),
                // 3. Timer (leftmost, only when recording)
                if (widget.isRecording) ...[
                  const SizedBox(width: 8),
                  _buildRecordingTimer(),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Recording timer (appears after MIC when recording)
  /// Color: black (primaryBlack) to match Sedi theme
  Widget _buildRecordingTimer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recording indicator (black dot - matching Sedi theme)
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.textPrimary, // Black to match Sedi theme
          ),
        ),
        const SizedBox(width: 8),
        // Timer text from recordingTimeFormatted (black color)
        Text(
          widget.recordingTime,
          style: const TextStyle(
            color: AppTheme.textPrimary, // Black color
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Send icon (ChatGPT-style: white arrow inside black circle)
  /// primaryBlack circle when hasText, metalGrey when empty
  /// Size: 20% larger (32 -> 38, arrow 20 -> 24)
  Widget _buildSendIcon(bool hasText) {
    return GestureDetector(
      onTap: hasText ? _sendText : () {},
      child: Container(
        width: 38, // 32 * 1.2 = 38.4 ≈ 38
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasText
              ? AppTheme.iconActive
              : AppTheme
                  .iconInactive, // Active when user types, inactive otherwise
        ),
        child: const Icon(
          Icons.arrow_upward_rounded,
          size: 24, // 20 * 1.2 = 24
          color: AppTheme.backgroundWhite, // Always white arrow
        ),
      ),
    );
  }

  /// Speaker (mic) icon (simple mic without circle)
  /// Default: primaryBlack
  /// When recording: metalGrey
  /// Size: 20% larger (28 -> 34)
  Widget _buildSpeakerIcon() {
    return GestureDetector(
      onTap: _handleMicTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Icon(
          Icons.mic_rounded,
          size: 34, // 28 * 1.2 = 33.6 ≈ 34
          color: widget.isRecording
              ? AppTheme.iconInactive // Inactive when recording
              : AppTheme.iconActive, // Active when idle
        ),
      ),
    );
  }
}

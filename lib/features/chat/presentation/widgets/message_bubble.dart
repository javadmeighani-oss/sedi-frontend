import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSedi;
  final bool isFailed;
  final VoidCallback? onRetry;
  final bool showTyping;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSedi,
    this.isFailed = false,
    this.onRetry,
    this.showTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isSedi
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;

    final backgroundColor = isSedi
        ? AppTheme.backgroundWhite
        : AppTheme.metalGrey.withOpacity(0.15);

    final borderColor = isSedi
        ? AppTheme.metalGrey.withOpacity(0.25)
        : AppTheme.metalGrey.withOpacity(0.35);

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(AppTheme.radiusLarge),
      topRight: Radius.circular(AppTheme.radiusLarge),
      bottomLeft: Radius.circular(
        isSedi ? AppTheme.radiusSmall : AppTheme.radiusLarge,
      ),
      bottomRight: Radius.circular(
        isSedi ? AppTheme.radiusLarge : AppTheme.radiusSmall,
      ),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTyping)
              const _TypingDots()
            else
              Text(
                message,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            if (isFailed && onRetry != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(),
        const SizedBox(width: 4),
        _dot(),
        const SizedBox(width: 4),
        _dot(),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppTheme.iconInactive,
        shape: BoxShape.circle,
      ),
    );
  }
}

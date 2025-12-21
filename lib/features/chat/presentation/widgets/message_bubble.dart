import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSedi;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSedi,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isSedi ? Alignment.centerLeft : Alignment.centerRight;

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
        child: Text(
          message,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

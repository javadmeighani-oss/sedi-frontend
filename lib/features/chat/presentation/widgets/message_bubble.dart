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
    return Align(
      alignment: isSedi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isSedi
              ? AppTheme.backgroundWhite
              : AppTheme.metalGrey.withOpacity(0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusLarge),
            topRight: const Radius.circular(AppTheme.radiusLarge),
            bottomLeft: Radius.circular(
              isSedi ? 0 : AppTheme.radiusLarge,
            ),
            bottomRight: Radius.circular(
              isSedi ? AppTheme.radiusLarge : 0,
            ),
          ),
          border: Border.all(
            color: AppTheme.metalGrey.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Text(
          message,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

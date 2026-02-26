import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center, style: AppTheme.bodySecondary),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.borderInactive),
              ),
              child: const Text('Retry', style: AppTheme.bodyPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center, style: AppTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center, style: AppTheme.bodySecondary),
            ],
          ],
        ),
      ),
    );
  }
}

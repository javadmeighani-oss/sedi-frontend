import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppLoadingState extends StatelessWidget {
  final String? label;

  const AppLoadingState({
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (label != null) ...[
            const SizedBox(height: 10),
            Text(label!, style: AppTheme.bodySecondary),
          ],
        ],
      ),
    );
  }
}

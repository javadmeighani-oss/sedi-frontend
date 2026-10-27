import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/notification_feedback.dart' show kFeedbackReasonValues;
import '../notification_inbox_l10n.dart';

/// Bounded "why didn't you like it?" sheet (5 reasons). Returns the picked reason, or null when dismissed.
/// Shared by the notification inbox and the A3 chat page (reason for a tray dislike, P7).
Future<String?> showDislikeReasonSheet(
  BuildContext context,
  NotificationInboxL10n l10n,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.backgroundWhite,
    builder: (ctx) => Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dislikeReasonTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dislikeReasonHint,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kFeedbackReasonValues
                    .map(
                      (r) => ActionChip(
                        label: Text(l10n.dislikeReasonLabel(r)),
                        onPressed: () => Navigator.of(ctx).pop(r),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

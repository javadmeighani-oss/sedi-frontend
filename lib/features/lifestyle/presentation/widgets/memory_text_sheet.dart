import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../lifestyle_l10n.dart';

/// Bottom sheet with one text field (edit a message, add a note or a correction). Returns the trimmed text, or null
/// when cancelled / empty.
Future<String?> showMemoryTextSheet(
  BuildContext context, {
  required LifestyleL10n l10n,
  required String title,
  String initial = '',
  required String hint,
  int maxLength = 240,
  int maxLines = 4,
}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: A3DestinationSurface.canvas,
    builder: (ctx) => Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: maxLines,
              maxLength: maxLength,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.ctaFill,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    onPressed: () {
                      final t = controller.text.trim();
                      Navigator.pop(ctx, t.isEmpty ? null : t);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

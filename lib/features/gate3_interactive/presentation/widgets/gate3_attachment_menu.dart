import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../gate3_localization.dart';
import 'gate3_attachment_flow.dart';

/// Attachment entry sheet for the Gate 3 composer (R-021 / M4): camera, photos and files are real now.
class Gate3AttachmentMenu {
  Gate3AttachmentMenu._();

  static Future<void> show(
    BuildContext context,
    String lang, {
    required Gate3AttachmentFlow flow,
    required ValueChanged<String> onTalk,
  }) async {
    final l10n = Gate3Localization(lang);
    // Taken before the sheet closes: the flow keeps running after this context's sheet is popped.
    final hostContext = context;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.gate3PaleOliveBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        void pick(Gate3AttachmentSource source) {
          Navigator.of(ctx).pop();
          if (!hostContext.mounted) return;
          flow.runDocument(hostContext, lang, source, onTalk: onTalk);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AttachmentMenuItem(
                  icon: Icons.camera_alt_outlined,
                  label: l10n.camera,
                  onTap: () => pick(Gate3AttachmentSource.camera),
                ),
                const SizedBox(height: 8),
                _AttachmentMenuItem(
                  icon: Icons.photo_outlined,
                  label: l10n.photos,
                  onTap: () => pick(Gate3AttachmentSource.gallery),
                ),
                const SizedBox(height: 8),
                _AttachmentMenuItem(
                  icon: Icons.attach_file_outlined,
                  label: l10n.files,
                  onTap: () => pick(Gate3AttachmentSource.file),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SediPalette.shell100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SediPalette.pistachio100,
                ),
                child: Icon(icon, size: 22, color: AppTheme.primaryBlack),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';
import '../gate3_localization.dart';
import 'gate3_attachment_flow.dart';

/// Attachment entry for the Gate 3 composer (R-021 / M4): files, photos and the camera are real.
///
/// Pilot V1 (R-034, Javad 2026-10-29): no sheet, no scrim, no filled buttons and no visible text - three bare
/// thin-line icons rise one above the other from the paperclip, each in a hairline light ring. The labels live
/// only in the accessibility tree.
class Gate3AttachmentMenu {
  Gate3AttachmentMenu._();

  static const double ringSize = 53;
  static const double iconSize = 27;
  static const double gap = 14;

  /// [anchor] is the paperclip's rectangle in global coordinates; the stack rises from its top edge.
  static Future<void> show(
    BuildContext context,
    String lang, {
    required Gate3AttachmentFlow flow,
    required ValueChanged<String> onTalk,
    Rect? anchor,
  }) async {
    final l10n = Gate3Localization(lang);
    // Taken before the menu closes: the flow keeps running after this context's route is popped.
    final hostContext = context;
    final screen = MediaQuery.of(context).size;
    final from = anchor ??
        Rect.fromLTWH(screen.width - 64, screen.height - 110, 48, 48);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        void pick(Gate3AttachmentSource source) {
          Navigator.of(ctx).pop();
          if (!hostContext.mounted) return;
          flow.runDocument(hostContext, lang, source, onTalk: onTalk);
        }

        final left = (from.center.dx - ringSize / 2)
            .clamp(8.0, screen.width - ringSize - 8.0)
            .toDouble();
        final bottom = screen.height - from.top + 10;
        return Stack(
          children: [
            Positioned(
              left: left,
              bottom: bottom,
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AttachmentIcon(
                        icon: Icons.insert_drive_file_outlined,
                        label: l10n.files,
                        onTap: () => pick(Gate3AttachmentSource.file),
                      ),
                      const SizedBox(height: gap),
                      _AttachmentIcon(
                        icon: Icons.photo_library_outlined,
                        label: l10n.photos,
                        onTap: () => pick(Gate3AttachmentSource.gallery),
                      ),
                      const SizedBox(height: gap),
                      _AttachmentIcon(
                        icon: Icons.photo_camera_outlined,
                        label: l10n.camera,
                        onTap: () => pick(Gate3AttachmentSource.camera),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttachmentIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: Gate3AttachmentMenu.ringSize,
          height: Gate3AttachmentMenu.ringSize,
          decoration: SediGlass.lightRing(),
          child: Icon(
            icon,
            size: Gate3AttachmentMenu.iconSize,
            color: SediGlass.ink,
          ),
        ),
      ),
    );
  }
}

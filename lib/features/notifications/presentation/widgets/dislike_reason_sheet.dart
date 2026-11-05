import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../data/models/notification_feedback.dart' show kFeedbackReasonValues;
import '../notification_inbox_l10n.dart';

/// R-073 (Javad 2026-11-05): the "why not now?" panel is liquid glass. The three answers that mean "not now" come first as
/// large pills, the other reasons below as smaller ones; one tap answers (no confirm button). Returns the picked reason, or
/// null when dismissed. Shared by the notification inbox.
const List<String> kPrimaryReasons = <String>['busy_now', 'rest_time', 'not_in_mood'];

Future<String?> showDislikeReasonSheet(
  BuildContext context,
  NotificationInboxL10n l10n,
) {
  final others = kFeedbackReasonValues.where((r) => !kPrimaryReasons.contains(r)).toList();
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x42243008),
    isScrollControlled: true,
    builder: (ctx) => Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SediGlass.blur(
        radius: const BorderRadius.vertical(top: Radius.circular(30)),
        sigma: 28,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xA8F4F8DE),
            border: Border(top: BorderSide(color: Color(0xCCFFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x4748551F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.dislikeReasonTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: SediPalette.charcoal950,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.dislikeReasonHint,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.8,
                      color: SediPalette.sageMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final r in kPrimaryReasons) ...[
                    ReasonPill(
                      label: l10n.dislikeReasonLabel(r),
                      large: true,
                      onTap: () => Navigator.of(ctx).pop(r),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.dislikeReasonMore,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: SediPalette.sageMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in others)
                        ReasonPill(
                          label: l10n.dislikeReasonLabel(r),
                          large: false,
                          onTap: () => Navigator.of(ctx).pop(r),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One glass answer. Touch target >= 44 dp (the large one 52 dp).
class ReasonPill extends StatelessWidget {
  final String label;
  final bool large;
  final VoidCallback onTap;

  const ReasonPill({
    super.key,
    required this.label,
    required this.large,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(large ? 26 : 22);
    final text = Text(
      label,
      style: TextStyle(
        color: SediGlass.inkDeep,
        fontSize: large ? 16 : 13.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: large ? double.infinity : null,
          constraints: BoxConstraints(minHeight: large ? 52 : 44),
          padding: EdgeInsets.symmetric(horizontal: large ? 20 : 16, vertical: 8),
          alignment: large ? AlignmentDirectional.centerStart : Alignment.center,
          decoration: SediGlass.pill().copyWith(borderRadius: radius),
          child: text,
        ),
      ),
    );
  }
}

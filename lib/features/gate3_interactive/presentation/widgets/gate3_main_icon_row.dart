import 'package:flutter/material.dart';

import '../../../../core/theme/sedi_palette.dart';
import '../gate3_localization.dart';
import '../pages/gate3_profile_page.dart';
import 'gate3_main_icon_button.dart';

/// A3 top row: Profile | Lifestyle | Gadgets | Smart Notifications.
/// Health lives inside Lifestyle (no separate top Health icon).
class Gate3MainIconRow extends StatelessWidget {
  final VoidCallback onLifestyle;
  final VoidCallback onGadgets;
  final VoidCallback onNotifications;
  final String lang;
  /// Backend canonical unread SENT-history count. Zero/null → no badge.
  final int? unreadNotificationCount;

  const Gate3MainIconRow({
    super.key,
    required this.onLifestyle,
    required this.onGadgets,
    required this.onNotifications,
    required this.lang,
    this.unreadNotificationCount,
  });

  Gate3Localization get _l10n => Gate3Localization(lang);

  Widget? _notificationsBadge() {
    final count = unreadNotificationCount;
    if (count == null || count <= 0) return null;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: SediPalette.skin500,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Row(
      children: [
        Expanded(
          child: Gate3MainIconButton(
            icon: Icons.person_outline,
            label: l10n.profileTitle,
            plainIcon: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Gate3ProfilePage(),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Gate3MainIconButton(
            icon: Icons.self_improvement_outlined,
            label: l10n.lifestyle,
            onTap: onLifestyle,
          ),
        ),
        Expanded(
          child: Gate3MainIconButton(
            icon: Icons.devices_other_outlined,
            label: l10n.gadgets,
            onTap: onGadgets,
          ),
        ),
        Expanded(
          child: Gate3MainIconButton(
            icon: Icons.notifications_none_outlined,
            label: l10n.notifications,
            plainIcon: true,
            badge: _notificationsBadge(),
            onTap: onNotifications,
          ),
        ),
      ],
    );
  }
}

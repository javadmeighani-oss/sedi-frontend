import 'package:flutter/material.dart';

import '../../../notifications/presentation/pages/notification_inbox_page.dart';

/// Route-stable wrapper for legacy imports.
/// Keeps existing navigation references intact while using new inbox implementation.
class NotificationsInboxPage extends StatelessWidget {
  const NotificationsInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationInboxPage();
  }
}

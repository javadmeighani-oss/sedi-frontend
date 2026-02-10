/// Notifications Inbox - Apple-like list with pull-to-refresh, Like/Dislike.
/// Respects RTL for FA/AR; default English LTR.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/models/notification.dart' as sedi;
import '../../../../data/models/notification_feedback.dart';
import '../../data/notification_service.dart';
import '../widgets/notification_card.dart';

class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  final NotificationService _service = NotificationService();
  List<sedi.Notification> _notifications = [];
  bool _loading = true;
  String? _error;
  final Set<String> _readIds = {};
  final Map<String, SelectedReaction> _reactionState = {};
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadNotifications();
  }

  Future<void> _loadLanguage() async {
    final lang = await UserPreferences.getUserLanguage();
    if (mounted) setState(() => _language = lang);
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'User not found';
        _notifications = [];
      });
      return;
    }
    final resp = await _service.getNotifications(userId: userId, limit: 50);
    if (!mounted) return;
    if (resp['ok'] != true) {
      setState(() {
        _loading = false;
        _error = resp['error']?['message']?.toString() ?? 'Failed to load';
        _notifications = [];
      });
      return;
    }
    final data = resp['data'] as Map<String, dynamic>?;
    final list = data?['notifications'] as List<dynamic>?;
    final items = <sedi.Notification>[];
    if (list != null) {
      for (final e in list) {
        try {
          items.add(sedi.Notification.fromJson(Map<String, dynamic>.from(e as Map)));
        } catch (_) {}
      }
    }
    setState(() {
      _loading = false;
      _error = null;
      _notifications = items;
    });
  }

  Future<void> _onTapNotification(sedi.Notification n) async {
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) return;
    final resp = await _service.markRead(notificationId: n.id, userId: userId);
    if (resp['ok'] == true && mounted) {
      setState(() => _readIds.add(n.id));
    }
  }

  Future<void> _onLike({required String notificationId}) async {
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) return;
    setState(() => _reactionState[notificationId] = SelectedReaction.like);
    final feedback = NotificationFeedback.create(
      notificationId: notificationId,
      actionId: 'tap_like',
      reaction: FeedbackReaction.like,
    );
    await _service.submitFeedback(feedback);
  }

  Future<void> _onDislike({required String notificationId}) async {
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) return;
    setState(() => _reactionState[notificationId] = SelectedReaction.dislike);
    final feedback = NotificationFeedback.create(
      notificationId: notificationId,
      actionId: 'tap_dislike',
      reaction: FeedbackReaction.dislike,
    );
    await _service.submitFeedback(feedback);
  }

  bool get _isRtl => _language == 'fa' || _language == 'ar';

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading && _notifications.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: AppTheme.pistachioGreen));
    } else if (_error != null && _notifications.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppTheme.pistachioGreen,
        child: _notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Text('No notifications', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return NotificationCard(
                    notification: n,
                    selectedReaction: _reactionState[n.id] ?? SelectedReaction.none,
                    displayAsUnread: !n.isRead && !_readIds.contains(n.id),
                    onTap: () => _onTapNotification(n),
                    onLike: (f) => _onLike(notificationId: f.notificationId),
                    onDislike: (f) => _onDislike(notificationId: f.notificationId),
                  );
                },
              ),
      );
    }

    Widget page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryBlack,
      ),
      body: body,
    );

    if (_isRtl) {
      page = Directionality(
        textDirection: TextDirection.rtl,
        child: page,
      );
    }
    return page;
  }
}

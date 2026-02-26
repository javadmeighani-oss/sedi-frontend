import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states/app_empty_state.dart';
import '../../../../core/widgets/app_states/app_error_state.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../services/notifications/inbox_refresh_bus.dart';
import '../../../../services/notifications/notifications_service.dart';
import '../../../auth_otp/presentation/pages/otp_login_page.dart';

enum InboxFilter { all, unread }

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  final NotificationsService _service = NotificationsService();
  final Set<int> _pendingReadIds = <int>{};
  final Set<int> _likedIds = <int>{};
  final Set<int> _dislikedIds = <int>{};

  List<NotificationItem> _items = const <NotificationItem>[];
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  InboxFilter _filter = InboxFilter.all;
  StreamSubscription<void>? _refreshSub;

  @override
  void initState() {
    super.initState();
    _refreshSub = InboxRefreshBus.instance.stream.listen((_) {
      _reload(soft: true);
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = await UserIdentityService.resolveUserId();
    if (!mounted) return;
    if (userId == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OtpLoginPage()),
      );
      return;
    }
    await _reload();
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _reload({bool soft = false}) async {
    if (_loading || _refreshing) return;
    if (soft) {
      _refreshing = true;
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final resp = await _service.listInbox(
      unreadOnly: _filter == InboxFilter.unread,
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
      if (resp.ok) {
        _items = _dedupeById(resp.data ?? const <NotificationItem>[]);
        _error = null;
      } else {
        _error = resp.errorMessage;
      }
    });
  }

  List<NotificationItem> _dedupeById(List<NotificationItem> list) {
    final byId = <int, NotificationItem>{};
    for (final item in list) {
      byId[item.id] = item;
    }
    final deduped = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deduped;
  }

  Future<void> _markReadOptimistic(NotificationItem item) async {
    if (item.isRead || _pendingReadIds.contains(item.id)) return;

    final previous = List<NotificationItem>.from(_items);
    setState(() {
      _pendingReadIds.add(item.id);
      _items = _items
          .map((e) => e.id == item.id ? e.copyWith(isRead: true) : e)
          .toList(growable: false);
    });

    final resp = await _service.markRead(item.id);
    if (!mounted) return;

    if (!resp.ok) {
      setState(() {
        _items = previous;
        _pendingReadIds.remove(item.id);
      });
      _showMessage(resp.errorMessage);
      return;
    }

    setState(() {
      _pendingReadIds.remove(item.id);
    });
  }

  Future<void> _sendFeedback(NotificationItem item,
      {required bool liked}) async {
    if (liked && _likedIds.contains(item.id)) return;
    if (!liked && _dislikedIds.contains(item.id)) return;

    if (liked) {
      setState(() {
        _likedIds.add(item.id);
        _dislikedIds.remove(item.id);
      });
    } else {
      setState(() {
        _dislikedIds.add(item.id);
        _likedIds.remove(item.id);
      });
    }

    final resp = await _service.sendFeedback(item.id, liked: liked);
    if (!mounted) return;
    if (!resp.ok) {
      _showMessage(resp.errorMessage);
    }
  }

  Future<void> _openDetails(NotificationItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _channelPill(item.channel),
                const SizedBox(height: 12),
                Text(
                  item.title.isEmpty ? 'Notification' : item.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: item.isRead
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                await _markReadOptimistic(item);
                              },
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AppTheme.borderInactive),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: const Text(
                          'Mark as read',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _sendFeedback(item, liked: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: AppTheme.backgroundWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: const Text('Like'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _sendFeedback(item, liked: false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.metalGrey,
                          foregroundColor: AppTheme.backgroundWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: const Text('Dislike'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  String _displayBody(NotificationItem item) {
    if (item.body.trim().isNotEmpty) return item.body.trim();
    return 'No details';
  }

  Widget _channelPill(String channel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.metalGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        channel.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBlack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                _filterChip(
                  label: 'All',
                  selected: _filter == InboxFilter.all,
                  onTap: () {
                    if (_filter == InboxFilter.all) return;
                    setState(() => _filter = InboxFilter.all);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Unread',
                  selected: _filter == InboxFilter.unread,
                  onTap: () {
                    if (_filter == InboxFilter.unread) return;
                    setState(() => _filter = InboxFilter.unread);
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlack : AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primaryBlack : AppTheme.borderInactive,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.backgroundWhite : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingState(label: 'Loading notifications...');
    }
    if (_error != null && _items.isEmpty) {
      return AppErrorState(message: _error!, onRetry: _reload);
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        color: AppTheme.primaryBlack,
        child: const ListView(
          children: [
            SizedBox(height: 160),
            AppEmptyState(
              title: 'No notifications yet',
              subtitle: 'You are all caught up for now.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppTheme.primaryBlack,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final displayUnread =
              !item.isRead && !_pendingReadIds.contains(item.id);
          return GestureDetector(
            onTap: () async {
              await _markReadOptimistic(item);
              await _openDetails(item);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border:
                    Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _channelPill(item.channel),
                      const Spacer(),
                      if (displayUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.pistachioGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title.isEmpty ? 'Notification' : item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayBody(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _relativeTime(item.createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 18,
                        color: _likedIds.contains(item.id)
                            ? AppTheme.primaryBlack
                            : AppTheme.iconInactive,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.thumb_down_alt_outlined,
                        size: 18,
                        color: _dislikedIds.contains(item.id)
                            ? AppTheme.primaryBlack
                            : AppTheme.iconInactive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

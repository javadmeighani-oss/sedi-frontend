import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states/app_empty_state.dart';
import '../../../../core/widgets/app_states/app_error_state.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../core/navigation/app_gate_router.dart';
import '../../../../services/notifications/inbox_refresh_bus.dart';
import '../../../../services/notifications/notifications_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../notification_inbox_l10n.dart';

enum InboxFilter { all, unread }

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  final NotificationsService _service = NotificationsService();
  final Set<int> _pendingReadIds = <int>{};
  final ScrollController _scrollController = ScrollController();

  List<NotificationItem> _items = const <NotificationItem>[];
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _nextCursor;
  String? _error;
  InboxFilter _filter = InboxFilter.all;
  StreamSubscription<void>? _refreshSub;

  NotificationInboxL10n get _l10n =>
      NotificationInboxL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    SediLocaleController.instance.addListener(_onLocale);
    _scrollController.addListener(_onScroll);
    _refreshSub = InboxRefreshBus.instance.stream.listen((_) {
      _reload(soft: true);
    });
    _bootstrap();
  }

  void _onLocale() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    final userId = await UserIdentityService.resolveUserId();
    if (!mounted) return;
    if (userId == null) {
      AppGateRouter.goToLogin(context);
      return;
    }
    await _reload();
  }

  @override
  void dispose() {
    SediLocaleController.instance.removeListener(_onLocale);
    _refreshSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
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
    final resp = await _service.listInboxPage(
      unreadOnly: _filter == InboxFilter.unread,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
      if (resp.ok && resp.data != null) {
        _items = _dedupeById(resp.data!.items);
        _nextCursor = resp.data!.nextCursor;
        _hasMore = resp.data!.hasMore;
        _error = null;
      } else {
        _error = resp.errorMessage;
      }
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    final resp = await _service.listInboxPage(
      unreadOnly: _filter == InboxFilter.unread,
      limit: 20,
      cursor: _nextCursor,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (resp.ok && resp.data != null) {
        _items = _dedupeById([..._items, ...resp.data!.items]);
        _nextCursor = resp.data!.nextCursor;
        _hasMore = resp.data!.hasMore;
      }
    });
  }

  List<NotificationItem> _dedupeById(List<NotificationItem> list) {
    final byId = <int, NotificationItem>{};
    for (final item in list) {
      byId[item.id] = item;
    }
    final deduped = byId.values.toList()
      ..sort((a, b) {
        final aTs = a.sentAt ?? a.createdAt;
        final bTs = b.sentAt ?? b.createdAt;
        final cmp = bTs.compareTo(aTs);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });
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
    InboxRefreshBus.instance.triggerDebounced();
  }

  Future<void> _openDetails(
      NotificationItem item, NotificationInboxL10n l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
        final maxHeight = media.size.height * 0.85;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 24 + media.viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _categoryPill(item, l10n),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title.isEmpty
                                ? l10n.fallbackTitle
                                : item.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.body.trim().isEmpty
                                ? l10n.noDetails
                                : item.body,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.relativeTime(item.sentAt ?? item.createdAt),
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: item.isRead
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await _markReadOptimistic(item);
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                      child: Text(l10n.markAsRead),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayBody(NotificationItem item, NotificationInboxL10n l10n) {
    if (item.body.trim().isNotEmpty) return item.body.trim();
    return l10n.noDetails;
  }

  String _categorySource(NotificationItem item) {
    final meta = item.metadata;
    if (meta != null) {
      final cat = meta['category'] ?? meta['gate4_category'];
      if (cat != null && cat.toString().trim().isNotEmpty) {
        return cat.toString();
      }
    }
    return item.channel;
  }

  Widget _categoryPill(NotificationItem item, NotificationInboxL10n l10n) {
    final label = l10n.categoryLabel(_categorySource(item));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.metalGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
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
    final l10n = _l10n;
    Widget page = Scaffold(
      backgroundColor: A3DestinationSurface.canvas,
      appBar: A3PageAppBar(
        title: Text(l10n.title),
        backgroundColor: A3DestinationSurface.canvas,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                _filterChip(
                  label: l10n.filterAll,
                  selected: _filter == InboxFilter.all,
                  onTap: () {
                    if (_filter == InboxFilter.all) return;
                    setState(() => _filter = InboxFilter.all);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: l10n.filterUnread,
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
            child: _buildBody(l10n),
          ),
        ],
      ),
    );

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: page,
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
          color: selected
              ? AppTheme.gate2ButtonOlive.withOpacity(0.14)
              : AppTheme.gate2CardWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.gate2ButtonOlive
                : AppTheme.gate2BorderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.gate2ButtonOlive : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationInboxL10n l10n) {
    if (_loading) {
      return AppLoadingState(label: l10n.loading);
    }
    if (_error != null && _items.isEmpty) {
      return AppErrorState(message: _error!, onRetry: _reload);
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        color: AppTheme.primaryBlack,
        child: ListView(
          children: [
            const SizedBox(height: 160),
            AppEmptyState(
              title: l10n.emptyTitle,
              subtitle: l10n.emptySubtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppTheme.primaryBlack,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = _items[index];
          final displayUnread =
              !item.isRead && !_pendingReadIds.contains(item.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: A3DestinationCard(
              onTap: () async {
                await _markReadOptimistic(item);
                await _openDetails(item, l10n);
              },
              child: Opacity(
                opacity: displayUnread ? 1 : 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _categoryPill(item, l10n),
                        const Spacer(),
                        if (displayUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.gate2ButtonOlive,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title.isEmpty ? l10n.fallbackTitle : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight:
                            displayUnread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayBody(item, l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.relativeTime(item.sentAt ?? item.createdAt),
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

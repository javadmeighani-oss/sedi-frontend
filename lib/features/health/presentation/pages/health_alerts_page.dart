import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../core/widgets/app_states/app_empty_state.dart';
import '../../../../core/widgets/app_states/app_error_state.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../services/health/health_alerts_service.dart';
import '../../../auth_otp/presentation/pages/otp_login_page.dart';

class HealthAlertsPage extends StatefulWidget {
  const HealthAlertsPage({super.key});

  @override
  State<HealthAlertsPage> createState() => _HealthAlertsPageState();
}

class _HealthAlertsPageState extends State<HealthAlertsPage> {
  final HealthAlertsService _service = HealthAlertsService();
  final Set<int> _likedIds = <int>{};
  final Set<int> _dislikedIds = <int>{};

  List<NotificationItem> _items = const [];
  bool _loading = true;
  String? _error;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final profile = await UserProfileManager.loadProfile();
    _lang =
        profile.preferredLanguage.isNotEmpty ? profile.preferredLanguage : 'en';
    await _load();
  }

  Future<void> _load() async {
    final userId = await UserIdentityService.resolveUserId();
    if (userId == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OtpLoginPage()),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.listHealthAlerts(userId: userId, limit: 80);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.data ?? const [];
      _error = res.ok ? null : res.errorMessage;
    });
  }

  bool get _isRtl => _lang == 'fa' || _lang == 'ar';

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryBlack,
        title: const Text('Health Alerts'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBlack,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: page,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListView(
        children: [
          SizedBox(height: 120),
          AppLoadingState(label: 'Loading health alerts...'),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          AppErrorState(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_items.isEmpty) {
      return const ListView(
        children: [
          SizedBox(height: 120),
          AppEmptyState(
            title: 'No health alerts yet',
            subtitle: 'You will see important alerts here.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return GestureDetector(
          onTap: () => _openDetails(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border:
                  Border.all(color: AppTheme.borderInactive.withOpacity(0.25)),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!item.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlack,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (!item.isRead) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isNotEmpty ? item.title : 'Health alert',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _relativeTime(item.createdAt),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        );
      },
    );
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : 'Health alert',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: item.isRead
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                await _service.markRead(item.id);
                                await _load();
                              },
                        child: const Text(
                          'Mark read',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _likedIds.contains(item.id)
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                setState(() {
                                  _likedIds.add(item.id);
                                  _dislikedIds.remove(item.id);
                                });
                                await _service.sendFeedback(item.id,
                                    liked: true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: AppTheme.backgroundWhite,
                        ),
                        child: const Text('Like'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _dislikedIds.contains(item.id)
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                setState(() {
                                  _dislikedIds.add(item.id);
                                  _likedIds.remove(item.id);
                                });
                                await _service.sendFeedback(item.id,
                                    liked: false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.metalGrey,
                          foregroundColor: AppTheme.backgroundWhite,
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
    return '${dt.month}/${dt.day}';
  }
}

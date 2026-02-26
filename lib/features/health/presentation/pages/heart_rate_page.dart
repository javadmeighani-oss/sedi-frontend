import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../core/widgets/app_states/app_empty_state.dart';
import '../../../../core/widgets/app_states/app_error_state.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../data/models/heart_rate_event.dart';
import '../../logic/heart_rate_thresholds.dart';
import '../../../../services/health/heart_rate_service.dart';
import '../../../auth_otp/presentation/pages/otp_login_page.dart';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  final HeartRateService _service = HeartRateService();
  List<HeartRateEvent> _events = const [];
  bool _loading = true;
  String? _error;
  String _lang = 'en';
  bool _usingFallback = false;

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

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final res = await _service.listHeartRate(userId: userId, limit: 50);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _events = res.data ?? const [];
      _error = res.ok ? null : res.errorMessage;
      _usingFallback = res.error?.code == 'NO_HEART_RATE_ENDPOINT';
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
        title: const Text('Heart Rate'),
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
          AppLoadingState(label: 'Loading heart rate...'),
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
    if (_events.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const AppEmptyState(
            title: 'No heart rate data yet',
            subtitle: 'Connect a device or wait for incoming readings.',
          ),
          if (_usingFallback)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'TODO: Waiting for dedicated heart-rate listing endpoint; currently using alert notifications proxy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
        ],
      );
    }

    final current = _events.first;
    final band = resolveHeartRateBand(current.bpm);
    final bandLabel = switch (band) {
      HeartRateBand.low => 'Low',
      HeartRateBand.high => 'High',
      HeartRateBand.normal => 'Normal',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border:
                Border.all(color: AppTheme.borderInactive.withOpacity(0.35)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${current.bpm}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const Text(
                'BPM',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: $bandLabel',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recent',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._events.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(HeartRateEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderInactive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            '${e.bpm} bpm',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatTime(e.recordedAt),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textDirection: TextDirection.ltr,
          ),
          if ((e.quality ?? '').isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              e.quality!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

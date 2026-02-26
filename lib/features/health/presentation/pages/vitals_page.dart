/// Vitals screen: view-only. Last known vitals (from cache) + trend. Updates via chat only.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../logic/vitals_cache.dart';
import '../../logic/vitals_controller.dart';
import 'health_alerts_page.dart';
import 'heart_rate_page.dart';
import '../widgets/vital_value_tile.dart';

class VitalsPage extends StatefulWidget {
  const VitalsPage({super.key});

  @override
  State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  final VitalsController _controller = VitalsController();
  bool _loadingCache = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadData();
  }

  Future<void> _loadLanguage() async {
    final lang = await UserPreferences.getUserLanguage();
    if (mounted) setState(() => _language = lang);
  }

  /// Load cache first, then try server; update controller.lastVitals and lastSource. No error on failure.
  Future<void> _loadData() async {
    setState(() => _loadingCache = true);
    await _controller.load();
    if (mounted) setState(() => _loadingCache = false);
  }

  bool get _isRtl => _language == 'fa' || _language == 'ar';

  @override
  Widget build(BuildContext context) {
    Widget body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HeartRatePage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderInactive),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Heart Rate',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HealthAlertsPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: AppTheme.backgroundWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text('Health Alerts'),
                ),
              ),
            ],
          ),
        ),
        // View-only note
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Vital data updates are created through chat. Please use Sedi conversation to modify your vitals.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        // Last recorded section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                'Last recorded',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _controller.lastSource == kSourceServer
                    ? 'Source: Server'
                    : 'Source: Local',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        if (_loadingCache)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.pistachioGreen)),
          )
        else if (_controller.lastVitals == null ||
            (_controller.lastVitals!.heartRate == null &&
                _controller.lastVitals!.spo2 == null &&
                _controller.lastVitals!.temperature == null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'No vitals recorded yet.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          )
        else ...[
          if (_controller.lastVitals!.heartRate != null)
            VitalValueTile(
                label: 'Heart rate',
                value: _controller.lastVitals!.heartRate!.round().toString(),
                unit: 'bpm'),
          if (_controller.lastVitals!.spo2 != null)
            VitalValueTile(
                label: 'SpO2',
                value: _controller.lastVitals!.spo2!.round().toString(),
                unit: '%'),
          if (_controller.lastVitals!.temperature != null)
            VitalValueTile(
                label: 'Temperature',
                value: _controller.lastVitals!.temperature!.toStringAsFixed(1),
                unit: '°C'),
          if (_controller.lastVitals!.createdAt != null)
            VitalValueTile(
              label: 'Recorded',
              value: _formatDate(_controller.lastVitals!.createdAt!),
            ),
        ],
        // Trend section (7-day mini trend)
        _buildTrendSection(),
      ],
    );

    Widget page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Vitals'),
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

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTrendSection() {
    const padding = EdgeInsets.fromLTRB(16, 16, 16, 4);
    final history = _controller.recentHistory;
    final avgHr = _controller.avgHeartRate7d;
    final count = _controller.countRecords7d;
    final hasData = count > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(
            'Trend',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            border: Border(
                bottom: BorderSide(
                    color: AppTheme.borderInactive.withOpacity(0.5),
                    width: 0.5)),
          ),
          child: Row(
            children: [
              Text(
                '7-day average HR',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const Spacer(),
              Text(
                hasData && avgHr != null ? '$avgHr bpm' : '—',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: history.take(5).map((CachedVitals e) {
                final time =
                    e.createdAt != null ? _formatDate(e.createdAt!) : '—';
                final hr =
                    e.heartRate != null ? '${e.heartRate!.round()} bpm' : '—';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.borderInactive.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          textDirection: TextDirection.ltr),
                      const SizedBox(width: 6),
                      Text(hr,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          textDirection: TextDirection.ltr),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

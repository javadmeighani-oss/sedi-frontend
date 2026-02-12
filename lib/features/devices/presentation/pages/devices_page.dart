/// Devices screen: MVP ECG-only. Shows Sedi-connected ECG device or "Not connected" + Coming soon.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../data/dto/device_public_info.dart';
import '../../logic/devices_controller.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final DevicesController _controller = DevicesController();
  bool _loading = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _load();
  }

  Future<void> _loadLanguage() async {
    final lang = await UserPreferences.getUserLanguage();
    if (mounted) setState(() => _language = lang);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _controller.loadDevices();
    if (mounted) setState(() => _loading = false);
  }

  bool get _isRtl => _language == 'fa' || _language == 'ar';

  static final _ecgTypes = {'ecg', 'heart_rate', 'heart-rate', 'hr'};
  static final _connectedStatuses = {'active', 'connected', 'online'};

  /// MVP: consider ECG-type device as first device with normalized type in [ecg, heart_rate, heart-rate, hr].
  /// Normalization: assumes deviceType/status are non-nullable from DTO; if ever nullable, use (value ?? '').toLowerCase().trim().
  DevicePublicInfo? get _ecgDevice {
    for (final d in _controller.devices) {
      final t = d.deviceType.toLowerCase().trim();
      if (_ecgTypes.contains(t)) return d;
    }
    return null;
  }

  bool get _ecgConnected {
    final d = _ecgDevice;
    if (d == null) return false;
    final s = d.status.toLowerCase().trim();
    return _connectedStatuses.contains(s);
  }

  String _lastSeenLabel(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Never';
    final n = DateTime.now();
    final d = lastSeenAt;
    if (d.year == n.year && d.month == n.month && d.day == n.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget body = RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.pistachioGreen,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Section: Connected devices
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Connected devices',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.pistachioGreen)),
            )
          else
            _buildEcgCard(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'When connected, ECG readings will appear in Vitals.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    Widget page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Devices'),
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

  Widget _buildEcgCard() {
    final connected = _ecgConnected;
    final d = _ecgDevice;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ECG Device',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chest device',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: connected
                        ? AppTheme.pistachioGreen.withOpacity(0.2)
                        : AppTheme.borderInactive.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    connected ? 'Connected' : 'Not connected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: connected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (connected && d != null && d.lastSeenAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Last updated: ${_lastSeenLabel(d.lastSeenAt)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                textDirection: TextDirection.ltr,
              ),
            )
          else if (!connected) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Coming soon',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.6,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.pistachioGreen,
                      foregroundColor: AppTheme.backgroundWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

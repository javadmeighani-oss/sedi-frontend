/// Devices screen: list + register + revoke/rotate. Apple-like; RTL support.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/brand_name.dart';
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
  final _deviceIdController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  bool _loading = true;
  String _language = 'en';
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _load();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceTypeController.dispose();
    super.dispose();
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

  Future<void> _register() async {
    final id = _deviceIdController.text.trim();
    if (id.isEmpty) {
      _showSnackBar('Device ID is required', isError: true);
      return;
    }
    setState(() {
      _registering = true;
      _controller.errorMessage = null;
    });
    final ok = await _controller.registerDevice(id, _deviceTypeController.text.trim().isEmpty ? null : _deviceTypeController.text.trim());
    if (!mounted) return;
    setState(() => _registering = false);
    if (ok) {
      _showSnackBar('Device registered');
      _deviceIdController.clear();
      _deviceTypeController.clear();
    } else {
      _showSnackBar(_controller.errorMessage ?? 'Failed to register', isError: true);
    }
  }

  void _onDeviceLongPress(DevicePublicInfo d) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.textSecondary),
              title: const Text('Revoke'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRevoke(d.deviceId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              title: const Text('Rotate token'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRotate(d.deviceId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.textSecondary),
              title: const Text('Copy device ID'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: d.deviceId));
                _showSnackBar('Device ID copied');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRevoke(String deviceId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke device'),
        content: const Text('Revoke this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {});
    final success = await _controller.revokeDevice(deviceId);
    if (!mounted) return;
    setState(() {});
    if (success) {
      _showSnackBar('Device revoked');
    } else {
      _showSnackBar(_controller.errorMessage ?? 'Failed to revoke', isError: true);
    }
  }

  Future<void> _confirmRotate(String deviceId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rotate token'),
        content: const Text('Rotate device token?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {});
    final success = await _controller.rotateDeviceToken(deviceId);
    if (!mounted) return;
    setState(() {});
    if (success) {
      _showSnackBar('Token rotated');
    } else {
      _showSnackBar(_controller.errorMessage ?? 'Failed to rotate token', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.pistachioGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.pistachioGreen,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Register form
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Register device',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                labelText: 'Device ID (required)',
                hintText: 'e.g. ${sediBrandName('en')}001',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.borderInactive),
                ),
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _deviceTypeController,
              decoration: InputDecoration(
                labelText: 'Device type (optional)',
                hintText: 'e.g. heart_rate',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.borderInactive),
                ),
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: FilledButton(
              onPressed: (_registering || _controller.isActionInProgress) ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.pistachioGreen,
                foregroundColor: AppTheme.backgroundWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
              child: _registering
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundWhite),
                    )
                  : const Text('Register'),
            ),
          ),
          // Error banner
          if (_controller.errorMessage != null && _controller.errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _controller.errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                ),
              ),
            ),
          // Devices list header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Devices',
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
          else if (_controller.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'No devices registered yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            )
          else
            ..._controller.devices.map((d) => _buildDeviceCard(d)),
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

  Widget _buildDeviceCard(DevicePublicInfo d) {
    final deviceId = d.deviceId;
    final deviceType = d.deviceType;
    final status = deviceStatusLabel(d.status);
    final lastSeen = deviceLastSeenLabel(d.lastSeenAt);

    return GestureDetector(
      onLongPress: () => _onDeviceLongPress(d),
      child: Container(
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
                    child: SelectableText(
                      deviceId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Icon(Icons.more_vert, size: 20, color: AppTheme.iconInactive),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    deviceType,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    status,
                    style: TextStyle(
                      color: status == 'Revoked' ? Colors.red.shade700 : AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Last seen: $lastSeen',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

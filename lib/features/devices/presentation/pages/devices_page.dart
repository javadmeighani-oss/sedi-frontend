/// Gadgets screen: backend Device classification SELF / OTHER / Unclassified.
/// BLE transport state is separate from platform status=active (never mapped).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/dto/device_public_info.dart';
import '../../../../data/repositories/devices_repository.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_hologram_header.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../ble/sedi_ble_models.dart';
import '../../ble/sedi_ble_permissions.dart';
import '../../ble/sedi_ble_transport.dart';
import '../../logic/devices_controller.dart';
import '../../logic/gadgets_connect_controller.dart';
import '../devices_l10n.dart';

class DevicesPage extends StatefulWidget {
  final DevicesController? controller;
  final GadgetsConnectController? connectController;

  const DevicesPage({
    super.key,
    this.controller,
    this.connectController,
  });

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late final DevicesController _controller;
  GadgetsConnectController? _connect;
  bool _loading = true;
  bool _connecting = false;

  DevicesL10n get _l10n =>
      DevicesL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DevicesController();
    _connect = widget.connectController;
    SediLocaleController.instance.addListener(_onLocale);
    _load();
  }

  @override
  void dispose() {
    SediLocaleController.instance.removeListener(_onLocale);
    if (widget.connectController == null) {
      _connect?.dispose();
    }
    super.dispose();
  }

  void _onLocale() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _controller.loadDevices();
    if (mounted) setState(() => _loading = false);
  }

  GadgetsConnectController _ensureConnect() {
    return _connect ??= GadgetsConnectController(
      repository: DevicesRepository(),
      transport: ReactiveSediBleTransport(),
      requestBlePermissions: SediBlePermissions.request,
    );
  }

  Color _transportColor(SediBleTransportState? state) {
    switch (state) {
      case SediBleTransportState.connected:
        return AppTheme.gate2ButtonOlive;
      case SediBleTransportState.connecting:
      case SediBleTransportState.reconnecting:
        return AppTheme.statusNeutralMuted;
      case SediBleTransportState.outOfRange:
        return AppTheme.statusChangeAmber;
      case SediBleTransportState.disconnected:
      case null:
        return AppTheme.metalGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final groups = <_DeviceGroup>[
      _DeviceGroup(title: l10n.myGadgets, devices: _controller.selfDevices),
      _DeviceGroup(title: l10n.otherGadgets, devices: _controller.otherDevices),
      if (_controller.unclassifiedDevices.isNotEmpty)
        _DeviceGroup(
          title: l10n.unclassified,
          devices: _controller.unclassifiedDevices,
        ),
    ];

    Widget body = RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.gate2ButtonOlive,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const A3HologramHeader(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.gate2ButtonOlive),
              ),
            )
          else if (_controller.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: A3DestinationCard(
                child: Text(
                  l10n.noGadgets,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  g.title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (g.devices.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: A3DestinationCard(
                    child: Text(
                      l10n.noGadgets,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                for (final d in g.devices) ...[
                  _deviceCard(d, l10n),
                  const SizedBox(height: 12),
                ],
            ],
          if (_controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: A3DestinationCard(
                child: Text(
                  _controller.errorMessage!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 8),
          A3DestinationCard(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _connecting ? 0.72 : 1,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _connecting ? null : () => _onConnectPressed(l10n),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.ctaFill,
                    disabledBackgroundColor: AppTheme.gate2ButtonDisabled,
                    foregroundColor: AppTheme.ctaText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: Text(_connecting ? l10n.scanning : l10n.connect),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget page = Scaffold(
      backgroundColor: A3DestinationSurface.canvas,
      appBar: A3PageAppBar(
        title: Text(l10n.title),
        backgroundColor: A3DestinationSurface.canvas,
      ),
      body: body,
    );

    if (SediLocaleController.instance.isRtl) {
      page = Directionality(
        textDirection: TextDirection.rtl,
        child: page,
      );
    }
    return page;
  }

  Widget _deviceCard(DevicePublicInfo d, DevicesL10n l10n) {
    final ble = _connect?.transportFor(d.deviceId);
    final bleLabel = ble == null ? null : l10n.transportLabel(ble.name);
    final status = _connect?.lastDeviceStatus;
    final isBleConnected = ble == SediBleTransportState.connected &&
        _connect?.connectedDeviceId == d.deviceId;

    // Transport shown once (colored); no fake health/clinical fields.
    return A3DestinationCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.displayName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (bleLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              bleLabel,
              style: TextStyle(
                color: _transportColor(ble),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            d.deviceType,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statusLabel(d.status),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.formatLastSync(d.lastSeenAt),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          if (isBleConnected && status?.batteryPercent != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.batteryLabel(status!.batteryPercent!),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          if (isBleConnected && status?.contactOk != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.contactLabel(status!.contactOk!),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _controller.isActionInProgress
                    ? null
                    : () => _openPresentationEditor(d, l10n),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.gate2ButtonOlive,
                ),
                child: Text(l10n.rename),
              ),
              if (isBleConnected)
                TextButton(
                  onPressed: _connecting
                      ? null
                      : () async {
                          setState(() => _connecting = true);
                          await _connect?.manualDisconnect(d.deviceId);
                          if (mounted) setState(() => _connecting = false);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                  child: Text(l10n.disconnect),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onConnectPressed(DevicesL10n l10n) async {
    setState(() => _connecting = true);
    final connect = _ensureConnect();
    try {
      final found = await connect.scan();
      if (!mounted) return;
      if (found.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.permissionMessage(connect.lastError))),
        );
        return;
      }
      final selected = await showDialog<SediBleDiscoveredDevice>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l10n.selectDevice),
          children: [
            for (final d in found)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, d),
                child: Text(d.name ?? d.remoteId),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;

      final info = await connect.connectAndReadInfo(selected.remoteId);
      if (info == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(connect.lastError ?? 'connect failed')),
        );
        return;
      }

      final proof = await connect.obtainPossessionProof();
      if (proof == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(connect.lastError ?? 'proof failed')),
        );
        return;
      }

      final setupCtrl = TextEditingController();
      var category = 'SELF';
      final labelCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            backgroundColor: AppTheme.gate2CardWhite,
            title: Text(
              info.deviceId,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: setupCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: l10n.setupCodeHint,
                    filled: true,
                    fillColor: AppTheme.gate2InputFill,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'SELF', label: Text(l10n.selfCategory)),
                    ButtonSegment(
                        value: 'OTHER', label: Text(l10n.otherCategory)),
                  ],
                  selected: {category},
                  onSelectionChanged: (s) =>
                      setLocal(() => category = s.first),
                ),
                if (category == 'OTHER') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      hintText: l10n.labelHint,
                      filled: true,
                      fillColor: AppTheme.gate2InputFill,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.ctaFill,
                  foregroundColor: AppTheme.ctaText,
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) {
        setupCtrl.dispose();
        labelCtrl.dispose();
        return;
      }

      final claimed = await connect.claimDevice(
        deviceId: info.deviceId,
        possessionProof: proof,
        setupCode: setupCtrl.text,
        deviceCategory: category,
        userLabel: labelCtrl.text,
      );
      setupCtrl.dispose();
      labelCtrl.dispose();
      if (!claimed || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(connect.lastError ?? 'claim failed')),
        );
        return;
      }

      final paired =
          await connect.pairGatewayAndStoreCredential(info.deviceId);
      if (!paired || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(connect.lastError ?? 'gateway failed')),
        );
        return;
      }

      await connect.startDataSubscription(info.deviceId);
      await _load();
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _openPresentationEditor(
    DevicePublicInfo device,
    DevicesL10n l10n,
  ) async {
    var category = device.isOtherDevice
        ? 'OTHER'
        : (device.isSelfDevice ? 'SELF' : 'SELF');
    final labelCtrl = TextEditingController(text: device.userLabel ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: AppTheme.gate2CardWhite,
              title: Text(l10n.rename),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.category,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'SELF',
                        label: Text(l10n.selfCategory),
                      ),
                      ButtonSegment(
                        value: 'OTHER',
                        label: Text(l10n.otherCategory),
                      ),
                    ],
                    selected: {category},
                    onSelectionChanged: (s) {
                      setLocal(() => category = s.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelCtrl,
                    maxLength: 80,
                    decoration: InputDecoration(
                      hintText: l10n.labelHint,
                      filled: true,
                      fillColor: AppTheme.gate2InputFill,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.ctaFill,
                    foregroundColor: AppTheme.ctaText,
                  ),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      labelCtrl.dispose();
      return;
    }

    final ok = await _controller.updateDevicePresentation(
      deviceId: device.deviceId,
      deviceCategory: category,
      userLabel: labelCtrl.text,
    );
    labelCtrl.dispose();
    if (!mounted) return;
    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.presentationUpdated)));
    } else if (_controller.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));
    }
  }
}

class _DeviceGroup {
  final String title;
  final List<DevicePublicInfo> devices;

  const _DeviceGroup({
    required this.title,
    required this.devices,
  });
}

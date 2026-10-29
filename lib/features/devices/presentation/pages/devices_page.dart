/// Gadgets screen: backend Device classification SELF / OTHER / Unclassified.
/// BLE transport state is separate from platform status=active (never mapped).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../data/dto/device_public_info.dart';
import '../../../../data/repositories/devices_repository.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
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
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          16,
          28,
        ),
        children: [
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
              child: _specialCard(l10n),
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
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _connecting ? 0.72 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(27),
              onTap: _connecting ? null : () => _onConnectPressed(l10n),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: SediGlass.pistachioSphere().copyWith(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: AppTheme.ctaText),
                    const SizedBox(width: 8),
                    Text(
                      _connecting ? l10n.scanning : l10n.connect,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ctaText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget page = Scaffold(
      backgroundColor: A3DestinationSurface.canvas,
      extendBodyBehindAppBar: true,
      appBar: A3PageAppBar(
        // R-035: the small Sedi sphere sits on the START side of the title (right in fa/ar, left in en).
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SediHologramOrb(
              state: Gate3InteractionState.idle,
              diameter: 38,
              showRings: false,
              animate: false,
              keyedLogo: false,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: SediGlass.inkDeep,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SediSceneBackdrop(),
          body,
        ],
      ),
    );

    if (SediLocaleController.instance.isRtl) {
      page = Directionality(
        textDirection: TextDirection.rtl,
        child: page,
      );
    }
    return page;
  }

  /// Sedi's own specialised gadgets: only the heart-rate gadget is in development (Javad 2026-10-29).
  Widget _specialCard(DevicesL10n l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: SediGlass.card(BorderRadius.circular(28), strong: true),
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(painter: _WatchPainter()),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.specialTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: SediGlass.inkDeep,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.specialBody,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 14,
              height: 1.75,
              fontWeight: FontWeight.w600,
              color: SediGlass.ink,
            ),
          ),
        ],
      ),
    );
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

/// A small vector smart-watch with a pulse line (the heart-rate gadget).
class _WatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(c, r * 0.96, Paint()..color = Colors.white.withOpacity(0.72));
    canvas.drawCircle(
      c,
      r * 0.96,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = const Color(0xFFCFE27C),
    );
    final strap = Paint()..color = const Color(0xFFB9C28E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, -r * 0.62), width: r * 0.58, height: r * 0.3), Radius.circular(r * 0.1)),
      strap,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, r * 0.62), width: r * 0.58, height: r * 0.3), Radius.circular(r * 0.1)),
      strap,
    );
    final face = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 0.8, height: r * 0.9), Radius.circular(r * 0.24));
    canvas.drawRRect(face, Paint()..color = const Color(0xFFF4F7E6));
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = const Color(0xFF7F9E32),
    );
    final pulse = Path()
      ..moveTo(c.dx - r * 0.28, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.12, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.04, c.dy - r * 0.2)
      ..lineTo(c.dx + r * 0.06, c.dy + r * 0.24)
      ..lineTo(c.dx + r * 0.14, c.dy + r * 0.02)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.02);
    canvas.drawPath(
      pulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF48551F),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

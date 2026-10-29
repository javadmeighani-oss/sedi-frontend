import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/core/theme/app_theme.dart';
import 'package:sedi_app/data/dto/device_public_info.dart';
import 'package:sedi_app/data/dto/devices_list_response.dart';
import 'package:sedi_app/data/repositories/devices_repository.dart';
import 'package:sedi_app/features/devices/ble/sedi_ble_models.dart';
import 'package:sedi_app/features/devices/ble/sedi_ble_permissions.dart';
import 'package:sedi_app/features/devices/ble/sedi_ble_transport.dart';
import 'package:sedi_app/features/devices/gateway/device_credential_store.dart';
import 'package:sedi_app/features/devices/gateway/gateway_install_id_store.dart';
import 'package:sedi_app/features/devices/logic/devices_controller.dart';
import 'package:sedi_app/features/devices/logic/gadgets_connect_controller.dart';
import 'package:sedi_app/features/devices/presentation/devices_l10n.dart';
import 'package:sedi_app/features/devices/presentation/pages/devices_page.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _read(String relativePath) => File(relativePath).readAsStringSync();

class _FakeDevicesRepository extends DevicesRepository {
  _FakeDevicesRepository() : super(baseUrl: 'http://fake');

  @override
  Future<ApiResponse<DevicesListData?>> list() async {
    final now = DateTime.utc(2026, 1, 1, 12);
    final devices = [
      DevicePublicInfo(
        deviceId: 'SEDI-ECG-000000000001',
        deviceType: 'heart_rate',
        status: 'active',
        createdAt: now,
        lastSeenAt: now.subtract(const Duration(minutes: 5)),
        deviceCategory: 'SELF',
      ),
      DevicePublicInfo(
        deviceId: 'SEDI-ECG-000000000002',
        deviceType: 'heart_rate',
        status: 'active',
        createdAt: now,
        deviceCategory: 'OTHER',
        userLabel: 'Mom BP',
      ),
    ];
    return ApiResponse(
      ok: true,
      data: DevicesListData(devices: devices, count: devices.length),
    );
  }
}

class _FakeGatewayStore extends GatewayInstallIdStore {
  String? _id;
  @override
  Future<String> getOrCreate() async {
    _id ??= GatewayInstallIdStore.generateHighEntropyInstallId();
    return _id!;
  }

  @override
  Future<String?> peek() async => _id;
}

class _FakeCredStore extends DeviceCredentialStore {
  final map = <String, String>{};
  @override
  Future<void> saveToken({required String deviceId, required String token}) async {
    map[deviceId] = token;
  }

  @override
  Future<String?> readToken(String deviceId) async => map[deviceId];
}

class _FakeBle implements SediBleTransport {
  @override
  Stream<SediBleTransportState> get transportState => const Stream.empty();

  @override
  Stream<SediBleDiscoveredDevice> scanForSediGadgets() async* {
    yield const SediBleDiscoveredDevice(remoteId: 'aa:bb', name: 'SEDI');
  }

  @override
  Future<void> connect(String remoteId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<SediBleDeviceInfo> readDeviceInfo() async => const SediBleDeviceInfo(
        protocol: 1,
        deviceId: 'SEDI-HR-000000000099',
        deviceType: 'heart_rate',
      );

  @override
  Stream<SediBleDeviceData> subscribeDeviceData() => const Stream.empty();

  @override
  Stream<SediBleDeviceStatus> subscribeDeviceStatus() => const Stream.empty();

  @override
  Future<SediBleDeviceStatus?> readDeviceStatus() async => null;

  @override
  Future<void> writeClaimChallenge(List<int> challengeNonce) async {}

  @override
  Future<List<int>> readClaimProof() async => const [1, 2, 3, 4];

  @override
  void dispose() {}
}

class _ScanRepo extends DevicesRepository {
  _ScanRepo() : super(baseUrl: 'http://fake');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SediLocaleController.instance.debugResetForTest();
  });

  test('G9 A3 visual contract: single AppTheme + pale olive + olive CTA', () {
    final page = _read('lib/features/devices/presentation/pages/devices_page.dart');
    final theme = _read('lib/core/theme/app_theme.dart');
    final native = _read(
      'android/app/src/main/kotlin/com/sedi/app/MainActivity.kt',
    );
    expect(theme.contains('gate3PaleOliveBackground'), isTrue);
    expect(page.contains('A3DestinationSurface.canvas'), isTrue);
    expect(page.contains('AppTheme.gate3PaleOliveBackground'), isFalse);
    expect(page.contains('A3PageAppBar('), isTrue);
    expect(page.contains('AppTheme.gate2ButtonOlive'), isTrue);
    expect(page.contains('A3DestinationCard'), isTrue);
    expect(page.contains('AppTheme.gate2CardWhite'), isTrue);
    expect(page.contains('health score'), isFalse);
    expect(page.contains('dangerRed'), isFalse);
    expect(page.contains('toIso8601String'), isFalse);
    expect(page.contains('SediBlePermissions.request'), isTrue);
    expect(page.contains('() async => true'), isFalse);

    final ctrl = _read(
      'lib/features/devices/logic/gadgets_connect_controller.dart',
    );
    expect(ctrl.contains('() async => true'), isFalse);
    expect(ctrl.contains('SediBlePermissions.request'), isTrue);

    expect(native.contains('sedi/ble_permissions'), isTrue);
    expect(native.contains('BLUETOOTH_SCAN'), isTrue);
    expect(native.contains('BLUETOOTH_CONNECT'), isTrue);
    expect(native.contains('ACCESS_FINE_LOCATION'), isTrue);
  });

  test('G9 transport colors are non-clinical (no danger red for disconnect)', () {
    final page = _read('lib/features/devices/presentation/pages/devices_page.dart');
    expect(page.contains('AppTheme.gate2ButtonOlive'), isTrue);
    expect(page.contains('AppTheme.statusNeutralMuted'), isTrue);
    expect(page.contains('AppTheme.statusChangeAmber'), isTrue);
    expect(page.contains('AppTheme.metalGrey'), isTrue);
    expect(page.contains('AppTheme.dangerRed'), isFalse);
    expect(page.contains('Colors.red'), isFalse);
  });

  test('G9 human-readable last sync + contact; en/fa/ar', () {
    final now = DateTime.utc(2026, 9, 12, 12, 0);
    final en = DevicesL10n('en');
    final fa = DevicesL10n('fa');
    final ar = DevicesL10n('ar');
    expect(en.formatLastSync(null), contains('Last sync'));
    expect(
      en.formatLastSync(now.subtract(const Duration(minutes: 3)), now: now),
      contains('3m ago'),
    );
    expect(
      en.formatLastSync(now.subtract(const Duration(minutes: 3)), now: now),
      isNot(contains('2026-09')),
    );
    expect(fa.formatLastSync(null), contains('همگام'));
    expect(ar.formatLastSync(null), contains('مزامنة'));
    expect(en.contactLabel(true), isNot(contains('true')));
    expect(en.contactLabel(false), isNot(contains('false')));
    expect(ar.isRtl, isTrue);
    expect(fa.isRtl, isTrue);
    expect(en.isRtl, isFalse);
  });

  test('G9 permission granted → scan proceeds; denied → empty', () async {
    final granted = GadgetsConnectController(
      repository: _ScanRepo(),
      transport: _FakeBle(),
      gatewayInstallIdStore: _FakeGatewayStore(),
      credentialStore: _FakeCredStore(),
      requestBlePermissions: () async => true,
    );
    final found =
        await granted.scan(timeout: const Duration(milliseconds: 40));
    expect(found, isNotEmpty);
    granted.dispose();

    final denied = GadgetsConnectController(
      repository: _ScanRepo(),
      transport: _FakeBle(),
      gatewayInstallIdStore: _FakeGatewayStore(),
      credentialStore: _FakeCredStore(),
      requestBlePermissions: () async => false,
    );
    final none = await denied.scan(timeout: const Duration(milliseconds: 40));
    expect(none, isEmpty);
    expect(denied.lastError, 'BLE_PERMISSION_DENIED');
    denied.dispose();
  });

  test('G9 SediBlePermissions: grant/deny/permanent via platform seam', () async {
    expect(
      await SediBlePermissions.requestDetailed(
        isAndroidOverride: true,
        invokePlatform: () async => 'granted',
      ),
      SediBlePermissionOutcome.granted,
    );

    expect(
      await SediBlePermissions.requestDetailed(
        isAndroidOverride: true,
        invokePlatform: () async => 'denied',
      ),
      SediBlePermissionOutcome.denied,
    );

    var opened = false;
    expect(
      await SediBlePermissions.requestDetailed(
        isAndroidOverride: true,
        invokePlatform: () async => 'permanentlyDenied',
        openSettings: () async {
          opened = true;
          return true;
        },
      ),
      SediBlePermissionOutcome.permanentlyDenied,
    );
    expect(opened, isTrue);
  });

  test('G9 permanently denied maps controller error code', () async {
    SediBlePermissions.lastOutcome =
        SediBlePermissionOutcome.permanentlyDenied;
    final c = GadgetsConnectController(
      repository: _ScanRepo(),
      transport: _FakeBle(),
      gatewayInstallIdStore: _FakeGatewayStore(),
      credentialStore: _FakeCredStore(),
      requestBlePermissions: () async => false,
    );
    final none = await c.scan(timeout: const Duration(milliseconds: 20));
    expect(none, isEmpty);
    expect(c.lastError, 'BLE_PERMISSION_PERMANENTLY_DENIED');
    c.dispose();
  });

  testWidgets('G9 DevicesPage white canvas + A3PageAppBar + Connect CTA',
      (tester) async {
    await SediLocaleController.instance.setRuntimeLocale(
      'en',
      persistBootstrapCache: false,
    );
    final controller = DevicesController(repo: _FakeDevicesRepository());
    await tester.pumpWidget(
      MaterialApp(home: DevicesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(A3PageAppBar), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, A3DestinationSurface.canvas);

    // pilot V1: the bar floats transparent over the soft pistachio scene (R-034)
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, Colors.transparent);

    expect(find.text('Connect'), findsOneWidget);
    expect(find.textContaining('Last sync'), findsWidgets);
    expect(find.textContaining('T12:'), findsNothing);
    expect(find.text('true'), findsNothing);
    expect(find.text('false'), findsNothing);
  });

  testWidgets('G9 FA/AR RTL + AR strings', (tester) async {
    await SediLocaleController.instance.setRuntimeLocale(
      'ar',
      persistBootstrapCache: false,
    );
    final controller = DevicesController(repo: _FakeDevicesRepository());
    await tester.pumpWidget(
      MaterialApp(home: DevicesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('الأجهزة'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );
  });

  testWidgets('G9 back pops prior A3 route', (tester) async {
    await SediLocaleController.instance.setRuntimeLocale(
      'en',
      persistBootstrapCache: false,
    );
    final controller = DevicesController(repo: _FakeDevicesRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DevicesPage(controller: controller),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(DevicesPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(DevicesPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}

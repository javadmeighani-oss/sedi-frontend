import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/data/dto/devices_list_response.dart';
import 'package:sedi_app/data/repositories/devices_repository.dart';
import 'package:sedi_app/features/devices/logic/devices_controller.dart';

/// Stub repository that records calls and returns success for revoke/rotate; list returns empty data.
class FakeDevicesRepository extends DevicesRepository {
  FakeDevicesRepository() : super(baseUrl: 'http://fake');

  int listCallCount = 0;
  bool revokeCalled = false;
  bool rotateTokenCalled = false;

  @override
  Future<ApiResponse<DevicesListData?>> list({required int userId}) async {
    listCallCount++;
    return ApiResponse(ok: true, data: const DevicesListData(devices: [], count: 0));
  }

  @override
  Future<ApiResponse<Map<String, dynamic>?>> revoke({
    required String deviceId,
    required int userId,
  }) async {
    revokeCalled = true;
    return const ApiResponse(ok: true, data: {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>?>> rotateToken({
    required String deviceId,
    required int userId,
  }) async {
    rotateTokenCalled = true;
    return const ApiResponse(ok: true, data: {});
  }
}

void main() {
  group('DevicesController revoke/rotate', () {
    test('revokeDevice calls repo.revoke then loadDevices on success', () async {
      final fake = FakeDevicesRepository();
      final controller = DevicesController(repo: fake, testUserId: 1);

      await controller.revokeDevice('device-1');

      expect(fake.revokeCalled, isTrue);
      expect(fake.listCallCount, greaterThanOrEqualTo(1));
    });

    test('rotateDeviceToken calls repo.rotateToken then loadDevices on success', () async {
      final fake = FakeDevicesRepository();
      final controller = DevicesController(repo: fake, testUserId: 1);

      await controller.rotateDeviceToken('device-2');

      expect(fake.rotateTokenCalled, isTrue);
      expect(fake.listCallCount, greaterThanOrEqualTo(1));
    });
  });
}

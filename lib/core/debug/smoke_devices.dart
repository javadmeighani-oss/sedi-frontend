/// Debug helper: register device + list devices.
/// Guarded — call explicitly; not executed automatically.
import '../../data/dto/device_register_request.dart';
import '../../data/repositories/devices_repository.dart';
import '../utils/user_profile_manager.dart';

/// Registers a sample device and then lists devices for the current user (from UserProfileManager).
/// Use only in debug builds or when explicitly triggered.
/// Returns result summary string for logging.
Future<String> smokeDevices() async {
  final profile = await UserProfileManager.loadProfile();
  final userId = profile.userId;
  if (userId == null) {
    return '[smoke_devices] No user_id in profile; skip';
  }
  final repo = DevicesRepository();
  final req = DeviceRegisterRequest(deviceId: 'SediDebug001', deviceType: 'heart_rate');
  final registerResp = await repo.register(userId: userId, request: req);
  if (!registerResp.ok) {
    return '[smoke_devices] register FAIL ${registerResp.error?.message ?? "unknown"}';
  }
  final listResp = await repo.list(userId: userId);
  if (!listResp.ok || listResp.data == null) {
    return '[smoke_devices] register OK; list FAIL ${listResp.error?.message ?? "no data"}';
  }
  return '[smoke_devices] OK registered; list count=${listResp.data!.count}';
}

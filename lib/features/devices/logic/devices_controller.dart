/// Devices list and register logic. Uses DevicesRepository; single responsibility.
import '../../../core/utils/user_profile_manager.dart';
import '../../../data/dto/device_public_info.dart';
import '../../../data/dto/device_register_request.dart';
import '../../../data/repositories/devices_repository.dart';

class DevicesController {
  final DevicesRepository _repo;
  final int? _testUserId;

  DevicesController({DevicesRepository? repo, int? testUserId})
      : _repo = repo ?? DevicesRepository(),
        _testUserId = testUserId;

  bool isLoading = false;
  bool isActionInProgress = false;
  List<DevicePublicInfo> devices = [];
  String? errorMessage;

  Future<int?> _getUserId() async {
    if (_testUserId != null) return _testUserId;
    final profile = await UserProfileManager.loadProfile();
    return profile.userId;
  }

  /// Load devices for current user. Clears error on success.
  Future<void> loadDevices() async {
    final userId = await _getUserId();
    if (userId == null) {
      devices = [];
      errorMessage = 'User not found';
      return;
    }
    isLoading = true;
    errorMessage = null;
    try {
      final response = await _repo.list(userId: userId);
      if (response.ok && response.data != null) {
        devices = response.data!.devices;
        errorMessage = null;
      } else {
        errorMessage = response.errorMessage;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  /// Register a device. On success reloads list; on failure sets errorMessage.
  Future<bool> registerDevice(String deviceId, [String? deviceType]) async {
    if (isActionInProgress) {
      errorMessage = 'Please wait.';
      return false;
    }
    final trimmed = deviceId.trim();
    if (trimmed.isEmpty) {
      errorMessage = 'Device ID is required';
      return false;
    }
    final userId = await _getUserId();
    if (userId == null) {
      errorMessage = 'User not found';
      return false;
    }
    isActionInProgress = true;
    errorMessage = null;
    try {
      final request = DeviceRegisterRequest(deviceId: trimmed, deviceType: deviceType?.trim().isEmpty == true ? null : deviceType?.trim());
      final response = await _repo.register(userId: userId, request: request);
      if (!response.ok) {
        errorMessage = response.errorMessage;
        return false;
      }
      await loadDevices();
      return true;
    } finally {
      isActionInProgress = false;
    }
  }

  /// Revoke a device. On success reloads list.
  Future<bool> revokeDevice(String deviceId) async {
    if (isActionInProgress) {
      errorMessage = 'Please wait.';
      return false;
    }
    final userId = await _getUserId();
    if (userId == null) {
      errorMessage = 'User not found';
      return false;
    }
    isActionInProgress = true;
    errorMessage = null;
    try {
      final response = await _repo.revoke(deviceId: deviceId, userId: userId);
      if (!response.ok) {
        errorMessage = response.errorMessage;
        return false;
      }
      await loadDevices();
      return true;
    } finally {
      isActionInProgress = false;
    }
  }

  /// Rotate device token. On success reloads list.
  Future<bool> rotateDeviceToken(String deviceId) async {
    if (isActionInProgress) {
      errorMessage = 'Please wait.';
      return false;
    }
    final userId = await _getUserId();
    if (userId == null) {
      errorMessage = 'User not found';
      return false;
    }
    isActionInProgress = true;
    errorMessage = null;
    try {
      final response = await _repo.rotateToken(deviceId: deviceId, userId: userId);
      if (!response.ok) {
        errorMessage = response.errorMessage;
        return false;
      }
      await loadDevices();
      return true;
    } finally {
      isActionInProgress = false;
    }
  }
}

// --- UI-friendly mapping (for tests and UI) ---

/// Status label for device card: Active / Revoked.
String deviceStatusLabel(String status) {
  final s = (status).toLowerCase();
  if (s == 'revoked') return 'Revoked';
  return 'Active';
}

/// Last seen label: formatted date-time or "Never".
String deviceLastSeenLabel(DateTime? lastSeenAt) {
  if (lastSeenAt == null) return 'Never';
  final n = DateTime.now();
  final d = lastSeenAt;
  if (d.year == n.year && d.month == n.month && d.day == n.day) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Devices management: POST /devices/register, GET /devices, revoke, rotate-token.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../dto/device_register_request.dart';
import '../dto/devices_list_response.dart';

class DevicesRepository {
  final ApiClient _client;

  DevicesRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  Map<String, String> _userQuery(int userId) => {'user_id': userId.toString()};

  /// POST /devices/register — register device for user.
  /// Backend returns { ok, data: { device_id, token? }, error? }.
  Future<ApiResponse<Map<String, dynamic>?>> register({
    required int userId,
    required DeviceRegisterRequest request,
  }) async {
    return _client.post<Map<String, dynamic>?>(
      '/devices/register',
      queryParams: _userQuery(userId),
      body: request.toJson(),
      parser: (v) => v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  /// GET /devices — list devices for user.
  Future<ApiResponse<DevicesListData?>> list({required int userId}) async {
    return _client.get<DevicesListData?>(
      '/devices',
      queryParams: _userQuery(userId),
      parser: (v) {
        if (v == null) return null;
        final map = v is Map ? Map<String, dynamic>.from(v) : null;
        return map != null ? DevicesListData.fromJson(map) : null;
      },
    );
  }

  /// POST /devices/{device_id}/revoke — revoke device.
  Future<ApiResponse<Map<String, dynamic>?>> revoke({
    required String deviceId,
    required int userId,
  }) async {
    return _client.post<Map<String, dynamic>?>(
      '/devices/$deviceId/revoke',
      queryParams: _userQuery(userId),
      parser: (v) => v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  /// POST /devices/{device_id}/rotate-token — rotate device token.
  Future<ApiResponse<Map<String, dynamic>?>> rotateToken({
    required String deviceId,
    required int userId,
  }) async {
    return _client.post<Map<String, dynamic>?>(
      '/devices/$deviceId/rotate-token',
      queryParams: _userQuery(userId),
      parser: (v) => v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }
}

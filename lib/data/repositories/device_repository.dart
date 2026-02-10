/// Device ingest: POST /device/ingest (vitals from device).
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../dto/device_ingest_request.dart';
import '../dto/device_ingest_response.dart';

class DeviceRepository {
  final ApiClient _client;

  DeviceRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  /// POST /device/ingest — send device event (heart_rate, blood_pressure, glucose, temperature).
  /// Note: Production may require device token in header; this uses user ApiClient.
  Future<ApiResponse<DeviceIngestResponse?>> ingest(DeviceIngestRequest request) async {
    return _client.post<DeviceIngestResponse?>(
      '/device/ingest',
      body: request.toJson(),
      parser: (v) {
        if (v == null) return null;
        final map = v is Map ? Map<String, dynamic>.from(v) : null;
        return map != null ? DeviceIngestResponse.fromJson(map) : null;
      },
    );
  }
}

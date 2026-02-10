/// Request DTO for POST /device/ingest.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (DeviceIngestRequest)
class DeviceIngestRequest {
  final int userId;
  final String? deviceId;
  final String eventType; // "heart_rate" | "blood_pressure" | "glucose" | "temperature"
  final Map<String, dynamic> payload;
  final DateTime? recordedAt;

  const DeviceIngestRequest({
    required this.userId,
    this.deviceId,
    required this.eventType,
    required this.payload,
    this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (deviceId != null && deviceId!.isNotEmpty) 'device_id': deviceId,
      'event_type': eventType,
      'payload': payload,
      if (recordedAt != null) 'recorded_at': recordedAt!.toUtc().toIso8601String(),
    };
  }
}

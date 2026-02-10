/// Device list item: device_id, device_type, status, last_seen_at, created_at, revoked_at.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (DevicePublicInfo)
class DevicePublicInfo {
  final String deviceId;
  final String deviceType;
  final String status; // "active" | "revoked"
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime? revokedAt;

  const DevicePublicInfo({
    required this.deviceId,
    required this.deviceType,
    required this.status,
    this.lastSeenAt,
    required this.createdAt,
    this.revokedAt,
  });

  factory DevicePublicInfo.fromJson(Map<String, dynamic> json) {
    DateTime? lastSeenAt;
    if (json['last_seen_at'] != null) {
      if (json['last_seen_at'] is String) lastSeenAt = DateTime.tryParse(json['last_seen_at'] as String);
      else if (json['last_seen_at'] is DateTime) lastSeenAt = json['last_seen_at'] as DateTime;
    }
    DateTime? createdAt;
    if (json['created_at'] != null) {
      if (json['created_at'] is String) createdAt = DateTime.tryParse(json['created_at'] as String);
      else if (json['created_at'] is DateTime) createdAt = json['created_at'] as DateTime;
    }
    if (createdAt == null) createdAt = DateTime.now();
    DateTime? revokedAt;
    if (json['revoked_at'] != null) {
      if (json['revoked_at'] is String) revokedAt = DateTime.tryParse(json['revoked_at'] as String);
      else if (json['revoked_at'] is DateTime) revokedAt = json['revoked_at'] as DateTime;
    }
    return DevicePublicInfo(
      deviceId: json['device_id']?.toString() ?? '',
      deviceType: json['device_type']?.toString() ?? 'heart_rate',
      status: json['status']?.toString() ?? 'active',
      lastSeenAt: lastSeenAt,
      createdAt: createdAt,
      revokedAt: revokedAt,
    );
  }
}

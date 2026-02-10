/// Response DTO for POST /health/add (data payload).
/// Backend may return: id/user_id/heart_rate/temperature/spo2/created_at
/// or success payload: user_id, health_id, notification_id, message.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (HealthDataResponse)
class HealthDataResponse {
  final int? id;
  final int? userId;
  final double? heartRate;
  final double? temperature;
  final double? spo2;
  final DateTime? createdAt;
  // Success payload fields (current backend)
  final int? notificationId;
  final String? message;

  const HealthDataResponse({
    this.id,
    this.userId,
    this.heartRate,
    this.temperature,
    this.spo2,
    this.createdAt,
    this.notificationId,
    this.message,
  });

  factory HealthDataResponse.fromJson(Map<String, dynamic> json) {
    int? id;
    if (json['id'] != null) id = json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString());
    if (id == null && json['health_id'] != null) id = json['health_id'] is int ? json['health_id'] as int : int.tryParse(json['health_id'].toString());
    int? userId;
    if (json['user_id'] != null) userId = json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id'].toString());
    int? notificationId;
    if (json['notification_id'] != null) notificationId = json['notification_id'] is int ? json['notification_id'] as int : int.tryParse(json['notification_id'].toString());
    double? heartRate;
    if (json['heart_rate'] != null) heartRate = (json['heart_rate'] is num) ? (json['heart_rate'] as num).toDouble() : double.tryParse(json['heart_rate'].toString());
    double? temperature;
    if (json['temperature'] != null) temperature = (json['temperature'] is num) ? (json['temperature'] as num).toDouble() : double.tryParse(json['temperature'].toString());
    double? spo2;
    if (json['spo2'] != null) spo2 = (json['spo2'] is num) ? (json['spo2'] as num).toDouble() : double.tryParse(json['spo2'].toString());
    DateTime? createdAt;
    if (json['created_at'] != null) {
      if (json['created_at'] is String) createdAt = DateTime.tryParse(json['created_at'] as String);
      else if (json['created_at'] is DateTime) createdAt = json['created_at'] as DateTime;
    }
    return HealthDataResponse(
      id: id,
      userId: userId,
      heartRate: heartRate,
      temperature: temperature,
      spo2: spo2,
      createdAt: createdAt,
      notificationId: notificationId,
      message: json['message'] as String?,
    );
  }

  /// Parse backend APIResponse "data" which may be a single object or a list.
  /// If list: pick newest by created_at, else first. Returns null if data is null or invalid.
  static HealthDataResponse? fromApiData(Object? data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return HealthDataResponse.fromJson(data);
    if (data is Map) return HealthDataResponse.fromJson(Map<String, dynamic>.from(data));
    if (data is List) {
      final list = data;
      if (list.isEmpty) return null;
      final parsed = <HealthDataResponse>[];
      for (final e in list) {
        if (e is Map) {
          try {
            parsed.add(HealthDataResponse.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
      if (parsed.isEmpty) return null;
      parsed.sort((a, b) {
        final at = a.createdAt ?? DateTime(0);
        final bt = b.createdAt ?? DateTime(0);
        return bt.compareTo(at);
      });
      return parsed.first;
    }
    return null;
  }
}

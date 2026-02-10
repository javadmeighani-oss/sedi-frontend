/// Request DTO for POST /health/add.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (HealthDataCreate)
class HealthDataCreate {
  final int userId;
  final double? heartRate;
  final double? temperature;
  final double? spo2;

  const HealthDataCreate({
    required this.userId,
    this.heartRate,
    this.temperature,
    this.spo2,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (heartRate != null) 'heart_rate': heartRate,
      if (temperature != null) 'temperature': temperature,
      if (spo2 != null) 'spo2': spo2,
    };
  }
}

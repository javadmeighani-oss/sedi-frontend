/// Parsed data for GET /lifestyle/context. Flexible: data may be object or null.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
class LifestyleContextResponse {
  final double? sleepHours;
  final int? steps;
  final int? calories;
  final int? stressLevel;
  final Map<String, dynamic>? raw;

  const LifestyleContextResponse({
    this.sleepHours,
    this.steps,
    this.calories,
    this.stressLevel,
    this.raw,
  });

  /// Parse from a JSON map. Returns empty response for null or empty map.
  static LifestyleContextResponse fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const LifestyleContextResponse();
    }
    double? sleepHours;
    if (json['sleep_hours'] != null) {
      sleepHours = (json['sleep_hours'] is num)
          ? (json['sleep_hours'] as num).toDouble()
          : double.tryParse(json['sleep_hours'].toString());
    }
    int? steps;
    if (json['steps'] != null) {
      steps = json['steps'] is int ? json['steps'] as int : int.tryParse(json['steps'].toString());
    }
    int? calories;
    if (json['calories'] != null) {
      calories = json['calories'] is int ? json['calories'] as int : int.tryParse(json['calories'].toString());
    }
    int? stressLevel;
    if (json['stress_level'] != null) {
      stressLevel = json['stress_level'] is int ? json['stress_level'] as int : int.tryParse(json['stress_level'].toString());
    }
    return LifestyleContextResponse(
      sleepHours: sleepHours,
      steps: steps,
      calories: calories,
      stressLevel: stressLevel,
      raw: json,
    );
  }

  /// Parse backend APIResponse "data" which may be an object or null.
  static LifestyleContextResponse? fromApiData(Object? data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return fromJson(data);
    if (data is Map) return fromJson(Map<String, dynamic>.from(data));
    return null;
  }
}

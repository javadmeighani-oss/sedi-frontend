class LifestyleGetResponseDto {
  final double? sleepDurationHours;
  final String? sleepQuality;
  final double? hydrationMl;
  final String? activityLevel;
  final int? stepsCount;
  final int? exerciseMinutes;
  final String? mood;
  final String? stressLevel;

  const LifestyleGetResponseDto({
    this.sleepDurationHours,
    this.sleepQuality,
    this.hydrationMl,
    this.activityLevel,
    this.stepsCount,
    this.exerciseMinutes,
    this.mood,
    this.stressLevel,
  });

  factory LifestyleGetResponseDto.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return LifestyleGetResponseDto(
      sleepDurationHours: asDouble(json['sleep_duration_hours']),
      sleepQuality: json['sleep_quality']?.toString(),
      hydrationMl: asDouble(json['hydration_ml']),
      activityLevel: json['activity_level']?.toString(),
      stepsCount: asInt(json['steps_count']),
      exerciseMinutes: asInt(json['exercise_minutes']),
      mood: json['mood']?.toString(),
      stressLevel: json['stress_level']?.toString(),
    );
  }
}

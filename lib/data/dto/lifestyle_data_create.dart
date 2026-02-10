/// Request DTO for POST /lifestyle/update.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (LifestyleDataCreate)
class LifestyleDataCreate {
  final int userId;
  final double? sleepHours;
  final int? steps;
  final int? calories;
  final int? stressLevel;

  const LifestyleDataCreate({
    required this.userId,
    this.sleepHours,
    this.steps,
    this.calories,
    this.stressLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (steps != null) 'steps': steps,
      if (calories != null) 'calories': calories,
      if (stressLevel != null) 'stress_level': stressLevel,
    };
  }
}

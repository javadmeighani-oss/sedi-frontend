import '../dto/lifestyle/lifestyle_get_response_dto.dart';

class LifestyleState {
  final double? sleepDurationHours;
  final String? sleepQuality;
  final int? stepsCount;
  final int? exerciseMinutes;
  final String? activityLevel;
  final double? hydrationMl;
  final String? mood;
  final String? stressLevel;

  const LifestyleState({
    this.sleepDurationHours,
    this.sleepQuality,
    this.stepsCount,
    this.exerciseMinutes,
    this.activityLevel,
    this.hydrationMl,
    this.mood,
    this.stressLevel,
  });

  factory LifestyleState.fromDto(LifestyleGetResponseDto dto) {
    return LifestyleState(
      sleepDurationHours: dto.sleepDurationHours,
      sleepQuality: dto.sleepQuality,
      stepsCount: dto.stepsCount,
      exerciseMinutes: dto.exerciseMinutes,
      activityLevel: dto.activityLevel,
      hydrationMl: dto.hydrationMl,
      mood: dto.mood,
      stressLevel: dto.stressLevel,
    );
  }

  LifestyleState copyWith({
    double? sleepDurationHours,
    String? sleepQuality,
    int? stepsCount,
    int? exerciseMinutes,
    String? activityLevel,
    double? hydrationMl,
    String? mood,
    String? stressLevel,
  }) {
    return LifestyleState(
      sleepDurationHours: sleepDurationHours ?? this.sleepDurationHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stepsCount: stepsCount ?? this.stepsCount,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      activityLevel: activityLevel ?? this.activityLevel,
      hydrationMl: hydrationMl ?? this.hydrationMl,
      mood: mood ?? this.mood,
      stressLevel: stressLevel ?? this.stressLevel,
    );
  }

  bool get isEmpty =>
      sleepDurationHours == null &&
      sleepQuality == null &&
      stepsCount == null &&
      exerciseMinutes == null &&
      activityLevel == null &&
      hydrationMl == null &&
      mood == null &&
      stressLevel == null;
}

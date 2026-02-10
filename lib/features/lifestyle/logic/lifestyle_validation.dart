/// Pure validation and formatting for lifestyle form. Ranges: sleep 0–24, steps 0–100000, calories 0–20000, stress 0–10.

const double _sleepMin = 0, _sleepMax = 24;
const int _stepsMin = 0, _stepsMax = 100000;
const int _caloriesMin = 0, _caloriesMax = 20000;
const int _stressMin = 0, _stressMax = 10;

/// Returns null if valid, error message otherwise.
String? validateSleepHours(double? value) {
  if (value == null) return null;
  if (value < _sleepMin || value > _sleepMax) return 'Sleep hours must be $_sleepMin–$_sleepMax';
  return null;
}

String? validateSteps(int? value) {
  if (value == null) return null;
  if (value < _stepsMin || value > _stepsMax) return 'Steps must be $_stepsMin–$_stepsMax';
  return null;
}

String? validateCalories(int? value) {
  if (value == null) return null;
  if (value < _caloriesMin || value > _caloriesMax) return 'Calories must be $_caloriesMin–$_caloriesMax';
  return null;
}

String? validateStressLevel(int? value) {
  if (value == null) return null;
  if (value < _stressMin || value > _stressMax) return 'Stress level must be $_stressMin–$_stressMax';
  return null;
}

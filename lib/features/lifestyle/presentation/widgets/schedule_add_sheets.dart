/// What the user is adding to My Schedule (R-031): each type has its own meaning, so Sedi can notify on time and ask
/// "did you take it?" / "did you go?". Pilot V1 (R-034): all four are chosen inside ONE sheet
/// (see `ScheduleAddReminderSheet`), no separate type step.
enum ScheduleAddType { medication, appointment, meeting, free }

/// A medication to create: its name and the times of day (`HH:MM`, sorted).
class NewMedicationInput {
  final String name;

  /// 'HH:MM' times, sorted.
  final List<String> times;
  const NewMedicationInput({required this.name, required this.times});
}

/// `GET/PUT /lifestyle/plan-settings` - which weekdays the plan reminders count for, how long before the item Sedi
/// reminds (`lead`: null = off, 0 = on time, 15, 30) and the weekly-review weekday (ISO 1 = Monday ... 7 = Sunday) + time.
class PlanSettingsDto {
  final List<int> days;
  final int? lead;
  final int reviewWeekday;
  final String reviewTime;

  const PlanSettingsDto({
    this.days = const [1, 2, 3, 4, 5, 6, 7],
    this.lead = 0,
    this.reviewWeekday = 5,
    this.reviewTime = '20:00',
  });

  factory PlanSettingsDto.fromJson(Map<String, dynamic> json) {
    final raw = json['days'];
    final days = <int>[
      if (raw is List)
        for (final d in raw)
          if (int.tryParse('$d') != null) int.parse('$d'),
    ];
    return PlanSettingsDto(
      days: days.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : days,
      lead: json['lead'] == null ? null : int.tryParse('${json['lead']}'),
      reviewWeekday: int.tryParse('${json['review_weekday']}') ?? 5,
      reviewTime: '${json['review_time'] ?? '20:00'}',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'days': days,
        'lead': lead,
        'review_weekday': reviewWeekday,
        'review_time': reviewTime,
      };

  PlanSettingsDto copyWith({
    List<int>? days,
    int? lead,
    bool clearLead = false,
    int? reviewWeekday,
    String? reviewTime,
  }) {
    return PlanSettingsDto(
      days: days ?? this.days,
      lead: clearLead ? null : (lead ?? this.lead),
      reviewWeekday: reviewWeekday ?? this.reviewWeekday,
      reviewTime: reviewTime ?? this.reviewTime,
    );
  }
}

/// The user's answers of the setup sheet (the same fields Sedi asks in chat).
class PlanSetupInput {
  final String domain;
  final String goal;
  final String avoid;
  final String allergies;
  final bool noAllergies;
  final Map<String, String> mealTimes;
  final String? exerciseTime;
  final PlanSettingsDto settings;

  const PlanSetupInput({
    required this.domain,
    this.goal = '',
    this.avoid = '',
    this.allergies = '',
    this.noAllergies = false,
    this.mealTimes = const {},
    this.exerciseTime,
    this.settings = const PlanSettingsDto(),
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'domain': domain,
        if (goal.trim().isNotEmpty) 'goal': goal.trim(),
        if (avoid.trim().isNotEmpty) 'avoid': avoid.trim(),
        if (allergies.trim().isNotEmpty) 'allergies': allergies.trim(),
        if (noAllergies) 'no_allergies': true,
        if (mealTimes.isNotEmpty) 'meal_times': mealTimes,
        if (exerciseTime != null) 'exercise_time': exerciseTime,
        'settings': settings.toJson(),
      };
}

/// Result of `POST /lifestyle/plan/build`: BUILT | UPDATED | NEEDS_INFO | CONSENT_REQUIRED ...
class PlanBuildResultDto {
  final String status;
  final List<String> needs;
  final int created;

  const PlanBuildResultDto({required this.status, this.needs = const [], this.created = 0});

  bool get built => status == 'BUILT' || status == 'UPDATED';

  factory PlanBuildResultDto.fromJson(Map<String, dynamic> json) {
    final needs = json['needs'];
    return PlanBuildResultDto(
      status: '${json['status'] ?? ''}',
      needs: [if (needs is List) for (final n in needs) '$n'],
      created: int.tryParse('${json['created']}') ?? 0,
    );
  }
}

/// `GET /lifestyle/weekly-review`: how the week went, from what the user marked (nothing invented).
class WeeklyReviewDto {
  final String state;
  final int done;
  final int skipped;
  final int total;
  final int percent;
  final int? bestWeekday;
  final int? delta;
  final String message;

  const WeeklyReviewDto({
    required this.state,
    this.done = 0,
    this.skipped = 0,
    this.total = 0,
    this.percent = 0,
    this.bestWeekday,
    this.delta,
    this.message = '',
  });

  bool get hasStory => state != 'empty' && state != 'unavailable' && total > 0;

  factory WeeklyReviewDto.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v == null ? null : int.tryParse('$v');
    return WeeklyReviewDto(
      state: '${json['state'] ?? 'unavailable'}',
      done: asInt(json['done']) ?? 0,
      skipped: asInt(json['skipped']) ?? 0,
      total: asInt(json['total']) ?? 0,
      percent: asInt(json['percent']) ?? 0,
      bestWeekday: asInt(json['best_weekday']),
      delta: asInt(json['delta']),
      message: '${json['message'] ?? ''}',
    );
  }
}

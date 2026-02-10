/// Soft gender guess from name for personalization (non-blocking).
/// Returns male / female / unknown. Heuristics only; default unknown.

enum GuessedGender {
  male,
  female,
  unknown,
}

/// Guess gender from [name] using [langCode] (fa, ar, en).
/// FA/AR: endings like ه, هٔ, ه‌, ة (soft female); common male suffixes (soft).
/// EN: common female endings a, e, ie (soft).
GuessedGender guessGender(String name, String langCode) {
  final n = name.trim();
  if (n.isEmpty) return GuessedGender.unknown;

  final lang = langCode.toLowerCase();
  if (lang == 'fa' || lang == 'ar') {
    return _guessGenderFaAr(n);
  }
  return _guessGenderEn(n);
}

GuessedGender _guessGenderFaAr(String name) {
  // Female: common Persian/Arabic endings (very soft)
  // ه، ة (ta marbuta)
  final trimmed = name.trim();
  if (trimmed.isEmpty) return GuessedGender.unknown;

  final runes = trimmed.runes.toList();
  if (runes.isEmpty) return GuessedGender.unknown;
  final lastChar = String.fromCharCodes([runes.last]);

  if (lastChar == 'ه' || lastChar == 'ة') {
    return GuessedGender.female;
  }
  return GuessedGender.unknown;
}

GuessedGender _guessGenderEn(String name) {
  final lower = name.trim().toLowerCase();
  if (lower.isEmpty) return GuessedGender.unknown;

  // Soft female: common endings (a, e, ie)
  if (lower.endsWith('a') ||
      lower.endsWith('e') ||
      lower.endsWith('ie')) {
    return GuessedGender.female;
  }
  return GuessedGender.unknown;
}

/// String value for persistence (e.g. in UserProfile): 'male', 'female', 'unknown'.
String guessedGenderToValue(GuessedGender g) {
  switch (g) {
    case GuessedGender.male:
      return 'male';
    case GuessedGender.female:
      return 'female';
    case GuessedGender.unknown:
      return 'unknown';
  }
}

/// Parse from stored value; defaults to unknown.
GuessedGender guessedGenderFromValue(String? value) {
  if (value == null) return GuessedGender.unknown;
  switch (value.toLowerCase()) {
    case 'male':
      return GuessedGender.male;
    case 'female':
      return GuessedGender.female;
    default:
      return GuessedGender.unknown;
  }
}

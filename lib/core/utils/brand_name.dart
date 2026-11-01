/// Centralized brand name: EN = "Sedi", FA = "صدی", AR = "صدي" (Arabic spelling, R-048).
/// Use for all UI strings, notifications, onboarding, and intro.
/// Do NOT use "سدی" (wrong spelling) anywhere; always use this helper for FA/AR.
///
/// The animated A3 orb is intentionally language-invariant and must use
/// [sediOrbBrandLatin], never [sediBrandName].

const String sediOrbBrandLatin = 'Sedi.';

String sediBrandName(String langCode) {
  final lang = langCode.toLowerCase();
  if (lang == 'ar') return 'صدي'; // R-048: Arabic spelling with the Arabic Yeh
  if (lang == 'fa') return 'صدی'; // Correct: صدی (not سدی)
  return 'Sedi';
}

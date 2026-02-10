/// Centralized brand name: EN = "Sedi", FA/AR = "صدی".
/// Use for all UI strings, notifications, onboarding, and intro.
/// Do NOT use "سدی" (wrong spelling) anywhere; always use this helper for FA/AR.

String sediBrandName(String langCode) {
  final lang = langCode.toLowerCase();
  if (lang == 'fa' || lang == 'ar') return 'صدی'; // Correct: صدی (not سدی)
  return 'Sedi';
}

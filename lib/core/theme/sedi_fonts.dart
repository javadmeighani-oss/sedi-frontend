/// The approved, licensed app fonts (R-041, Javad 2026-10-29): one family per language, all bundled under
/// `assets/fonts` with their SIL Open Font Licence - never the phone's system font.
///
///   Persian  -> Vazirmatn («وزیر»)
///   Arabic   -> IBM Plex Sans Arabic
///   English  -> IBM Plex Sans
class SediFonts {
  SediFonts._();

  static const String persian = 'Vazirmatn';
  static const String arabic = 'IBMPlexSansArabic';
  static const String english = 'IBMPlexSans';

  /// The family of the app language (`fa` / `ar` / anything else = English).
  static String familyFor(String languageCode) {
    switch (languageCode) {
      case 'fa':
        return persian;
      case 'ar':
        return arabic;
      default:
        return english;
    }
  }

  /// Glyphs the main family lacks (a Latin word inside Persian text, Persian digits inside English...) come from the
  /// other families, so no letter ever falls back to a system font.
  static List<String> fallbackFor(String languageCode) {
    final main = familyFor(languageCode);
    return <String>[
      for (final f in const [persian, english, arabic])
        if (f != main) f,
    ];
  }
}

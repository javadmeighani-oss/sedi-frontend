/// Natural, slow word-by-word reveal of Sedi's text (Javad 2026-10-29: "stream the text, very slow and natural").
///
/// UI-only: it never changes what the backend sent, only WHEN each word appears. A pause follows every word, a little
/// longer after a comma and clearly longer after the end of a sentence, like a person writing to a friend.
class NaturalReveal {
  NaturalReveal._();

  /// Base pause after a word (about five words a second).
  static const int baseMs = 170;

  /// Words + the spaces after them (so joining the tokens gives the original text back).
  static List<String> tokens(String text) {
    return [for (final m in RegExp(r'\S+\s*').allMatches(text)) m.group(0)!];
  }

  /// The pause AFTER [token]. [total] = how many words the whole text has: a very long answer is revealed faster so that
  /// nobody waits half a minute.
  static Duration gapFor(String token, {int total = 0}) {
    final word = token.trimRight();
    var ms = baseMs;
    final letters = word.runes.length;
    if (letters > 7) ms += 40;
    if (letters <= 2) ms -= 50;
    if (word.endsWith('.') || word.endsWith('!') || word.endsWith('?') || word.endsWith('؟') || word.endsWith('…')) {
      ms += 320;
    } else if (word.endsWith(',') || word.endsWith('،') || word.endsWith('؛') || word.endsWith(';') || word.endsWith(':')) {
      ms += 130;
    }
    if (token.contains('\n')) ms += 220;
    if (total > 160) {
      ms = (ms * 0.45).round();
    } else if (total > 90) {
      ms = (ms * 0.7).round();
    }
    return Duration(milliseconds: ms < 60 ? 60 : ms);
  }
}

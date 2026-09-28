/// Defensive normalisation for free-text user input.
///
/// Every string that leaves a text field passes through [InputSanitizer]
/// before it is validated, searched, displayed or stored. The goals are:
///
/// * strip control characters and zero-width/format characters that can be
///   used to smuggle invisible content or break rendering;
/// * collapse runs of whitespace and trim the ends;
/// * enforce a hard length ceiling so nothing unbounded reaches the domain.
///
/// Sanitising is deliberately conservative: it never rewrites visible
/// characters, so names in any script survive intact.
class InputSanitizer {
  const InputSanitizer._();

  /// C0/C1 control characters plus Unicode format characters such as
  /// zero-width joiners, bidirectional overrides and the byte-order mark.
  static final RegExp disallowedPattern = RegExp(
    '[${_range(0x0000, 0x0008)}${_range(0x000B, 0x000C)}'
    '${_range(0x000E, 0x001F)}${_range(0x007F, 0x009F)}'
    '${_range(0x200B, 0x200F)}${_range(0x2028, 0x202E)}'
    '${_range(0x2060, 0x2064)}${_cp(0xFEFF)}]',
  );

  /// Builds a regex character-class range from code points, so the source file
  /// never has to contain invisible characters itself.
  static String _range(int from, int to) => '${_cp(from)}-${_cp(to)}';

  static String _cp(int codePoint) =>
      String.fromCharCode(codePoint).replaceAllMapped(
        RegExp('[^a-zA-Z0-9]'),
        (match) => RegExp.escape(match.group(0)!),
      );

  static final RegExp _whitespaceRun = RegExp(r'\s+');

  /// Returns a cleaned copy of [input].
  ///
  /// [maxLength] caps the result; text beyond the limit is dropped rather
  /// than rejected so the caller can decide how to surface the issue.
  static String clean(String input, {int maxLength = 200}) {
    assert(maxLength > 0, 'maxLength must be positive');

    final stripped = input
        .replaceAll(disallowedPattern, '')
        .replaceAll(_whitespaceRun, ' ')
        .trim();

    if (stripped.length <= maxLength) {
      return stripped;
    }
    return stripped.substring(0, maxLength).trimRight();
  }

  /// Returns `true` when [input] contains characters that [clean] would strip.
  static bool containsDisallowedCharacters(String input) =>
      disallowedPattern.hasMatch(input);
}

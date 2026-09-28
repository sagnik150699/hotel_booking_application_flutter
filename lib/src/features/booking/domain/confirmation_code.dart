import 'dart:math';

/// Produces booking references such as `HB-7KQ2-M9XT`.
///
/// Codes are drawn from a cryptographically secure source by default and use
/// an alphabet without look-alike characters (no `0/O`, `1/I`), so they are
/// safe to read over the phone or type from a printout. Two blocks of four
/// give 32^8 (about a trillion) possibilities, which is more than enough to
/// make guessing another guest's reference impractical.
class ConfirmationCodeGenerator {
  ConfirmationCodeGenerator({Random? random})
    : _random = random ?? Random.secure();

  static const String prefix = 'HB';
  static const String alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const int blockLength = 4;
  static const int blockCount = 2;

  /// Matches codes produced by [next]. Handy for input validation on a
  /// "find my booking" screen.
  static final RegExp pattern = RegExp(
    '^$prefix(?:-[$alphabet]{$blockLength}){$blockCount}\$',
  );

  final Random _random;

  String next() {
    final buffer = StringBuffer(prefix);
    for (var block = 0; block < blockCount; block++) {
      buffer.write('-');
      for (var i = 0; i < blockLength; i++) {
        buffer.write(alphabet[_random.nextInt(alphabet.length)]);
      }
    }
    return buffer.toString();
  }

  static bool isValid(String code) => pattern.hasMatch(code);
}

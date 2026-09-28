import 'package:flutter/foundation.dart';

import '../../../core/validation/input_sanitizer.dart';

/// Contact details for the person making the booking.
///
/// Construct instances through [GuestDetails.sanitized] so every field has
/// been normalised before it is validated or stored.
@immutable
class GuestDetails {
  const GuestDetails._({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  /// Cleans raw form input: strips control characters, trims, collapses
  /// whitespace, lower-cases the e-mail address and normalises the phone
  /// number to digits with an optional leading `+`.
  factory GuestDetails.sanitized({
    required String fullName,
    required String email,
    required String phone,
  }) {
    return GuestDetails._(
      fullName: InputSanitizer.clean(
        fullName,
        maxLength: GuestDetailsValidator.nameMaxLength,
      ),
      email: InputSanitizer.clean(
        email,
        maxLength: GuestDetailsValidator.emailMaxLength,
      ).toLowerCase(),
      phone: GuestDetailsValidator.normalizePhone(phone),
    );
  }

  final String fullName;
  final String email;
  final String phone;

  /// First name only, for friendly copy such as "Thanks, Priya!".
  String get firstName => fullName.split(' ').first;

  /// E-mail with the local part partially masked, safe to echo back on a
  /// confirmation screen: `p***a@example.com`.
  String get maskedEmail {
    final at = email.indexOf('@');
    if (at <= 1) {
      return email;
    }
    final local = email.substring(0, at);
    final domain = email.substring(at);
    if (local.length <= 2) {
      return '${local[0]}*$domain';
    }
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}$domain';
  }

  @override
  bool operator ==(Object other) =>
      other is GuestDetails &&
      other.fullName == fullName &&
      other.email == email &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(fullName, email, phone);

  /// Deliberately omits personal data so accidental logging stays harmless.
  @override
  String toString() => 'GuestDetails(${fullName.isEmpty ? 'empty' : 'set'})';
}

/// Field-level validation for [GuestDetails].
///
/// Each validator accepts the raw string from a text field and returns a
/// user-facing message, or `null` when the value is acceptable. The same
/// functions are reused by the booking policy so the domain never trusts the
/// UI to have validated anything.
abstract final class GuestDetailsValidator {
  static const int nameMinLength = 2;
  static const int nameMaxLength = 60;
  static const int emailMaxLength = 254;
  static const int phoneMinDigits = 8;
  static const int phoneMaxDigits = 15;

  /// Letters from any script, combining marks, spaces, dots, apostrophes and
  /// hyphens. Must start with a letter.
  static final RegExp _namePattern = RegExp(
    r"^[\p{L}\p{M}][\p{L}\p{M} .'\-]*$",
    unicode: true,
  );

  /// Pragmatic e-mail check: a dot-atom local part, an `@`, and a hostname
  /// with at least one dot. Not full RFC 5322, which would accept addresses no
  /// mail provider issues.
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  /// Digits with optional leading `+`; spaces, dashes, dots and brackets are
  /// tolerated as separators in the raw input.
  static final RegExp _phoneInputPattern = RegExp(r'^\+?[0-9][0-9 .\-()]*$');

  static String? fullName(String? value) {
    final cleaned = InputSanitizer.clean(
      value ?? '',
      maxLength: nameMaxLength + 1,
    );
    if (cleaned.isEmpty) {
      return 'Enter the guest\'s full name.';
    }
    if (cleaned.length < nameMinLength) {
      return 'Name must be at least $nameMinLength characters.';
    }
    if (cleaned.length > nameMaxLength) {
      return 'Name must be $nameMaxLength characters or fewer.';
    }
    if (!_namePattern.hasMatch(cleaned)) {
      return 'Use letters, spaces, dots, apostrophes or hyphens only.';
    }
    return null;
  }

  static String? email(String? value) {
    final cleaned = InputSanitizer.clean(
      value ?? '',
      maxLength: emailMaxLength + 1,
    );
    if (cleaned.isEmpty) {
      return 'Enter an e-mail address for the confirmation.';
    }
    if (cleaned.length > emailMaxLength) {
      return 'E-mail address is too long.';
    }
    if (cleaned.contains(' ') || !_emailPattern.hasMatch(cleaned)) {
      return 'Enter a valid e-mail address.';
    }
    return null;
  }

  static String? phone(String? value) {
    final cleaned = InputSanitizer.clean(value ?? '', maxLength: 40);
    if (cleaned.isEmpty) {
      return 'Enter a phone number the hotel can reach you on.';
    }
    if (!_phoneInputPattern.hasMatch(cleaned)) {
      return 'Use digits only, with an optional country code.';
    }
    final digits = normalizePhone(cleaned).replaceFirst('+', '');
    if (digits.length < phoneMinDigits) {
      return 'Phone number must have at least $phoneMinDigits digits.';
    }
    if (digits.length > phoneMaxDigits) {
      return 'Phone number must have $phoneMaxDigits digits or fewer.';
    }
    return null;
  }

  /// Strips separators, keeping digits and a single leading `+`.
  static String normalizePhone(String value) {
    final cleaned = InputSanitizer.clean(value, maxLength: 40);
    final hasPlus = cleaned.startsWith('+');
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Returns the first validation problem across all fields, or `null` when
  /// [details] is complete and well-formed.
  static String? firstError(GuestDetails details) =>
      fullName(details.fullName) ??
      email(details.email) ??
      phone(details.phone);

  static bool isValid(GuestDetails details) => firstError(details) == null;
}

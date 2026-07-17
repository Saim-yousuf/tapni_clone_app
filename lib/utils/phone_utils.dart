/// Phone helpers for WhatsApp-style auth (default country +92).
class PhoneUtils {
  static const String defaultCountryCode = '+92';

  /// Build E.164 phone from country code + local digits.
  static String normalize(String raw, {String countryCode = defaultCountryCode}) {
    var value = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (value.isEmpty) return '';

    if (value.startsWith('00')) {
      value = '+${value.substring(2)}';
    }

    if (value.startsWith('+')) {
      final digits = value.substring(1).replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? '' : '+$digits';
    }

    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final cc = countryCode.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(cc)) {
      return '+$digits';
    }
    return '+$cc$digits';
  }

  static bool isValid(String phone) {
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone);
  }
}

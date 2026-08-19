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

  static String digitsOnly(String? phone) {
    return (phone ?? '').replaceAll(RegExp(r'\D'), '');
  }

  /// Compare numbers ignoring formatting / leading zeros / country prefix.
  static bool sameNumber(String? a, String? b) {
    var da = digitsOnly(a);
    var db = digitsOnly(b);
    if (da.isEmpty || db.isEmpty) return false;
    if (da.startsWith('0')) da = da.substring(1);
    if (db.startsWith('0')) db = db.substring(1);
    if (da.isEmpty || db.isEmpty) return false;
    if (da == db) return true;
    const localLen = 10;
    if (da.length >= localLen && db.length >= localLen) {
      return da.substring(da.length - localLen) ==
          db.substring(db.length - localLen);
    }
    return da.endsWith(db) || db.endsWith(da);
  }
}

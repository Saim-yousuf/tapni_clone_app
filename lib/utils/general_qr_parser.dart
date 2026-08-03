/// Detected content type for a generic QR / barcode payload.
enum GeneralQrType { url, wifi, email, phone, sms, text }

class WifiQrData {
  final String ssid;
  final String password;
  final String security;
  final bool hidden;

  const WifiQrData({
    required this.ssid,
    required this.password,
    required this.security,
    this.hidden = false,
  });
}

class GeneralQrResult {
  final String rawValue;
  final GeneralQrType type;
  final WifiQrData? wifi;

  const GeneralQrResult({
    required this.rawValue,
    required this.type,
    this.wifi,
  });

  String get typeLabel {
    switch (type) {
      case GeneralQrType.url:
        return 'Website / Link';
      case GeneralQrType.wifi:
        return 'Wi‑Fi';
      case GeneralQrType.email:
        return 'Email';
      case GeneralQrType.phone:
        return 'Phone';
      case GeneralQrType.sms:
        return 'SMS';
      case GeneralQrType.text:
        return 'Text / Product';
    }
  }
}

class GeneralQrParser {
  GeneralQrParser._();

  static GeneralQrResult parse(String scannedValue) {
    final raw = scannedValue.trim();
    if (raw.isEmpty) {
      return const GeneralQrResult(rawValue: '', type: GeneralQrType.text);
    }

    final upper = raw.toUpperCase();

    if (upper.startsWith('WIFI:')) {
      return GeneralQrResult(
        rawValue: raw,
        type: GeneralQrType.wifi,
        wifi: _parseWifi(raw),
      );
    }

    if (upper.startsWith('MAILTO:') ||
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw)) {
      return GeneralQrResult(rawValue: raw, type: GeneralQrType.email);
    }

    if (upper.startsWith('TEL:') || upper.startsWith('PHONE:')) {
      return GeneralQrResult(rawValue: raw, type: GeneralQrType.phone);
    }

    if (upper.startsWith('SMS:') || upper.startsWith('SMSTO:')) {
      return GeneralQrResult(rawValue: raw, type: GeneralQrType.sms);
    }

    final uri = Uri.tryParse(raw);
    if (uri != null &&
        (uri.hasScheme &&
            (uri.scheme == 'http' ||
                uri.scheme == 'https' ||
                uri.scheme == 'ftp')) &&
        uri.host.isNotEmpty) {
      return GeneralQrResult(rawValue: raw, type: GeneralQrType.url);
    }

    // Bare domains like example.com/path
    if (RegExp(
      r'^(www\.)?[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}(/\S*)?$',
    ).hasMatch(raw)) {
      return GeneralQrResult(
        rawValue: raw.startsWith('http') ? raw : 'https://$raw',
        type: GeneralQrType.url,
      );
    }

    return GeneralQrResult(rawValue: raw, type: GeneralQrType.text);
  }

  /// WIFI:T:WPA;S:MyNetwork;P:secret;; or WIFI:S:…;T:…;P:…;;
  static WifiQrData? _parseWifi(String raw) {
    final body = raw.substring(5); // after WIFI:
    final fields = <String, String>{};

    // Split on unescaped semicolons
    final parts = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (c == '\\' && i + 1 < body.length) {
        buffer.write(body[i + 1]);
        i++;
        continue;
      }
      if (c == ';') {
        parts.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(c);
    }
    if (buffer.isNotEmpty) parts.add(buffer.toString());

    for (final part in parts) {
      if (part.isEmpty) continue;
      final colon = part.indexOf(':');
      if (colon <= 0) continue;
      final key = part.substring(0, colon).toUpperCase();
      final value = part.substring(colon + 1);
      fields[key] = value;
    }

    final ssid = fields['S'] ?? '';
    if (ssid.isEmpty) return null;

    return WifiQrData(
      ssid: ssid,
      password: fields['P'] ?? '',
      security: fields['T'] ?? 'nopass',
      hidden: (fields['H'] ?? '').toLowerCase() == 'true',
    );
  }
}

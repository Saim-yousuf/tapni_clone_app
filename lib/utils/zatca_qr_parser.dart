import 'dart:convert';
import 'dart:typed_data';

/// Parsed Saudi ZATCA (Fatoora) e-invoice QR payload.
///
/// Phase 1 TLV tags 1–5 are UTF-8 strings. Phase 2 adds cryptographic tags 6–9.
class ZatcaInvoice {
  final String sellerName;
  final String vatNumber;
  final String timestamp;
  final String invoiceTotal;
  final String vatTotal;
  final String? invoiceHash;
  final String? digitalSignature;
  final String? publicKey;
  final String? cryptographicStamp;
  final String rawValue;

  const ZatcaInvoice({
    required this.sellerName,
    required this.vatNumber,
    required this.timestamp,
    required this.invoiceTotal,
    required this.vatTotal,
    this.invoiceHash,
    this.digitalSignature,
    this.publicKey,
    this.cryptographicStamp,
    required this.rawValue,
  });

  bool get isPhase2 =>
      (invoiceHash != null && invoiceHash!.isNotEmpty) ||
      (digitalSignature != null && digitalSignature!.isNotEmpty);
}

/// Decodes Base64 TLV QR codes used on ZATCA-compliant Saudi e-invoices.
class ZatcaQrParser {
  ZatcaQrParser._();

  static ZatcaInvoice? parse(String scannedValue) {
    final raw = scannedValue.trim();
    if (raw.isEmpty) return null;

    final bytes = _decodeBase64(raw);
    if (bytes == null || bytes.length < 6) return null;

    final tags = _parseTlv(bytes);
    if (tags == null) return null;

    final seller = tags[1]?.trim();
    final vat = tags[2]?.trim();
    final timestamp = tags[3]?.trim();
    final total = tags[4]?.trim();
    final vatAmount = tags[5]?.trim();

    if (seller == null ||
        seller.isEmpty ||
        vat == null ||
        vat.isEmpty ||
        total == null ||
        total.isEmpty) {
      return null;
    }

    return ZatcaInvoice(
      sellerName: seller,
      vatNumber: vat,
      timestamp: timestamp ?? '',
      invoiceTotal: total,
      vatTotal: vatAmount ?? '',
      invoiceHash: tags[6],
      digitalSignature: tags[7],
      publicKey: tags[8],
      cryptographicStamp: tags[9],
      rawValue: raw,
    );
  }

  static Uint8List? _decodeBase64(String raw) {
    try {
      var normalized = raw.replaceAll(RegExp(r'\s'), '');
      normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
      final mod = normalized.length % 4;
      if (mod > 0) {
        normalized = normalized.padRight(normalized.length + (4 - mod), '=');
      }
      return Uint8List.fromList(base64.decode(normalized));
    } catch (_) {
      return null;
    }
  }

  /// TLV: tag (1 byte) + length (1 byte) + value (length bytes).
  static Map<int, String>? _parseTlv(Uint8List bytes) {
    final tags = <int, String>{};
    var i = 0;

    while (i + 2 <= bytes.length) {
      final tag = bytes[i];
      final length = bytes[i + 1];
      i += 2;

      if (length < 0 || i + length > bytes.length) return null;

      final valueBytes = bytes.sublist(i, i + length);
      i += length;

      if (tag < 1 || tag > 9) continue;

      if (tag >= 1 && tag <= 5) {
        try {
          tags[tag] = utf8.decode(valueBytes);
        } catch (_) {
          tags[tag] = latin1.decode(valueBytes);
        }
      } else {
        // Phase 2 crypto fields — keep as Base64 for display.
        tags[tag] = base64.encode(valueBytes);
      }
    }

    if (tags.isEmpty) return null;
    return tags;
  }
}

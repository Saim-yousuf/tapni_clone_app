/// User-facing payment labels — never show Stripe / Mongo technical IDs.
class PaymentDisplay {
  PaymentDisplay._();

  static final RegExp _stripeId = RegExp(
    r'^(pi_|ch_|cus_|pm_|seti_|evt_|re_|pyr_|acct_|tok_|src_|card_)',
    caseSensitive: false,
  );
  static final RegExp _mongoOid = RegExp(r'^[a-f0-9]{24}$', caseSensitive: false);
  static final RegExp _stripeInText = RegExp(
    r'\b(?:pi|ch|cus|pm|seti|evt|re)_[A-Za-z0-9]+\b',
  );

  static bool looksTechnical(String? value) {
    final s = (value ?? '').trim();
    if (s.isEmpty) return false;
    if (_stripeId.hasMatch(s)) return true;
    if (_mongoOid.hasMatch(s)) return true;
    if (s.toLowerCase().startsWith('mock_')) return true;
    if (s.toLowerCase().contains('payment_intent')) return true;
    if (s.toLowerCase().contains('client_secret')) return true;
    return false;
  }

  /// Prefer API `publicRef` / `publicPaymentRef`; never echo Stripe/ObjectIds.
  static String friendlyRef({
    String? publicRef,
    String? publicPaymentRef,
    String? fallbackSeed,
  }) {
    for (final candidate in [publicRef, publicPaymentRef]) {
      final v = (candidate ?? '').trim();
      if (v.isEmpty) continue;
      if (!looksTechnical(v)) return v;
    }
    final seed = (fallbackSeed ?? '').trim();
    if (seed.isEmpty || looksTechnical(seed)) return '';
    if (seed.startsWith('BQ-')) return seed;
    return seed.startsWith('#') ? seed : seed;
  }

  static String fromSeed(String? seed) {
    final hex = (seed ?? '').replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
    if (hex.length < 6) return '';
    final n = int.tryParse(hex.substring(hex.length - 6), radix: 16) ?? 0;
    return 'BQ-TXN-${(n % 1000000).toString().padLeft(6, '0')}';
  }

  static String orderLabel({
    dynamic tokenNumber,
    String? publicRef,
  }) {
    if (tokenNumber != null && '$tokenNumber'.trim().isNotEmpty) {
      final t = '$tokenNumber'.trim();
      return t.startsWith('#') ? t : '#$t';
    }
    final ref = friendlyRef(publicRef: publicRef);
    return ref;
  }

  static String stripTechnicalIds(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    return text
        .replaceAll(_stripeInText, '[ref]')
        .replaceAll(RegExp(r'\b[a-f0-9]{24}\b', caseSensitive: false), '[ref]')
        .trim();
  }

  /// Convert Stripe / gateway errors into short user copy.
  static String sanitizeError(String? message, {String fallback = 'Payment failed'}) {
    final raw = (message ?? '').trim();
    if (raw.isEmpty) return fallback;
    final lower = raw.toLowerCase();
    if (lower.contains('card_declined') ||
        lower.contains('card was declined') ||
        lower.contains('your card was declined')) {
      return 'Your card was declined. Try another payment method.';
    }
    if (lower.contains('insufficient_funds') ||
        lower.contains('insufficient funds')) {
      return 'Insufficient funds. Try another payment method.';
    }
    if (lower.contains('expired_card') || lower.contains('card has expired')) {
      return 'This card has expired. Try another payment method.';
    }
    if (lower.contains('incorrect_cvc') ||
        lower.contains('security code is invalid') ||
        lower.contains('invalid cvc')) {
      return 'The security code looks incorrect. Please try again.';
    }
    if (lower.contains('authentication') ||
        lower.contains('requires_action') ||
        lower.contains('3d secure')) {
      return 'Additional authentication is required. Please try again.';
    }
    if (looksTechnical(raw) ||
        lower.contains('stripe') ||
        lower.contains('payment_intent') ||
        lower.contains('idempotency') ||
        lower.contains('webhook') ||
        lower.contains('mongoose') ||
        lower.contains('objectid') ||
        lower.contains('e11000') ||
        raw.length > 160) {
      return fallback;
    }
    final cleaned = stripTechnicalIds(raw);
    return cleaned.isEmpty ? fallback : cleaned;
  }
}

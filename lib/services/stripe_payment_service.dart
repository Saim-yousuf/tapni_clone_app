import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tapni_app/repository/payment_repo.dart';

/// Initializes Stripe publishable key from backend config (never secret key).
class StripePaymentService {
  StripePaymentService._();
  static final StripePaymentService instance = StripePaymentService._();

  bool _initialized = false;
  String? _publishableKey;
  bool _configured = false;
  String? _nativeError;

  bool get isReady =>
      _initialized &&
      _configured &&
      (_publishableKey?.isNotEmpty ?? false) &&
      _nativeError == null;

  String? get nativeError => _nativeError;

  Future<bool> ensureInitialized() async {
    if (kIsWeb) {
      _nativeError =
          'Card payments on Flutter web are not supported here. Use the business website checkout or the Android/iOS app.';
      _initialized = true;
      _configured = false;
      return false;
    }

    if (_initialized && _configured && _nativeError == null) return true;

    final cfg = await PaymentRepo().fetchConfig();
    if (cfg == null) {
      _configured = false;
      _initialized = true;
      return false;
    }
    _configured = cfg['configured'] == true;
    final key = cfg['publishableKey']?.toString() ?? '';
    if (!_configured || key.isEmpty) {
      _initialized = true;
      return false;
    }

    try {
      if (_publishableKey != key) {
        Stripe.publishableKey = key;
        Stripe.merchantIdentifier = 'merchant.com.barqody.app';
        await Stripe.instance.applySettings();
        _publishableKey = key;
      }
      _nativeError = null;
    } on MissingPluginException {
      _nativeError =
          'Stripe native plugin is not linked. Stop the app completely, then run a full rebuild (not hot reload): flutter clean && flutter pub get && flutter run';
      _initialized = true;
      return false;
    } on PlatformException catch (e) {
      _nativeError = e.message ?? e.toString();
      _initialized = true;
      return false;
    }

    _initialized = true;
    return true;
  }

  Future<void> presentPaymentSheet({
    required PaymentIntentSession session,
    required String merchantDisplayName,
  }) async {
    if (!isReady) {
      final ok = await ensureInitialized();
      if (!ok) {
        throw Exception(
          _nativeError ?? 'Stripe is not configured on the server',
        );
      }
    }

    if (session.publishableKey.isNotEmpty &&
        session.publishableKey != _publishableKey) {
      Stripe.publishableKey = session.publishableKey;
      await Stripe.instance.applySettings();
      _publishableKey = session.publishableKey;
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: session.clientSecret,
        merchantDisplayName: merchantDisplayName,
        customerId: session.customerId,
        customerEphemeralKeySecret: session.ephemeralKey,
        style: ThemeMode.system,
        allowsDelayedPaymentMethods: false,
        billingDetailsCollectionConfiguration:
            const BillingDetailsCollectionConfiguration(
          name: CollectionMode.automatic,
          email: CollectionMode.automatic,
          phone: CollectionMode.automatic,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> presentSetupSheet({
    required String clientSecret,
    required String customerId,
    required String ephemeralKey,
    required String merchantDisplayName,
  }) async {
    final ok = await ensureInitialized();
    if (!ok) {
      throw Exception(_nativeError ?? 'Stripe is not ready');
    }
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
        style: ThemeMode.system,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }
}

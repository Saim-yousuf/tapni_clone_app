import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/services/stripe_payment_service.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/stripe_checkout_outcome.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/app_toast.dart';

export 'package:tapni_app/utils/stripe_checkout_outcome.dart'
    show StripeCheckoutOutcome, StripeCheckoutResult;

/// Real Stripe PaymentSheet checkout. Never collects raw card numbers in-app.
class StripeCheckoutScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String currency;
  final String customerName;
  final String? customerEmail;
  final String? businessName;
  final String paymentAttemptKey;
  final String? paymentSessionToken;
  final bool publicGuest;
  final String? guestPhone;
  final bool allowSaveCard;

  const StripeCheckoutScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.customerName,
    this.customerEmail,
    this.businessName,
    required this.paymentAttemptKey,
    this.paymentSessionToken,
    this.publicGuest = false,
    this.guestPhone,
    this.allowSaveCard = true,
  });

  @override
  State<StripeCheckoutScreen> createState() => _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  final _repo = PaymentRepo();
  bool _busy = false;
  bool _stripeReady = false;
  String? _error;
  bool _saveCard = false;
  SavedCard? _selectedCard;
  List<SavedCard> _cards = const [];
  bool _useNewCard = true;

  bool get _canPay => StripeCheckoutGuards.canSubmitPayment(
        stripeReady: _stripeReady,
        busy: _busy,
        useNewCard: _useNewCard,
        selectedSavedCardId: _selectedCard?.id,
      );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _busy = true;
      _error = null;
      _stripeReady = false;
    });
    try {
      final ready = await StripePaymentService.instance.ensureInitialized();
      if (!ready) {
        setState(() {
          _error = StripePaymentService.instance.nativeError ??
              'Online payments are not available yet. Stripe test keys are not configured on the server.';
          _busy = false;
          _stripeReady = false;
        });
        return;
      }
      _stripeReady = true;
      if (!widget.publicGuest && widget.allowSaveCard) {
        final cards = await _repo.listSavedCards();
        if (mounted) {
          setState(() {
            _cards = cards;
            if (cards.isNotEmpty) {
              _selectedCard =
                  cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
              _useNewCard = false;
            } else {
              _useNewCard = true;
              _selectedCard = null;
            }
          });
        }
      } else {
        // Guest / no saved-card UI: PaymentSheet collects the method.
        _useNewCard = true;
        _selectedCard = null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _stripeReady = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    if (_busy) return;
    if (!_canPay) {
      setState(() {
        _error = _useNewCard
            ? 'Payment is not ready yet.'
            : 'Select a saved card or choose “Use a new card”.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        setState(() {
          _error =
              'Card payment on Flutter web uses the business website checkout. Please complete payment in the browser site, or use the mobile app.';
          _busy = false;
        });
        return;
      }

      if (!_useNewCard &&
          (_selectedCard == null || _selectedCard!.id.trim().isEmpty)) {
        setState(() {
          _error = 'Select a saved card or choose “Use a new card”.';
          _busy = false;
        });
        return;
      }

      final intentRes = await _repo.createOrderIntent(
        orderId: widget.orderId,
        publicGuest: widget.publicGuest,
        saveCard: !widget.publicGuest && _saveCard && _useNewCard,
        paymentMethodId:
            !_useNewCard && _selectedCard != null ? _selectedCard!.id : null,
        paymentAttemptKey: widget.paymentAttemptKey,
        idempotencyKey: widget.paymentAttemptKey,
        guestPhone: widget.guestPhone,
        paymentSessionToken: widget.paymentSessionToken,
        email: widget.customerEmail,
      );

      if (!intentRes.success) {
        setState(() {
          _error = PaymentDisplay.sanitizeError(
            intentRes.message,
            fallback: 'Could not start payment',
          );
          _busy = false;
        });
        return;
      }

      final raw = intentRes.data is Map && intentRes.data['data'] is Map
          ? Map<String, dynamic>.from(intentRes.data['data'] as Map)
          : Map<String, dynamic>.from(intentRes.data as Map);
      final session = PaymentIntentSession.fromJson(raw);

      if (session.alreadyPaid) {
        if (!mounted) return;
        Navigator.of(context).pop(
          const StripeCheckoutResult(
            outcome: StripeCheckoutOutcome.success,
            paymentStatus: 'paid',
            simulated: false,
            message: 'Already paid',
          ),
        );
        return;
      }

      if (session.clientSecret.isEmpty || session.paymentIntentId.isEmpty) {
        setState(() {
          _error = 'Missing payment client secret';
          _busy = false;
        });
        return;
      }

      // PaymentSheetResult.completed → returns normally
      // PaymentSheetResult.canceled → StripeException(FailureCode.Canceled)
      // PaymentSheetResult.failed → StripeException (other)
      await StripePaymentService.instance.presentPaymentSheet(
        session: session,
        merchantDisplayName: widget.businessName?.trim().isNotEmpty == true
            ? widget.businessName!.trim()
            : 'BarQody',
      );

      // Only after completed sheet: verify with backend (never trust sheet alone).
      final confirm = await _repo.confirmOrderPayment(
        orderId: widget.orderId,
        paymentIntentId: session.paymentIntentId,
        publicGuest: widget.publicGuest,
        guestPhone: widget.guestPhone,
        paymentSessionToken: widget.paymentSessionToken,
      );

      if (!mounted) return;

      if (!confirm.success) {
        setState(() {
          _error = PaymentDisplay.sanitizeError(
            confirm.message,
            fallback: 'Payment could not be verified',
          );
          _busy = false;
        });
        return;
      }

      final data = confirm.data is Map && confirm.data['data'] is Map
          ? Map<String, dynamic>.from(confirm.data['data'] as Map)
          : <String, dynamic>{};

      final mapped = StripeCheckoutGuards.resultFromBackendConfirm(
        data: data,
        fallbackPaymentIntentId: session.paymentIntentId,
        message: confirm.message,
      );

      if (mapped.outcome == StripeCheckoutOutcome.success) {
        Navigator.of(context).pop(mapped);
        return;
      }

      // Pending / failed after sheet — stay on checkout, do not open success.
      setState(() {
        _error = mapped.message ?? 'Payment was not completed';
        _busy = false;
      });
    } on StripeException catch (e) {
      if (!mounted) return;
      // Canceled: stay on this checkout screen — never pop success.
      if (e.error.code == FailureCode.Canceled) {
        setState(() {
          _busy = false;
          _error = null;
        });
        showAppToast(
              context,
              'Payment cancelled',
              kind: AppToastKind.info,
            );
        return;
      }
      setState(() {
        _error = PaymentDisplay.sanitizeError(
          e.error.localizedMessage ?? e.error.message,
          fallback: 'Payment failed',
        );
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PaymentDisplay.sanitizeError(
          e.toString(),
          fallback: 'Payment failed',
        );
        _busy = false;
      });
    }
  }

  Future<void> _addCard() async {
    if (widget.publicGuest) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await _repo.createSetupIntent();
      if (!res.success) {
        setState(() {
          _error = PaymentDisplay.sanitizeError(
            res.message,
            fallback: 'Could not start card setup',
          );
          _busy = false;
        });
        return;
      }
      final data = res.data is Map && res.data['data'] is Map
          ? Map<String, dynamic>.from(res.data['data'] as Map)
          : Map<String, dynamic>.from(res.data as Map);
      await StripePaymentService.instance.presentSetupSheet(
        clientSecret: data['clientSecret']?.toString() ?? '',
        customerId: data['customerId']?.toString() ?? '',
        ephemeralKey: data['ephemeralKey']?.toString() ?? '',
        merchantDisplayName: 'BarQody',
      );
      final cards = await _repo.listSavedCards();
      if (mounted) {
        setState(() {
          _cards = cards;
          _useNewCard = false;
          if (cards.isNotEmpty) {
            _selectedCard = cards.first;
          }
          _busy = false;
        });
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        setState(() => _busy = false);
        return;
      }
      setState(() {
        _error = PaymentDisplay.sanitizeError(
          e.error.localizedMessage,
          fallback: 'Could not save card',
        );
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = PaymentDisplay.sanitizeError(
          e.toString(),
          fallback: 'Could not save card',
        );
        _busy = false;
      });
    }
  }

  Future<void> _removeCard(SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove card'),
        content: Text('Remove ${card.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.removeCard(card.id);
    if (!mounted) return;
    if (res.success) {
      final cards = await _repo.listSavedCards();
      setState(() {
        _cards = cards;
        if (_selectedCard?.id == card.id) {
          _selectedCard = cards.isEmpty ? null : cards.first;
          _useNewCard = cards.isEmpty;
        }
      });
    } else {
      showAppToast(
            context,
            res.message ?? 'Could not remove card',
            kind: AppToastKind.error,
          );
    }
  }

  Future<void> _setDefault(SavedCard card) async {
    final res = await _repo.setDefaultCard(card.id);
    if (!mounted) return;
    if (res.success) {
      final cards = await _repo.listSavedCards();
      setState(() {
        _cards = cards;
        _selectedCard = card;
        _useNewCard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountLabel =
        formatMoney(widget.amount, currency: widget.currency);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Explicit null result — catalog checkout must not treat as paid.
        leading: Center(
          child: CircleBackButton(onTap: () => Navigator.pop(context)),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              amountLabel,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.businessName?.isNotEmpty == true
                  ? 'Pay ${widget.businessName}'
                  : 'Secure card payment',
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 15),
            ),
            const SizedBox(height: 24),
            if (!widget.publicGuest) ...[
              const Text(
                'Payment method',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ..._cards.map((card) {
                final selected = !_useNewCard && _selectedCard?.id == card.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedCard = card;
                      _useNewCard = false;
                    }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? Colors.black : const Color(0xFFE5E5EA),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (card.expiryLabel.isNotEmpty)
                                  Text(
                                    'Exp ${card.expiryLabel}${card.isDefault ? ' · Default' : ''}',
                                    style: const TextStyle(
                                      color: Color(0xFF71717A),
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'default') _setDefault(card);
                              if (v == 'remove') _removeCard(card);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'default',
                                child: Text('Set as default'),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: () => setState(() {
                  _useNewCard = true;
                  _selectedCard = null;
                }),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _useNewCard ? Colors.black : const Color(0xFFE5E5EA),
                      width: _useNewCard ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _useNewCard
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Use a new card',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_useNewCard && widget.allowSaveCard) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveCard,
                  onChanged: (v) => setState(() => _saveCard = v ?? false),
                  title: const Text(
                    'Save this card for future payments',
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              TextButton.icon(
                onPressed: _busy || !_stripeReady ? null : _addCard,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Add a card without charging'),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'Guest checkout — card will not be saved to another account.',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _canPay ? _pay : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFFD4D4D8),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pay $amountLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            if (!_canPay && !_busy && _stripeReady && !_useNewCard) ...[
              const SizedBox(height: 8),
              const Text(
                'Select a saved card or “Use a new card” to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Card details are collected securely by Stripe. BarQody never stores full card numbers or CVC.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

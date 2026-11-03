import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

enum MockPaymentOutcome { success, failure, cancelled }

class MockPaymentResult {
  final MockPaymentOutcome outcome;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentTransactionId;
  final bool simulated;
  final String? message;

  const MockPaymentResult({
    required this.outcome,
    required this.paymentStatus,
    this.paymentMethod = 'online',
    this.paymentTransactionId,
    this.simulated = true,
    this.message,
  });
}

/// Stripe-inspired demo checkout. Never sends card data to the server.
class MockStripeCheckoutScreen extends StatefulWidget {
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

  const MockStripeCheckoutScreen({
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
  });

  @override
  State<MockStripeCheckoutScreen> createState() =>
      _MockStripeCheckoutScreenState();
}

class _MockStripeCheckoutScreenState extends State<MockStripeCheckoutScreen> {
  final _emailCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();

  bool _busy = false;
  String? _fieldError;
  MockPaymentResult? _result;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.customerEmail ?? '';
  }

  @override
  void dispose() {
    // Wipe demo card fields from memory on leave.
    _cardCtrl.clear();
    _expCtrl.clear();
    _cvcCtrl.clear();
    _emailCtrl.dispose();
    _cardCtrl.dispose();
    _expCtrl.dispose();
    _cvcCtrl.dispose();
    super.dispose();
  }

  bool _validateDemoFields() {
    final digits = _cardCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12) {
      setState(() => _fieldError = 'Enter a demo card number (not charged).');
      return false;
    }
    final expDigits = _expCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (expDigits.length < 4) {
      setState(() => _fieldError = 'Enter a demo expiry (MM / YY).');
      return false;
    }
    final cvc = _cvcCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cvc.length < 3) {
      setState(() => _fieldError = 'Enter a demo CVC (not stored).');
      return false;
    }
    setState(() => _fieldError = null);
    return true;
  }

  void _wipeCardFields() {
    _cardCtrl.clear();
    _expCtrl.clear();
    _cvcCtrl.clear();
  }

  Future<void> _runDemo(String outcome) async {
    if (_busy) return;
    if (outcome == 'success' && !_validateDemoFields()) return;

    setState(() => _busy = true);
    _wipeCardFields();

    final res = await CatalogRepo().processMockPayment(
      orderId: widget.orderId,
      demoOutcome: outcome,
      paymentAttemptKey: '${widget.paymentAttemptKey}_$outcome',
      paymentSessionToken: widget.paymentSessionToken,
      publicGuest: widget.publicGuest,
      guestPhone: widget.guestPhone,
    );

    if (!mounted) return;

    if (!res.success || res.data == null) {
      setState(() {
        _busy = false;
        _result = MockPaymentResult(
          outcome: MockPaymentOutcome.failure,
          paymentStatus: 'failed',
          message: res.message ?? 'Simulated payment failed',
        );
      });
      return;
    }

    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final status = payload['paymentStatus']?.toString() ?? '';

    MockPaymentOutcome mapped;
    if (outcome == 'cancel' || status == 'cancelled') {
      mapped = MockPaymentOutcome.cancelled;
    } else if (outcome == 'failure' || status == 'failed') {
      mapped = MockPaymentOutcome.failure;
    } else {
      mapped = MockPaymentOutcome.success;
    }

    setState(() {
      _busy = false;
      _result = MockPaymentResult(
        outcome: mapped,
        paymentStatus: status.isNotEmpty
            ? status
            : (mapped == MockPaymentOutcome.success
                ? 'simulated_paid'
                : mapped == MockPaymentOutcome.cancelled
                    ? 'cancelled'
                    : 'failed'),
        paymentMethod: payload['paymentMethod']?.toString() ?? 'online',
        paymentTransactionId: (payload['publicPaymentRef'] ??
                payload['publicRef'] ??
                payload['paymentTransactionId'])
            ?.toString(),
        simulated: true,
        message: res.message,
      );
    });
  }

  void _finish() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).pop(result);
  }

  void _retry() {
    setState(() => _result = null);
  }

  Future<void> _cancel() async {
    if (_result != null) {
      Navigator.of(context).pop(_result);
      return;
    }
    await _runDemo('cancel');
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _busy ? null : _cancel,
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF425466),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'SIMULATED · DEMO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: result == null
                  ? _buildForm()
                  : _buildResult(result),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Secure checkout',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A2540),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stripe-style demo for ${widget.businessName ?? 'Barqody'}. No real payment processing.',
            style: WaUi.body.copyWith(
              color: const Color(0xFF425466),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E8EE)),
            ),
            child: Column(
              children: [
                _sumRow('Amount', formatMoney(widget.amount, currency: widget.currency)),
                const SizedBox(height: 8),
                _sumRow('Currency', widget.currency.toUpperCase()),
                const SizedBox(height: 8),
                _sumRow('Customer', widget.customerName.trim().isEmpty ? '—' : widget.customerName),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E8EE)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF635BFF).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field('Email', _emailCtrl, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(
                  'Card number',
                  _cardCtrl,
                  keyboard: TextInputType.number,
                  hint: '4242 4242 4242 4242',
                  formatters: [_CardNumberFormatter()],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Expiry',
                        _expCtrl,
                        keyboard: TextInputType.number,
                        hint: 'MM / YY',
                        formatters: [_ExpiryFormatter()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        'CVC',
                        _cvcCtrl,
                        keyboard: TextInputType.number,
                        hint: 'CVC',
                        obscure: true,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_fieldError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _fieldError!,
                    style: WaUi.body.copyWith(
                      color: const Color(0xFFC0392B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Demo fields only — card details are wiped and never sent to the server.',
                  style: WaUi.body.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF8898AA),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _StripeButton(
            label: _busy ? 'Processing…' : 'Simulate successful payment',
            onPressed: _busy ? null : () => _runDemo('success'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : () => _runDemo('failure'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFF0A2540),
              side: const BorderSide(color: Color(0xFFD6DEE8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Simulate failure',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _cancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF697386),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(MockPaymentResult result) {
    final ok = result.outcome == MockPaymentOutcome.success;
    final fail = result.outcome == MockPaymentOutcome.failure;
    final color = ok
        ? const Color(0xFF16A34A)
        : fail
            ? const Color(0xFFDC2626)
            : const Color(0xFF64748B);
    final title = ok
        ? 'Demo payment complete'
        : fail
            ? 'Demo payment failed'
            : 'Payment cancelled';
    final sub = ok
        ? 'This was a demo only — not a real card charge.'
        : fail
            ? (result.message ?? 'You can retry this demo payment.')
            : 'No charge was made. You can retry or close.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              ok
                  ? Icons.check_rounded
                  : fail
                      ? Icons.close_rounded
                      : Icons.remove_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A2540),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              color: const Color(0xFF425466),
              height: 1.4,
            ),
          ),
          if (() {
            final ref = PaymentDisplay.friendlyRef(
              publicRef: result.paymentTransactionId,
            );
            return ref.isNotEmpty &&
                !PaymentDisplay.looksTechnical(result.paymentTransactionId);
          }()) ...[
            const SizedBox(height: 12),
            Text(
              'Ref: ${PaymentDisplay.friendlyRef(publicRef: result.paymentTransactionId)}',
              style: WaUi.body.copyWith(
                fontSize: 12,
                color: const Color(0xFF8898AA),
              ),
            ),
          ],
          const Spacer(),
          if (fail || result.outcome == MockPaymentOutcome.cancelled)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: _retry,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry payment',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          PillButton(
            label: 'Continue',
            onPressed: _finish,
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: WaUi.body.copyWith(
            color: const Color(0xFF697386),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: WaUi.body.copyWith(
              color: const Color(0xFF0A2540),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    String? hint,
    bool obscure = false,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF697386),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          inputFormatters: formatters,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE3E8EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE3E8EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF635BFF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StripeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _StripeButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF635BFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(clipped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;
    var text = clipped;
    if (clipped.length >= 3) {
      text = '${clipped.substring(0, 2)} / ${clipped.substring(2)}';
    } else if (clipped.length >= 1 && oldValue.text.length < newValue.text.length && clipped.length <= 2) {
      text = clipped;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

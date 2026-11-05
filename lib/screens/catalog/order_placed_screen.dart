import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';

import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Full-screen confirmation after place order / book stay / similar flows.
class OrderPlacedScreen extends StatelessWidget {
  final int token;
  final String? customerUsername;
  final String? customerName;
  final String? guestPhone;
  final String? businessUsername;
  final int totalItems;
  final double totalAmount;
  final String? currency;
  final String? orderId;

  /// order | appointment | stay — drives copy only.
  final String bookingKind;
  final String? paymentMethod;
  final String? paymentStatus;
  final bool paymentSimulated;

  const OrderPlacedScreen({
    super.key,
    required this.token,
    this.customerUsername,
    this.customerName,
    this.guestPhone,
    this.businessUsername,
    required this.totalItems,
    required this.totalAmount,
    this.currency,
    this.orderId,
    this.bookingKind = 'order',
    this.paymentMethod,
    this.paymentStatus,
    this.paymentSimulated = false,
  });

  String get _paymentLabel {
    final method = (paymentMethod ?? '').trim().toLowerCase();
    final status = (paymentStatus ?? '').trim().toLowerCase();
    if (method == 'online') {
      if (status == 'simulated_paid' || paymentSimulated) {
        return 'Online · demo payment (not a real charge)';
      }
      if (status == 'paid') return 'Online · paid';
      if (status == 'failed') return 'Online · payment failed';
      if (status == 'cancelled') return 'Online · cancelled';
      return 'Online · awaiting payment';
    }
    if (method == 'cash_on_delivery' || method == 'cash') {
      return 'Cash on delivery';
    }
    return '';
  }

  static String _handle(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return '—';
    return v.startsWith('@') ? v : '@$v';
  }

  String get _customerLabel {
    final uname = (customerUsername ?? '').trim().replaceFirst('@', '');
    if (uname.isNotEmpty) return '@$uname';
    final name = (customerName ?? '').trim();
    if (name.isNotEmpty) return name;
    return '—';
  }

  String get _kind {
    final k = bookingKind.trim().toLowerCase();
    if (k == 'appointment' || k == 'stay' || k == 'order') return k;
    return 'order';
  }

  String get _barTitle {
    switch (_kind) {
      case 'stay':
        return 'Stay Reserved';
      case 'appointment':
        return 'Booked';
      default:
        return 'Order Placed';
    }
  }

  String get _headline {
    switch (_kind) {
      case 'stay':
        return 'Your stay\nis reserved!';
      case 'appointment':
        return 'Booking\nrequest sent!';
      default:
        return 'Your Order\nWas Placed!';
    }
  }

  String get _subtitle {
    switch (_kind) {
      case 'stay':
        return "Your room reservation is confirmed. You'll receive updates shortly.";
      case 'appointment':
        return "Your booking request was sent. You'll be notified once the business confirms.";
      default:
        return "Your order has been confirmed successfully. You'll "
            'receive updates about your order shortly.';
    }
  }

  String get _itemsLabel {
    switch (_kind) {
      case 'stay':
        return 'Rooms';
      case 'appointment':
        return 'Services';
      default:
        return 'Total items';
    }
  }

  String get _tokenLabel {
    if (token <= 0) return '';
    return '#$token';
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customerLabel;
    final business = _handle(businessUsername);
    final phone = (guestPhone ?? '').trim();

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: _barTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/png/check-icon-1.png',
                          width: 32,
                          height: 32,
                          color: Colors.white,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _headline,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: 14,
                        color: BarqodyChrome.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(height: 1, color: BarqodyChrome.divider),
                    if (_tokenLabel.isNotEmpty)
                      _DetailRow(
                        label: _kind == 'order' ? 'Order number' : 'Booking number',
                        value: _tokenLabel,
                      ),
                    _DetailRow(label: 'Customer', value: customer),
                    if (phone.isNotEmpty)
                      _DetailRow(label: 'Phone', value: phone),
                    _DetailRow(label: 'Business', value: business),
                    _DetailRow(
                      label: _itemsLabel,
                      value: '$totalItems',
                    ),
                    if (_paymentLabel.isNotEmpty)
                      _DetailRow(label: 'Payment', value: _paymentLabel),
                    const Divider(height: 1, color: BarqodyChrome.divider),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Text(
                            'Total amount',
                            style: WaUi.body.copyWith(
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatMoney(totalAmount, currency: currency),
                            style: WaUi.body.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  PillButton(
                    label: 'Go Home',
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                  if (orderId != null) ...[
                    const SizedBox(height: 12),
                    PillButton(
                      label: _kind == 'order' ? 'View order' : 'View booking',
                      filled: false,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          AppPageRoute(
                            builder: (_) => OrderDetailScreen(
                              orderId: orderId!,
                              isBusinessView: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
          ),
          const Spacer(),
          Text(
            value,
            style: WaUi.body.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

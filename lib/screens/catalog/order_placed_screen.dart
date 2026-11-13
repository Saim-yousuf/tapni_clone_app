import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';

import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Full-screen confirmation after place order / book stay / similar flows.
/// Visual language matches app success screens (loyalty / activation).
class OrderPlacedScreen extends StatefulWidget {
  final int token;
  final String? customerUsername;
  final String? customerName;
  final String? guestPhone;
  final String? businessUsername;
  final String? businessName;
  final int totalItems;
  final double totalAmount;
  final String? currency;
  final String? orderId;

  /// order | appointment | stay — drives copy only.
  final String bookingKind;
  final String? paymentMethod;
  final String? paymentStatus;
  final bool paymentSimulated;

  /// takeaway | delivery (menu orders).
  final String? orderType;
  final String? fulfillmentAddress;

  const OrderPlacedScreen({
    super.key,
    required this.token,
    this.customerUsername,
    this.customerName,
    this.guestPhone,
    this.businessUsername,
    this.businessName,
    required this.totalItems,
    required this.totalAmount,
    this.currency,
    this.orderId,
    this.bookingKind = 'order',
    this.paymentMethod,
    this.paymentStatus,
    this.paymentSimulated = false,
    this.orderType,
    this.fulfillmentAddress,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _bodyFade;

  String get _paymentLabel {
    final method = (widget.paymentMethod ?? '').trim().toLowerCase();
    final status = (widget.paymentStatus ?? '').trim().toLowerCase();
    if (method == 'online') {
      if (status == 'simulated_paid' || widget.paymentSimulated) {
        return 'Online · paid';
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

  String get _customerLabel {
    final name = (widget.customerName ?? '').trim();
    if (name.isNotEmpty) return name;
    final uname =
        (widget.customerUsername ?? '').trim().replaceFirst('@', '');
    if (uname.isNotEmpty) return '@$uname';
    return '—';
  }

  String get _businessLabel {
    final name = (widget.businessName ?? '').trim();
    if (name.isNotEmpty) return name;
    final uname =
        (widget.businessUsername ?? '').trim().replaceFirst('@', '');
    if (uname.isNotEmpty) return '@$uname';
    return '—';
  }

  String get _orderTypeLabel {
    final t = (widget.orderType ?? '').trim().toLowerCase();
    if (t == 'delivery') return 'Delivery';
    if (t == 'takeaway' || t == 'pickup') return 'Pickup';
    return '';
  }

  String get _kind {
    final k = widget.bookingKind.trim().toLowerCase();
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
        return 'Your stay is reserved!';
      case 'appointment':
        return 'Booking request sent!';
      default:
        return 'Order placed successfully!';
    }
  }

  String get _subtitle {
    switch (_kind) {
      case 'stay':
        return "Your room reservation is confirmed. You'll receive updates shortly.";
      case 'appointment':
        return "Your booking request was sent. You'll be notified once the business confirms.";
      default:
        return "Your order has been confirmed. You'll receive updates about your order shortly.";
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
    if (widget.token <= 0) return '';
    return '#${widget.token}';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _heroScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _heroFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _bodyFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
    );
    _ctrl.forward().whenComplete(() {
      if (mounted) _pulseCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildSuccessHero() {
    return SizedBox(
      width: 128,
      height: 128,
      child: AnimatedBuilder(
        animation: Listenable.merge([_heroScale, _heroFade, _pulseCtrl]),
        builder: (context, _) {
          final pulse = Curves.easeOut.transform(_pulseCtrl.value);
          final ringScale = 1.0 + (pulse * 0.55);
          final ringOpacity = (1.0 - pulse) * 0.38;
          final ring2 = Curves.easeOut.transform(
            ((_pulseCtrl.value + 0.45) % 1.0),
          );
          final ring2Scale = 1.0 + (ring2 * 0.55);
          final ring2Opacity = (1.0 - ring2) * 0.22;

          return FadeTransition(
            opacity: _heroFade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1).animate(_heroScale),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: ringOpacity),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: ring2Scale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: ring2Opacity),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/png/check-icon-1.png',
                      width: 34,
                      height: 34,
                      color: Colors.white,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customerLabel;
    final business = _businessLabel;
    final phone = (widget.guestPhone ?? '').trim();
    final orderType = _orderTypeLabel;
    final address = (widget.fulfillmentAddress ?? '').trim();

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: _barTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  children: [
                    _buildSuccessHero(),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: _bodyFade,
                      child: SlideTransition(
                        position: _bodySlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _headline,
                              textAlign: TextAlign.center,
                              style: WaUi.toolsTitleOf(
                                size: 24,
                                weight: FontWeight.w800,
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
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                8,
                                18,
                                8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: BarqodyChrome.divider,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  if (_tokenLabel.isNotEmpty)
                                    _DetailRow(
                                      label: _kind == 'order'
                                          ? 'Order number'
                                          : 'Booking number',
                                      value: _tokenLabel,
                                    ),
                                  _DetailRow(
                                    label: 'Customer',
                                    value: customer,
                                  ),
                                  if (phone.isNotEmpty)
                                    _DetailRow(label: 'Phone', value: phone),
                                  _DetailRow(
                                    label: 'Business',
                                    value: business,
                                  ),
                                  if (orderType.isNotEmpty)
                                    _DetailRow(
                                      label: 'Order type',
                                      value: orderType,
                                    ),
                                  if (orderType == 'Delivery' &&
                                      address.isNotEmpty)
                                    _DetailRow(
                                      label: 'Address',
                                      value: address,
                                    ),
                                  _DetailRow(
                                    label: _itemsLabel,
                                    value: '${widget.totalItems}',
                                  ),
                                  if (_paymentLabel.isNotEmpty)
                                    _DetailRow(
                                      label: 'Payment',
                                      value: _paymentLabel,
                                    ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: BarqodyChrome.divider,
                                    ),
                                  ),
                                  _DetailRow(
                                    label: 'Total amount',
                                    value: formatMoney(
                                      widget.totalAmount,
                                      currency: widget.currency,
                                    ),
                                    emphasis: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FadeTransition(
                opacity: _bodyFade,
                child: Column(
                  children: [
                    PillButton(
                      label: 'Go Home',
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    if ((widget.orderId ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      PillButton(
                        label:
                            _kind == 'order' ? 'View order' : 'View booking',
                        filled: false,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            AppPageRoute(
                              builder: (_) => OrderDetailScreen(
                                orderId: widget.orderId!.trim(),
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
  final bool emphasis;

  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = WaUi.body.copyWith(
      fontSize: 14,
      height: 1.35,
      fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
      color: emphasis ? Colors.black : BarqodyChrome.secondaryText,
    );
    final valueStyle = WaUi.body.copyWith(
      fontSize: 14,
      height: 1.35,
      fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
      color: Colors.black,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

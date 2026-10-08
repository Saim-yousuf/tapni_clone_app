import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/cart_line_item.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class ServiceBookingCartScreen extends StatefulWidget {
  final List<CatalogItem> catalogItems;
  final List<CartLineItem> initialCart;
  final String businessId;
  final String businessLinkId;
  final String businessName;
  final String? businessUsername;
  final String? currency;
  final String? customerUsername;
  final VoidCallback? onBookedSuccess;

  const ServiceBookingCartScreen({
    super.key,
    required this.catalogItems,
    required this.initialCart,
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    this.businessUsername,
    this.currency,
    this.customerUsername,
    this.onBookedSuccess,
  });

  @override
  State<ServiceBookingCartScreen> createState() =>
      _ServiceBookingCartScreenState();
}

class _ServiceBookingCartScreenState extends State<ServiceBookingCartScreen> {
  late List<CartLineItem> _cart;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _cart = List<CartLineItem>.from(widget.initialCart);
  }

  int get _totalQty => _cart.fold(0, (s, l) => s + l.quantity);

  double get _total => _cart.fold(0.0, (sum, line) {
        final item = widget.catalogItems[line.itemIndex];
        return sum + item.displayPrice * line.quantity;
      });

  void _setQty(int index, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: qty);
      }
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy').format(d);
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    return raw;
  }

  Future<void> _bookNow() async {
    if (_cart.isEmpty || _placing) return;
    setState(() => _placing = true);

    final orderItems = _cart.map((line) {
      final item = widget.catalogItems[line.itemIndex];
      return {
        'name': item.name,
        'price': item.displayPrice,
        'quantity': line.quantity,
        if (item.imageUrl.isNotEmpty) 'image': item.imageUrl,
        if (line.notes.isNotEmpty) 'notes': line.notes,
      };
    }).toList();

    final bookingDate = _cart
        .map((e) => e.bookingDate)
        .firstWhere((d) => d != null && d.isNotEmpty, orElse: () => null);
    final bookingTime = _cart
        .map((e) => e.bookingTime)
        .firstWhere((t) => t != null && t.isNotEmpty, orElse: () => null);

    final res = await CatalogRepo().placeOrder(
      businessId: widget.businessId,
      businessLinkId: widget.businessLinkId,
      catalogType: 'services',
      items: orderItems,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
    );

    if (!mounted) return;
    setState(() => _placing = false);

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? context.l10n.failedToPlaceOrder),
        ),
      );
      return;
    }

    final token = CatalogOrder.tokenFromApi(res.data);
    final orderId = _orderIdFromApi(res.data);
    final bookingCode = token > 0
        ? '#BK$token'
        : (orderId != null && orderId.length >= 4
            ? '#BK${orderId.substring(orderId.length - 4).toUpperCase()}'
            : '#BK----');

    widget.onBookedSuccess?.call();

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ServiceBookingSuccessScreen(
          bookingCode: bookingCode,
          orderId: orderId,
          customerUsername: widget.customerUsername,
          businessUsername: widget.businessUsername ?? widget.businessName,
          totalServices: _totalQty,
          totalAmount: _total,
          currency: widget.currency,
        ),
      ),
    );
  }

  String? _orderIdFromApi(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final nested = map['data'];
    if (nested is Map) {
      final id = nested['id'] ?? nested['_id'];
      if (id != null) return id.toString();
    }
    final id = map['id'] ?? map['_id'];
    return id?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(List<CartLineItem>.from(_cart));
      },
      child: Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Your Booking',
              onBack: () =>
                  Navigator.of(context).pop(List<CartLineItem>.from(_cart)),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: BarqodyChrome.divider),
            Expanded(
              child: _cart.isEmpty
                  ? Center(
                      child: Text(
                        'No services selected',
                        style: WaUi.body.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      itemCount: _cart.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: BarqodyChrome.divider,
                      ),
                      itemBuilder: (context, index) {
                        final line = _cart[index];
                        final item = widget.catalogItems[line.itemIndex];
                        return _BookingLineRow(
                          item: item,
                          quantity: line.quantity,
                          currency: widget.currency,
                          dateLabel: _formatDate(line.bookingDate),
                          timeLabel: _formatTime(line.bookingTime),
                          onDecrement: () => _setQty(index, line.quantity - 1),
                          onIncrement: () => _setQty(index, line.quantity + 1),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: BarqodyChrome.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Service',
                          style: WaUi.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(_total, currency: widget.currency),
                          style: WaUi.toolsTitleOf(
                            size: 20,
                            weight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    height: WaUi.primaryButtonHeight,
                    child: ElevatedButton(
                      onPressed:
                          _cart.isEmpty || _placing ? null : _bookNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        disabledBackgroundColor:
                            Colors.black.withValues(alpha: 0.35),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: _placing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Book Now',
                              style: WaUi.promoButton.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _BookingLineRow extends StatelessWidget {
  final CatalogItem item;
  final int quantity;
  final String? currency;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _BookingLineRow({
    required this.item,
    required this.quantity,
    required this.currency,
    required this.dateLabel,
    required this.timeLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.imageUrl.trim().isNotEmpty
                  ? CachedAppImage(
                      url: item.imageUrl,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                    )
                  : Container(
                      color: BarqodyChrome.fieldFill,
                      child: const Icon(
                        Icons.spa_outlined,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(item.displayPrice, currency: currency),
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: WaUi.body.copyWith(
                      fontSize: 12,
                      color: BarqodyChrome.secondaryText,
                    ),
                    children: [
                      const TextSpan(text: 'Date: '),
                      TextSpan(
                        text: dateLabel,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: '  Time: '),
                      TextSpan(
                        text: timeLabel,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QtyControl(
            quantity: quantity,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleQtyBtn(
          asset: 'assets/images/png/minus-icon.png',
          filled: false,
          onTap: onDecrement,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$quantity',
            style: WaUi.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        _CircleQtyBtn(
          asset: 'assets/images/png/plus-icon.png',
          filled: true,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _CircleQtyBtn extends StatelessWidget {
  final String asset;
  final bool filled;
  final VoidCallback onTap;

  const _CircleQtyBtn({
    required this.asset,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.black : BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Image.asset(
              asset,
              width: 12,
              height: 12,
              color: filled ? Colors.white : Colors.black,
              errorBuilder: (_, __, ___) => Icon(
                filled ? Icons.add : Icons.remove,
                size: 16,
                color: filled ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceBookingSuccessScreen extends StatelessWidget {
  final String bookingCode;
  final String? orderId;
  final String? customerUsername;
  final String businessUsername;
  final int totalServices;
  final double totalAmount;
  final String? currency;

  const ServiceBookingSuccessScreen({
    super.key,
    required this.bookingCode,
    this.orderId,
    this.customerUsername,
    required this.businessUsername,
    required this.totalServices,
    required this.totalAmount,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final customer = (customerUsername ?? '').trim().isNotEmpty
        ? '@${customerUsername!.trim().replaceFirst('@', '')}'
        : '—';
    final business = businessUsername.trim().isNotEmpty
        ? (businessUsername.startsWith('@')
            ? businessUsername
            : '@$businessUsername')
        : '—';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Success'),
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
                      'Booking Request Sent',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Your booking request has been sent to the business. You'll be notified once the business confirms your booking.",
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: 14,
                        color: BarqodyChrome.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(height: 1, color: BarqodyChrome.divider),
                    _DetailRow(label: 'Booking', value: bookingCode),
                    _DetailRow(label: 'Customer', value: customer),
                    _DetailRow(label: 'Business', value: business),
                    _DetailRow(
                      label: 'Total Services',
                      value: '$totalServices',
                    ),
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
                    label: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (orderId != null) ...[
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'View Booking',
                      filled: false,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
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

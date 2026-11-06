import 'package:tapni_app/utils/app_page_transitions.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/screens/payments/payment_detail_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/order_ui.dart';

import 'package:tapni_app/l10n/app_localizations.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isBusinessView;

  /// Optional JWT from website WebView shopper session (overrides app token).
  final String? accessToken;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.isBusinessView,
    this.accessToken,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _repo = CatalogRepo();
  CatalogOrder? _order;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final result = await _repo.getOrderById(
      widget.orderId,
      accessToken: widget.accessToken,
    );
    if (!mounted) return;
    setState(() {
      _order = result.order;
      _loadFailed = result.failed;
      _isLoading = false;
    });
    // Clear unread badge when a business opens the order.
    final loaded = result.order;
    if (widget.isBusinessView &&
        loaded != null &&
        !loaded.isRead &&
        loaded.id.isNotEmpty) {
      unawaited(_repo.markOrderRead(loaded.id));
    }
  }

  Future<void> _refundPaidOrder() async {
    if (_order == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue full refund?'),
        content: const Text(
          'This refunds the customer to their original payment method via Stripe. Duplicate refunds are blocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isUpdating = true);
    final res = await PaymentRepo().refundOrder(
      orderId: _order!.id,
      idempotencyKey: 'refund_order_${_order!.id}_full',
    );
    if (!mounted) return;
    setState(() => _isUpdating = false);
    showAppToast(
          context,
          res.success
                  ? (res.message ?? 'Refund submitted')
                  : PaymentDisplay.sanitizeError(
                      res.message,
                      fallback: 'Refund failed',
                    ),
          kind: res.success ? AppToastKind.success : AppToastKind.error,
        );
    if (res.success) await _loadOrder();
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (_order == null) return;
    setState(() => _isUpdating = true);
    final res = await _repo.updateOrderStatus(
      _order!.id,
      CatalogHelper.statusApiValue(status),
    );
    if (!mounted) return;
    setState(() => _isUpdating = false);
    if (res.success) {
      await _loadOrder();
      if (mounted) {
        showAppToast(
              context,
              context.l10n.statusUpdatedTo(
                        CatalogHelper.statusLabel(status, context.l10n),
                      ),
              kind: AppToastKind.success,
            );
      }
    } else {
      showAppToast(
            context,
            res.message ?? context.l10n.failedToUpdateStatus,
            kind: AppToastKind.error,
          );
    }
  }

  void _viewProfile({required String? userId, required String? username}) {
    if (userId == null && (username == null || username.isEmpty)) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ScannedProfileScreen(
          user: userId,
          username: username,
        ),
      ),
    );
  }

  String _titleFor(CatalogOrder order) {
    final kind = order.kind;
    final noun = (kind == 'appointment' || kind == 'stay') ? 'Booking' : 'Order';
    if (order.hasToken) return '$noun #${order.tokenNumber}';
    return noun;
  }

  int _totalItems(CatalogOrder order) =>
      order.items.fold<int>(0, (sum, i) => sum + i.quantity);

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-${local.year}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('h:mm a').format(local);
  }

  String _orderDate(CatalogOrder order) {
    if (order.createdAt != null) return _formatDate(order.createdAt!);
    if (order.bookingDate != null && order.bookingDate!.isNotEmpty) {
      return order.bookingDate!;
    }
    return '—';
  }

  String _orderTime(CatalogOrder order) {
    if (order.createdAt != null) return _formatTime(order.createdAt!);
    if (order.bookingTime != null && order.bookingTime!.isNotEmpty) {
      return order.bookingTime!;
    }
    return '—';
  }

  String _bookingDateLabel(CatalogOrder order) {
    if (order.isStay) {
      final cin = order.checkInDate.trim();
      if (cin.isEmpty) return _orderDate(order);
      try {
        return DateFormat('MMM d, yyyy').format(DateTime.parse(cin));
      } catch (_) {
        return cin;
      }
    }
    final raw = order.bookingDate;
    if (raw == null || raw.isEmpty) return _orderDate(order);
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _bookingTimeLabel(CatalogOrder order) {
    if (order.isStay) {
      final cout = order.checkOutDate.trim();
      if (cout.isEmpty) return '—';
      try {
        return DateFormat('MMM d, yyyy').format(DateTime.parse(cout));
      } catch (_) {
        return cout;
      }
    }
    final raw = order.bookingTime;
    if (raw == null || raw.isEmpty) return _orderTime(order);
    return raw;
  }

  String _prettyDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '—';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(v));
    } catch (_) {
      return v;
    }
  }

  Color _avatarColor(String seed) {
    if (seed.isEmpty) return WaUi.avatarPalette.last;
    return WaUi.avatarPalette[seed.hashCode.abs() % WaUi.avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final showBusinessPendingActions =
        widget.isBusinessView &&
        order != null &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.held);
    final showBusinessConfirmedActions =
        widget.isBusinessView &&
        order != null &&
        order.status == OrderStatus.confirmed;
    final showCustomerActions = !widget.isBusinessView &&
        order != null &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed);
    final showStatusBanner = order != null &&
        !(widget.isBusinessView &&
            (order.status == OrderStatus.pending ||
                order.status == OrderStatus.held));

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (order != null)
              BarqodyTitleBar(title: _titleFor(order))
            else
              BarqodyTitleBar(title: context.l10n.orderDetails),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : order == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _loadFailed
                                      ? 'Couldn’t load this order'
                                      : context.l10n.orderNotFound,
                                  textAlign: TextAlign.center,
                                  style: WaUi.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _loadFailed
                                      ? 'Check your connection and try again.'
                                      : 'This order may have been removed, or it isn’t linked to your account.',
                                  textAlign: TextAlign.center,
                                  style: WaUi.body.copyWith(
                                    color: BarqodyChrome.secondaryText,
                                  ),
                                ),
                                if (_loadFailed) ...[
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: 160,
                                    child: PillButton(
                                      label: context.l10n.tryAgain,
                                      onPressed: _loadOrder,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Reference + status
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: OrderUi.cardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.hasToken
                                                ? '${order.nounLabel} #${order.tokenNumber}'
                                                : order.nounLabel,
                                            style: WaUi.toolsTitleOf(
                                              size: 20,
                                              weight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        OrderStatusBadgeLabeled(
                                          label: CatalogHelper.statusLabel(
                                            order.status,
                                            context.l10n,
                                          ),
                                          status: order.status,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      [
                                        order.kindLabel,
                                        if (order.catalogTypeLabel.isNotEmpty)
                                          order.catalogTypeLabel,
                                        if (order.orderTypeLabel.isNotEmpty &&
                                            (order.kind == 'order' ||
                                                order.kind == 'table'))
                                          order.orderTypeLabel,
                                      ].join(' · '),
                                      style: WaUi.caption.copyWith(
                                        color: OrderUi.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (order.publicPaymentRef.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Payment ref ${order.publicPaymentRef}',
                                        style: WaUi.caption.copyWith(
                                          color: OrderUi.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              // 2. Business / customer
                              OrderSectionCard(
                                title: widget.isBusinessView
                                    ? 'Customer'
                                    : 'Business',
                                child: _PersonRow(
                                  name: widget.isBusinessView
                                      ? (order.displayCustomerName.isNotEmpty
                                          ? order.displayCustomerName
                                          : 'Guest')
                                      : order.businessName,
                                  username: widget.isBusinessView
                                      ? order.customerUsername
                                      : order.businessUsername,
                                  subtitle: widget.isBusinessView &&
                                          order.guestPhone.trim().isNotEmpty
                                      ? order.guestPhone.trim()
                                      : null,
                                  badge: widget.isBusinessView && order.isGuest
                                      ? 'Guest'
                                      : null,
                                  photoUrl: widget.isBusinessView
                                      ? order.customerPhoto
                                      : order.businessPhoto,
                                  avatarColor: _avatarColor(
                                    widget.isBusinessView
                                        ? order.displayCustomerName
                                        : order.businessName,
                                  ),
                                  onTap: () {
                                    final id = widget.isBusinessView
                                        ? order.customerId
                                        : order.businessId;
                                    final uname = widget.isBusinessView
                                        ? order.customerUsername
                                        : order.businessUsername;
                                    if (id.trim().isEmpty &&
                                        uname.trim().isEmpty) {
                                      return;
                                    }
                                    _viewProfile(
                                      userId: id.trim().isEmpty ? null : id,
                                      username: uname,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              // 3. Schedule (appointments / stays / tables)
                              if (order.isAppointment ||
                                  order.isStay ||
                                  order.isTable) ...[
                                _WhenCard(
                                  order: order,
                                  prettyDate: _prettyDate,
                                ),
                                const SizedBox(height: 14),
                              ],
                              // 4. Items / services
                              OrderSectionCard(
                                title: order.isStay
                                    ? 'Rooms'
                                    : (order.isAppointment
                                        ? 'Services'
                                        : 'Items'),
                                trailing: Text(
                                  '${_totalItems(order)}',
                                  style: WaUi.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: OrderUi.muted,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                        i < order.items.length;
                                        i++) ...[
                                      if (i > 0)
                                        const Divider(
                                          height: 1,
                                          color: BarqodyChrome.divider,
                                        ),
                                      _OrderItemRow(
                                        item: order.items[i],
                                        currency: order.currency,
                                        dateLabel: _bookingDateLabel(order),
                                        timeLabel: _bookingTimeLabel(order),
                                        dateCaption: order.isStay
                                            ? 'Check-in'
                                            : 'Date',
                                        timeCaption: order.isStay
                                            ? 'Check-out'
                                            : 'Time',
                                        showSchedule: false,
                                      ),
                                      if (order.items[i].notes
                                          .trim()
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 48,
                                            bottom: 10,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Note: ${order.items[i].notes}',
                                              style: WaUi.caption.copyWith(
                                                color: OrderUi.muted,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              // 5. Fulfillment / delivery / table
                              if (order.fulfillmentAddress.isNotEmpty ||
                                  order.fulfillmentNotes.isNotEmpty ||
                                  order.tableToken.isNotEmpty ||
                                  order.orderTypeLabel.isNotEmpty) ...[
                                OrderSectionCard(
                                  title: order.kind == 'table'
                                      ? 'Table details'
                                      : (order.orderType == 'delivery'
                                          ? 'Delivery'
                                          : 'Fulfillment'),
                                  child: Column(
                                    children: [
                                      if (order.orderTypeLabel.isNotEmpty)
                                        OrderDetailRow(
                                          label: 'Type',
                                          value: order.orderTypeLabel,
                                        ),
                                      if (order.tableToken.isNotEmpty)
                                        OrderDetailRow(
                                          label: 'Table',
                                          value: order.tableToken,
                                        ),
                                      if (order.fulfillmentAddress.isNotEmpty)
                                        OrderDetailRow(
                                          label: 'Address',
                                          value: order.fulfillmentAddress,
                                        ),
                                      if (order.fulfillmentNotes.isNotEmpty)
                                        OrderDetailRow(
                                          label: 'Notes',
                                          value: order.fulfillmentNotes,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              // 6. Pricing + payment
                              OrderSectionCard(
                                title: 'Payment summary',
                                child: Column(
                                  children: [
                                    OrderDetailRow(
                                      label: 'Subtotal',
                                      value: formatMoney(
                                        order.subtotalAmount,
                                        currency: order.currency,
                                      ),
                                    ),
                                    if (order.couponDiscountAmount > 0)
                                      OrderDetailRow(
                                        label: order.couponCode.isNotEmpty
                                            ? 'Coupon (${order.couponCode})'
                                            : 'Coupon',
                                        value:
                                            '−${formatMoney(order.couponDiscountAmount, currency: order.currency)}',
                                      ),
                                    if (order.pointsDiscountAmount > 0)
                                      OrderDetailRow(
                                        label: order.pointsRedeemed > 0
                                            ? 'Points (${order.pointsRedeemed})'
                                            : 'Points',
                                        value:
                                            '−${formatMoney(order.pointsDiscountAmount, currency: order.currency)}',
                                      ),
                                    OrderDetailRow(
                                      label: 'Total',
                                      value: formatMoney(
                                        order.totalAmount,
                                        currency: order.currency,
                                      ),
                                    ),
                                    OrderDetailRow(
                                      label: 'Payment',
                                      value: order.paymentLabel,
                                    ),
                                    if (order.hasRefund) ...[
                                      OrderDetailRow(
                                        label: 'Refund status',
                                        value: order.refundStatus
                                            .replaceAll('_', ' '),
                                      ),
                                      if (order.refundedAmount > 0)
                                        OrderDetailRow(
                                          label: 'Refunded',
                                          value: formatMoney(
                                            order.refundedAmount,
                                            currency: order.currency,
                                          ),
                                        ),
                                    ],
                                    if (order.publicPaymentRef.isNotEmpty)
                                      OrderDetailRow(
                                        label: 'Reference',
                                        value: order.publicPaymentRef,
                                      ),
                                    OrderDetailRow(
                                      label: 'Placed',
                                      value:
                                          '${_orderDate(order)} · ${_orderTime(order)}',
                                    ),
                                    if (order.loyaltyReward != null)
                                      OrderDetailRow(
                                        label: 'Rewards',
                                        value:
                                            order.loyaltyReward!.summaryLabel,
                                      ),
                                    if (order.paymentMethod.toLowerCase() ==
                                            'online' &&
                                        order.id.isNotEmpty)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              AppPageRoute(
                                                builder: (_) =>
                                                    PaymentDetailScreen(
                                                  orderId: order.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'View payment details',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              // 7. Timeline
                              if (order.statusHistory.isNotEmpty) ...[
                                OrderSectionCard(
                                  title: 'Status timeline',
                                  child: OrderTimeline(
                                    events: order.statusHistory,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (showStatusBanner)
                                _StatusBanner(
                                  status: order.status,
                                  noun: order.nounLabel,
                                  isBusinessView: widget.isBusinessView,
                                ),
                            ],
                          ),
                        ),
            ),
            if (showBusinessPendingActions)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PillButton(
                        label: 'Confirm',
                        enabled: !_isUpdating,
                        onPressed: () =>
                            _updateStatus(OrderStatus.confirmed),
                      ),
                      const SizedBox(height: 10),
                      _OutlineActionButton(
                        label: 'Cancel',
                        onPressed: _isUpdating
                            ? null
                            : () => _updateStatus(OrderStatus.cancelled),
                      ),
                    ],
                  ),
                ),
              ),
            if (showBusinessConfirmedActions)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineActionButton(
                              label: 'Customer Missed',
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(OrderStatus.noShow),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OutlineActionButton(
                              label: 'Cancel',
                              destructive: true,
                              onPressed: _isUpdating
                                  ? null
                                  : () =>
                                      _updateStatus(OrderStatus.cancelled),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PillButton(
                        label: 'Mark as Complete',
                        enabled: !_isUpdating,
                        onPressed: () =>
                            _updateStatus(OrderStatus.completed),
                      ),
                      if (order.isGenuinelyPaid ||
                          order.paymentStatus == 'paid' ||
                          order.paymentStatus == 'partially_refunded') ...[
                        const SizedBox(height: 10),
                        _OutlineActionButton(
                          label: 'Issue full refund',
                          destructive: true,
                          onPressed: _isUpdating ? null : _refundPaidOrder,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (showCustomerActions)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: PillButton(
                    label: (order.kind == 'appointment' ||
                            order.kind == 'stay')
                        ? 'Cancel booking'
                        : 'Cancel order',
                    filled: false,
                    enabled: !_isUpdating,
                    onPressed: () => _updateStatus(OrderStatus.cancelled),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CatalogOrderLineItem item;
  final String currency;
  final String dateLabel;
  final String timeLabel;
  final String dateCaption;
  final String timeCaption;
  final bool showSchedule;

  const _OrderItemRow({
    required this.item,
    required this.currency,
    required this.dateLabel,
    required this.timeLabel,
    this.dateCaption = 'Date',
    this.timeCaption = 'Time',
    this.showSchedule = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${item.quantity} x',
              style: WaUi.body.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.imageUrl.trim().isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: BarqodyChrome.fieldFill,
                        child: const Icon(
                          Icons.image_outlined,
                          color: BarqodyChrome.bodyText,
                          size: 24,
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: BarqodyChrome.fieldFill,
                      child: const Icon(
                        Icons.image_outlined,
                        color: BarqodyChrome.bodyText,
                        size: 24,
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
                  style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                if (item.hasDiscountSnapshot) ...[
                  Text(
                    formatMoney(item.listPrice!, currency: currency),
                    style: WaUi.body.copyWith(
                      fontSize: 12,
                      color: BarqodyChrome.secondaryText,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  formatMoney(item.price, currency: currency),
                  style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (showSchedule) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: WaUi.body.copyWith(
                        fontSize: 12,
                        color: BarqodyChrome.secondaryText,
                      ),
                      children: [
                        TextSpan(text: '$dateCaption: '),
                        TextSpan(
                          text: dateLabel,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '  $timeCaption: '),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhenCard extends StatelessWidget {
  final CatalogOrder order;
  final String Function(String raw) prettyDate;

  const _WhenCard({
    required this.order,
    required this.prettyDate,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Type', order.kindLabel),
    ];
    if (order.isStay) {
      rows.add(('Check-in', prettyDate(order.checkInDate)));
      rows.add(('Check-out', prettyDate(order.checkOutDate)));
      if (order.resourceNames.isNotEmpty) {
        rows.add(('Room', order.resourceNames.join(', ')));
      }
    } else if (order.isAppointment) {
      rows.add(('Date', prettyDate(order.bookingDate ?? '')));
      rows.add((
        'Time',
        (order.bookingTime ?? '').trim().isEmpty
            ? '—'
            : order.bookingTime!.trim(),
      ));
      if (order.resourceNames.isNotEmpty) {
        rows.add(('Specialist', order.resourceNames.join(', ')));
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            order.isStay ? 'Stay' : 'When',
            style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _SummaryRow(label: rows[i].$1, value: rows[i].$2),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
        ),
        const Spacer(),
        Text(
          value,
          style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  final String username;
  final String? subtitle;
  final String? badge;
  final String? photoUrl;
  final Color avatarColor;
  final VoidCallback onTap;

  const _PersonRow({
    required this.name,
    required this.username,
    this.subtitle,
    this.badge,
    this.photoUrl,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : context.l10n.order;
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final phone = (subtitle ?? '').trim();
    final canOpenProfile = username.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: canOpenProfile ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                child: hasPhoto
                    ? null
                    : Text(initial, style: WaUi.avatarInitial),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if ((badge ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BarqodyChrome.scaffold,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: BarqodyChrome.divider,
                              ),
                            ),
                            child: Text(
                              badge!.trim(),
                              style: WaUi.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (canOpenProfile)
                Icon(
                  Icons.chevron_right_rounded,
                  color: BarqodyChrome.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  const _OutlineActionButton({
    required this.label,
    this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : Colors.black;
    return SizedBox(
      height: WaUi.primaryButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WaUi.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  final String noun;
  final bool isBusinessView;

  const _StatusBanner({
    required this.status,
    required this.noun,
    required this.isBusinessView,
  });

  ({String title, String description, Widget icon}) _content(
    AppLocalizations l10n,
  ) {
    final biz = isBusinessView;
    final n = noun;
    switch (status) {
      case OrderStatus.completed:
        return (
          title: '$n complete',
          description: biz
              ? 'This $n was marked complete'
              : 'Your $n has been completed successfully',
          icon: _CircleIcon(
            child: Image.asset(
              'assets/images/png/check-icon-1.png',
              width: 18,
              height: 18,
              color: Colors.white,
              errorBuilder: (_, _, _) => const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      case OrderStatus.cancelled:
        return (
          title: '$n cancelled',
          description: biz
              ? 'This $n was cancelled'
              : 'Your $n has been cancelled',
          icon: _CircleIcon(
            child: Image.asset(
              'assets/images/png/cancel-icon.png',
              width: 16,
              height: 16,
              color: Colors.white,
              errorBuilder: (_, _, _) => Image.asset(
                CircleCloseButton.asset,
                width: 16,
                height: 16,
                color: Colors.white,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.cancel_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      case OrderStatus.noShow:
        return (
          title: '$n missed',
          description: biz
              ? 'Customer did not attend this appointment'
              : "You didn't attend your scheduled appointment",
          icon: Image.asset(
            'assets/images/png/order-cance.png',
            width: 48,
            height: 48,
            errorBuilder: (_, _, _) => const _CircleIcon(
              outlined: true,
              child: Icon(
                Icons.block_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        );
      case OrderStatus.confirmed:
        return (
          title: '$n confirmed',
          description: biz
              ? 'You confirmed this $n'
              : 'Your $n has been confirmed by the business',
          icon: _CircleIcon(
            child: Image.asset(
              'assets/images/png/check-icon-1.png',
              width: 18,
              height: 18,
              color: Colors.white,
              errorBuilder: (_, _, _) => const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      case OrderStatus.held:
        return (
          title: 'Request held',
          description: biz
              ? 'Soft request — accept or decline when ready'
              : 'Your request is held until the business confirms',
          icon: Image.asset(
            'assets/images/png/bag-icon.png',
            width: 56,
            height: 56,
            errorBuilder: (_, _, _) => const Icon(
              Icons.hourglass_empty_rounded,
              size: 56,
              color: Colors.black,
            ),
          ),
        );
      case OrderStatus.pending:
        return (
          title: '$n pending',
          description: biz
              ? 'Waiting for you to confirm this $n'
              : 'Your $n request is waiting for confirmation',
          icon: Image.asset(
            'assets/images/png/bag-icon.png',
            width: 56,
            height: 56,
            errorBuilder: (_, _, _) => const Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: Colors.black,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _content(context.l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          content.icon,
          const SizedBox(height: 14),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: 18,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          if (content.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content.description,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final Widget child;
  final bool outlined;

  const _CircleIcon({required this.child, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : Colors.black,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: Colors.black, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

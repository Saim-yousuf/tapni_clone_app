import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

import 'package:tapni_app/l10n/app_localizations.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isBusinessView;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.isBusinessView,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _repo = CatalogRepo();
  CatalogOrder? _order;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await _repo.getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.statusUpdatedTo(
                CatalogHelper.statusLabel(status, context.l10n),
              ),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToUpdateStatus)),
      );
    }
  }

  void _viewProfile({required String? userId, required String? username}) {
    if (userId == null && (username == null || username.isEmpty)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannedProfileScreen(
          user: userId,
          username: username,
        ),
      ),
    );
  }

  String _titleFor(CatalogOrder order) {
    if (order.hasToken) return 'Booking #BK${order.tokenNumber}';
    final id = order.id;
    final short = id.length > 6 ? id.substring(id.length - 6) : id;
    return 'Booking #$short';
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
    final raw = order.bookingDate;
    if (raw == null || raw.isEmpty) return _orderDate(order);
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _bookingTimeLabel(CatalogOrder order) {
    final raw = order.bookingTime;
    if (raw == null || raw.isEmpty) return _orderTime(order);
    return raw;
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
        order.status == OrderStatus.pending;
    final showBusinessConfirmedActions =
        widget.isBusinessView &&
        order != null &&
        order.status == OrderStatus.confirmed;
    final showCustomerActions = !widget.isBusinessView &&
        order != null &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed);
    final showStatusBanner = order != null &&
        !(widget.isBusinessView && order.status == OrderStatus.pending);

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
                      ? Center(child: Text(context.l10n.orderNotFound))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...order.items.map(
                                (item) => Column(
                                  children: [
                                    _OrderItemRow(
                                      item: item,
                                      currency: order.currency,
                                      dateLabel: _bookingDateLabel(order),
                                      timeLabel: _bookingTimeLabel(order),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: BarqodyChrome.divider,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SummaryCard(
                                order: order,
                                totalItems: _totalItems(order),
                                orderDate: _orderDate(order),
                                orderTime: _orderTime(order),
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                color: BarqodyChrome.divider,
                              ),
                              _PersonRow(
                                name: widget.isBusinessView
                                    ? order.customerName
                                    : order.businessName,
                                username: widget.isBusinessView
                                    ? order.customerUsername
                                    : order.businessUsername,
                                photoUrl: widget.isBusinessView
                                    ? order.customerPhoto
                                    : order.businessPhoto,
                                avatarColor: _avatarColor(
                                  widget.isBusinessView
                                      ? order.customerName
                                      : order.businessName,
                                ),
                                onTap: () => _viewProfile(
                                  userId: widget.isBusinessView
                                      ? order.customerId
                                      : order.businessId,
                                  username: widget.isBusinessView
                                      ? order.customerUsername
                                      : order.businessUsername,
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: BarqodyChrome.divider,
                              ),
                              const SizedBox(height: 24),
                              if (showStatusBanner)
                                _StatusBanner(
                                  status: order.status,
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
                    ],
                  ),
                ),
              ),
            if (showCustomerActions)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _OutlineActionButton(
                          label: 'Cancel',
                          onPressed: _isUpdating
                              ? null
                              : () => _updateStatus(OrderStatus.cancelled),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PillButton(
                          label: 'Reschedule',
                          enabled: !_isUpdating,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reschedule is not available yet. Please cancel and book again.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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

class _OrderItemRow extends StatelessWidget {
  final CatalogOrderLineItem item;
  final String currency;
  final String dateLabel;
  final String timeLabel;

  const _OrderItemRow({
    required this.item,
    required this.currency,
    required this.dateLabel,
    required this.timeLabel,
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
                          Icons.spa_outlined,
                          color: BarqodyChrome.bodyText,
                          size: 24,
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: BarqodyChrome.fieldFill,
                      child: const Icon(
                        Icons.spa_outlined,
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
                Text(
                  formatMoney(item.price, currency: currency),
                  style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
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
          Icon(
            Icons.chevron_right_rounded,
            color: BarqodyChrome.secondaryText,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CatalogOrder order;
  final int totalItems;
  final String orderDate;
  final String orderTime;

  const _SummaryCard({
    required this.order,
    required this.totalItems,
    required this.orderDate,
    required this.orderTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Booking',
            value: order.hasToken ? '#BK${order.tokenNumber}' : '—',
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Order Date', value: orderDate),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Order Time', value: orderTime),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Total services', value: '$totalItems'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: BarqodyChrome.divider),
          ),
          Row(
            children: [
              Text(
                'Total amount',
                style: WaUi.body.copyWith(
                  color: BarqodyChrome.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                formatMoney(order.totalAmount, currency: order.currency),
                style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
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
  final String? photoUrl;
  final Color avatarColor;
  final VoidCallback onTap;

  const _PersonRow({
    required this.name,
    required this.username,
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

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
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
                    Text(
                      displayName,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
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
  final bool isBusinessView;

  const _StatusBanner({
    required this.status,
    required this.isBusinessView,
  });

  ({String title, String description, Widget icon}) _content(
    AppLocalizations l10n,
  ) {
    switch (status) {
      case OrderStatus.completed:
        return (
          title: 'Booking Complete',
          description: 'Your booking has been completed successfully',
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
          title: 'Booking Cancelled',
          description: 'Your booking has been cancelled',
          icon: _CircleIcon(
            child: Image.asset(
              'assets/images/png/cancel-icon.png',
              width: 16,
              height: 16,
              color: Colors.white,
              errorBuilder: (_, _, _) => const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      case OrderStatus.noShow:
        return (
          title: 'Booking Missed',
          description: "You didn't attend your scheduled appointment",
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
          title: 'Booking Confirmed',
          description: 'Your booking has been confirmed by the business',
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
      case OrderStatus.pending:
        return (
          title: 'Booking Pending',
          description: 'Your booking request is waiting for confirmation',
          icon: Image.asset(
            'assets/images/png/bag-icon.png',
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) => const Icon(
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

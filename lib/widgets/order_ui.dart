import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/connection_error_state.dart';

/// Shared BarQody order / booking chrome for customer + business screens.
class OrderUi {
  OrderUi._();

  static const Color border = Color(0xFFE5E5EA);
  static const Color muted = Color(0xFF8E8E93);
  static const double radius = 16;
  static const double sidePad = 20;

  static BoxDecoration cardDecoration({Color? fill}) => BoxDecoration(
        color: fill ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );

  static Color avatarColor(String seed) {
    if (seed.isEmpty) return WaUi.avatarPalette.last;
    return WaUi.avatarPalette[seed.hashCode.abs() % WaUi.avatarPalette.length];
  }

  static String formatShortDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    return DateFormat('MMM d, yyyy').format(d);
  }

  static String formatShortDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d · h:mm a').format(dt.toLocal());
  }

  static String statusHeadline(CatalogOrder order) {
    final noun = order.nounLabel;
    switch (order.status) {
      case OrderStatus.held:
        return '$noun held';
      case OrderStatus.pending:
        return '$noun pending';
      case OrderStatus.confirmed:
        return '$noun confirmed';
      case OrderStatus.completed:
        return '$noun complete';
      case OrderStatus.cancelled:
        return '$noun cancelled';
      case OrderStatus.noShow:
        return '$noun missed';
    }
  }

  static String statusChipLabel(OrderStatus status, {String? l10nPending}) {
    switch (status) {
      case OrderStatus.held:
        return 'Held';
      case OrderStatus.pending:
        return l10nPending ?? 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.noShow:
        return 'Missed';
    }
  }
}

class OrderStatusBadgeLabeled extends StatelessWidget {
  const OrderStatusBadgeLabeled({
    super.key,
    required this.label,
    required this.status,
    this.compact = false,
  });

  final String label;
  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    late Color fg;
    late Color bg;
    switch (status) {
      case OrderStatus.held:
      case OrderStatus.pending:
        fg = const Color(0xFF9A6700);
        bg = const Color(0xFFFFF4D6);
        break;
      case OrderStatus.confirmed:
        fg = const Color(0xFF1B7F4E);
        bg = const Color(0xFFE8F5EE);
        break;
      case OrderStatus.completed:
        fg = Colors.black;
        bg = const Color(0xFFF2F2F7);
        break;
      case OrderStatus.cancelled:
      case OrderStatus.noShow:
        fg = const Color(0xFFC62828);
        bg = const Color(0xFFFDECEA);
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: WaUi.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

class OrderFilterChip extends StatelessWidget {
  const OrderFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.black : BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selected ? Colors.black : OrderUi.border,
              ),
            ),
            child: Text(
              label,
              style: WaUi.caption.copyWith(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.receipt_long_rounded,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: OrderUi.muted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderErrorState extends StatelessWidget {
  const OrderErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        ConnectionErrorState(
          message: 'Couldn’t load orders',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class OrderSectionCard extends StatelessWidget {
  const OrderSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: OrderUi.cardDecoration(fill: BarqodyChrome.fieldFill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class OrderDetailRow extends StatelessWidget {
  const OrderDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: WaUi.body.copyWith(
                color: BarqodyChrome.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.order,
    required this.isBusinessView,
    required this.statusLabel,
    required this.onTap,
  });

  final CatalogOrder order;
  final bool isBusinessView;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = isBusinessView
        ? (order.displayCustomerName.isNotEmpty
            ? order.displayCustomerName
            : (order.isGuest ? 'Guest' : 'Customer'))
        : (order.businessName.isNotEmpty ? order.businessName : 'Business');
    final photo = isBusinessView ? order.customerPhoto : order.businessPhoto;
    final metaBits = <String>[
      order.listReference,
      if (order.hasToken) order.kindLabel,
      if (order.catalogTypeLabel.isNotEmpty &&
          order.catalogType != 'catalog')
        order.catalogTypeLabel,
    ];
    final amount = formatMoney(order.totalAmount, currency: order.currency);
    final when = order.whenLine.isNotEmpty
        ? order.whenLine
        : OrderUi.formatShortDate(order.createdAt);
    final payHint = order.listPaymentHint;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: OrderUi.avatarColor(title),
                    backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                    child: hasPhoto
                        ? null
                        : Text(initial, style: WaUi.avatarInitial),
                  ),
                  if (isBusinessView && !order.isRead)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF6B6B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.listTitle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          amount,
                          style: WaUi.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metaBits.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        color: OrderUi.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.itemsSummary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        order.itemsSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.bodyText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OrderStatusBadgeLabeled(
                          label: statusLabel,
                          status: order.status,
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            when,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.caption.copyWith(
                              color: OrderUi.muted,
                            ),
                          ),
                        ),
                        if (payHint.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: payHint == 'Pay now'
                                  ? Colors.black
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: payHint == 'Pay now'
                                    ? Colors.black
                                    : OrderUi.border,
                              ),
                            ),
                            child: Text(
                              payHint,
                              style: WaUi.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: payHint == 'Pay now'
                                    ? Colors.white
                                    : OrderUi.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
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

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.events});

  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'No status history yet.',
        style: WaUi.caption.copyWith(color: OrderUi.muted),
      );
    }
    final sorted = [...events]..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i != sorted.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: OrderUi.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(sorted[i]),
                        style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        OrderUi.formatShortDateTime(sorted[i].createdAt),
                        style: WaUi.caption.copyWith(color: OrderUi.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _label(OrderStatusEvent e) {
    final to = e.to.replaceAll('_', ' ');
    if (to.isEmpty) return 'Updated';
    return to[0].toUpperCase() + to.substring(1);
  }
}

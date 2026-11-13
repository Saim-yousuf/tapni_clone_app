import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/order_ui.dart';

/// Customer order layout helpers — Barqody light chrome (not dark mock).
class Cx {
  Cx._();

  static const Color bg = BarqodyChrome.scaffold;
  static const Color surface = Color(0xFFF6F6F4);
  static const Color surface2 = BarqodyChrome.fieldFill;
  static const Color hairline = Color(0xFFE8E8E4);
  static const Color text = Colors.black;
  static const Color muted = BarqodyChrome.secondaryText;
  /// Primary accent follows Barqody black, not gold.
  static const Color accent = Colors.black;
  static const Color accentSoft = Color(0xFFF2F2F7);
  static const Color green = Color(0xFF1B5E3B);
  static const Color greenSoft = Color(0xFFE7F4EA);
  static const Color blue = Color(0xFF2F6FED);
  static const Color blueSoft = Color(0xFFE8EEF5);
  static const Color orange = Color(0xFF8A4B12);
  static const Color orangeSoft = Color(0xFFFFF1E0);
  static const Color red = Color(0xFFB42318);
  static const Color redSoft = Color(0xFFFCECEC);

  /// Back-compat aliases used by older call sites.
  static const Color gold = accent;
  static const Color goldSoft = accentSoft;

  static (Color bg, Color fg) statusColors(OrderStatus status) {
    return switch (status) {
      OrderStatus.completed => (greenSoft, green),
      OrderStatus.cancelled || OrderStatus.noShow => (redSoft, red),
      OrderStatus.outForDelivery => (blueSoft, blue),
      OrderStatus.confirmed => (accentSoft, accent),
      OrderStatus.held || OrderStatus.pending => (orangeSoft, orange),
    };
  }

  static String statusLabel(CatalogOrder order) {
    switch (order.status) {
      case OrderStatus.held:
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return order.isDelivery ? 'On the way' : 'Ready';
      case OrderStatus.completed:
        return order.isDelivery ? 'Delivered' : 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.noShow:
        return order.isDelivery ? 'Not delivered' : 'Not collected';
    }
  }
}

class CxStatusChip extends StatelessWidget {
  final String label;
  final OrderStatus status;

  const CxStatusChip({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = Cx.statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: WaUi.caption.copyWith(
          color: c.$2,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class CxOrderListCard extends StatelessWidget {
  final CatalogOrder order;
  final String statusLabel;
  final VoidCallback onTap;

  const CxOrderListCard({
    super.key,
    required this.order,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        order.businessName.isNotEmpty ? order.businessName : 'Business';
    final photo = order.businessPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final thumb = order.items.isNotEmpty ? order.items.first.imageUrl : null;
    final hasThumb = thumb != null && thumb.trim().isNotEmpty;
    final amount = formatMoney(order.totalAmount, currency: order.currency);
    final when = order.createdAt != null
        ? DateFormat('MMM d · h:mm a').format(order.createdAt!.toLocal())
        : OrderUi.formatShortDate(order.createdAt);
    final ref = order.listReference;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hasThumb
                      ? Image.network(
                          thumb.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackThumb(
                            hasPhoto,
                            photo,
                            initial,
                          ),
                        )
                      : _fallbackThumb(hasPhoto, photo, initial),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ref.isNotEmpty ? ref : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              color: Cx.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          amount,
                          style: WaUi.body.copyWith(
                            color: Cx.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        color: Cx.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CxStatusChip(
                          label: statusLabel,
                          status: order.status,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            when,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.caption.copyWith(
                              color: Cx.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
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

  Widget _fallbackThumb(bool hasPhoto, String? photo, String initial) {
    if (hasPhoto) {
      return Image.network(
        photo!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialBox(initial),
      );
    }
    return _initialBox(initial);
  }

  Widget _initialBox(String initial) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          initial,
          style: WaUi.body.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class CxPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool gold;
  final bool outlined;

  const CxPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.gold = true,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final filled = gold && !outlined;
    final bg = outlined
        ? Colors.transparent
        : (filled ? Colors.black : Cx.surface2);
    final fg = outlined || !filled ? Colors.black : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 1.4),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CxProgressStep {
  final String title;
  final IconData icon;
  final bool done;
  final bool active;
  final bool bad;

  const CxProgressStep({
    required this.title,
    required this.icon,
    this.done = false,
    this.active = false,
    this.bad = false,
  });

  static List<CxProgressStep> forOrder(CatalogOrder order) {
    final status = order.status;
    final pending =
        status == OrderStatus.held || status == OrderStatus.pending;
    final confirmed = status == OrderStatus.confirmed;
    final onWay = status == OrderStatus.outForDelivery;
    final completed = status == OrderStatus.completed;
    final pastPreparing = confirmed || onWay || completed;
    final pastOnWay = onWay || completed;
    final bad =
        status == OrderStatus.cancelled || status == OrderStatus.noShow;
    final thirdTitle = order.isDelivery ? 'On the way' : 'Ready';
    final thirdIcon = order.isDelivery
        ? Icons.delivery_dining_rounded
        : Icons.storefront_rounded;
    final doneTitle = order.isDelivery ? 'Delivered' : 'Completed';

    if (bad) {
      return [
        const CxProgressStep(
          title: 'Placed',
          icon: Icons.receipt_long_rounded,
          done: true,
        ),
        CxProgressStep(
          title: status == OrderStatus.cancelled
              ? 'Cancelled'
              : (order.isDelivery ? 'Not delivered' : 'Not collected'),
          icon: Icons.close_rounded,
          done: true,
          bad: true,
          active: true,
        ),
      ];
    }

    return [
      CxProgressStep(
        title: 'Placed',
        icon: Icons.receipt_long_rounded,
        done: true,
        active: pending,
      ),
      CxProgressStep(
        title: 'Preparing',
        icon: Icons.restaurant_rounded,
        done: pastPreparing,
        active: confirmed,
      ),
      CxProgressStep(
        title: thirdTitle,
        icon: thirdIcon,
        done: pastOnWay,
        active: onWay,
      ),
      CxProgressStep(
        title: doneTitle,
        icon: Icons.check_rounded,
        done: completed,
      ),
    ];
  }

  static String captionFor(CatalogOrder order) {
    switch (order.status) {
      case OrderStatus.held:
      case OrderStatus.pending:
        return 'Waiting for the business to confirm';
      case OrderStatus.confirmed:
        final prep = order.prepTimeLabel;
        if (prep.isNotEmpty) return prep;
        return order.isDelivery
            ? 'Kitchen is preparing your order'
            : 'Being prepared for pickup';
      case OrderStatus.outForDelivery:
        return order.isDelivery
            ? 'Your order is on the way'
            : 'Your order is ready for pickup';
      case OrderStatus.completed:
        return order.isDelivery
            ? 'Your order has been delivered. Enjoy!'
            : 'Your order is complete. Enjoy!';
      case OrderStatus.cancelled:
        return 'This order was cancelled';
      case OrderStatus.noShow:
        return order.isDelivery
            ? 'Delivery couldn’t be completed'
            : 'You didn’t pick up';
    }
  }

  static String captionForBusiness(CatalogOrder order) {
    switch (order.status) {
      case OrderStatus.held:
      case OrderStatus.pending:
        return 'Confirm this order to start preparing';
      case OrderStatus.confirmed:
        final prep = order.prepTimeLabel;
        if (prep.isNotEmpty) return 'Preparing · $prep';
        return order.isDelivery
            ? 'Preparing — mark out for delivery next'
            : 'Preparing — mark ready when packed';
      case OrderStatus.outForDelivery:
        return order.isDelivery
            ? 'Out for delivery — mark delivered when done'
            : 'Ready — mark complete when collected';
      case OrderStatus.completed:
        return order.isDelivery ? 'Order delivered' : 'Order completed';
      case OrderStatus.cancelled:
        return 'Order cancelled';
      case OrderStatus.noShow:
        return order.isDelivery
            ? 'Marked not delivered'
            : 'Customer didn’t collect';
    }
  }

  static String statusLabelBusiness(CatalogOrder order) {
    switch (order.status) {
      case OrderStatus.held:
      case OrderStatus.pending:
        return 'Needs action';
      case OrderStatus.confirmed:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return order.isDelivery ? 'On the way' : 'Ready';
      case OrderStatus.completed:
        return order.isDelivery ? 'Delivered' : 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.noShow:
        return order.isDelivery ? 'Not delivered' : 'Not collected';
    }
  }
}

/// Business orders list card — customer-first, Barqody chrome.
class BizOrderListCard extends StatelessWidget {
  final CatalogOrder order;
  final String statusLabel;
  final VoidCallback onTap;

  const BizOrderListCard({
    super.key,
    required this.order,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = order.displayCustomerName.isNotEmpty
        ? order.displayCustomerName
        : (order.isGuest ? 'Guest' : 'Customer');
    final photo = order.customerPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final thumb = order.items.isNotEmpty ? order.items.first.imageUrl : null;
    final hasThumb = thumb != null && thumb.trim().isNotEmpty;
    final amount = formatMoney(order.totalAmount, currency: order.currency);
    final when = order.createdAt != null
        ? DateFormat('MMM d · h:mm a').format(order.createdAt!.toLocal())
        : OrderUi.formatShortDate(order.createdAt);
    final ref = order.listReference;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final type = order.isDelivery
        ? 'Delivery'
        : (order.isPickup ? 'Pickup' : order.orderTypeLabel);

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: hasThumb
                          ? Image.network(
                              thumb.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _bizThumb(hasPhoto, photo, initial),
                            )
                          : _bizThumb(hasPhoto, photo, initial),
                    ),
                  ),
                  if (!order.isRead)
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
                      children: [
                        Expanded(
                          child: Text(
                            ref.isNotEmpty ? ref : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          amount,
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        title,
                        if (type.isNotEmpty) type,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        color: Cx.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CxStatusChip(
                          label: statusLabel,
                          status: order.status,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            when,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.caption.copyWith(
                              color: Cx.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
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

  Widget _bizThumb(bool hasPhoto, String? photo, String initial) {
    if (hasPhoto) {
      return Image.network(
        photo!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: Colors.white,
          child: Center(
            child: Text(
              initial,
              style: WaUi.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          initial,
          style: WaUi.body.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class CxProgressBar extends StatelessWidget {
  final List<CxProgressStep> steps;
  final String caption;

  const CxProgressBar({
    super.key,
    required this.steps,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final allDone = steps.every((s) => s.done) && steps.isNotEmpty;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 17),
                    child: Container(
                      height: 2,
                      color: steps[i - 1].done || steps[i - 1].active
                          ? (steps[i - 1].bad
                              ? Cx.red
                              : (allDone ? Cx.green : Colors.black))
                          : const Color(0xFFE0E0E5),
                    ),
                  ),
                ),
              _CxNode(step: steps[i], allDone: allDone),
            ],
          ],
        ),
        if (caption.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: WaUi.caption.copyWith(
              color: Cx.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _CxNode extends StatefulWidget {
  final CxProgressStep step;
  final bool allDone;

  const _CxNode({required this.step, required this.allDone});

  @override
  State<_CxNode> createState() => _CxNodeState();
}

class _CxNodeState extends State<_CxNode>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.step.active && !widget.step.bad) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _CxNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    final should = widget.step.active && !widget.step.bad;
    if (should && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    } else if (!should && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final hot = step.done || step.active;
    final accent = step.bad
        ? Cx.red
        : (widget.allDone && step.done
            ? Cx.green
            : Colors.black);

    Widget circle;
    if (step.done && !step.active) {
      circle = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: step.bad ? Colors.white : accent,
          border: step.bad ? Border.all(color: accent, width: 1.8) : null,
        ),
        child: Icon(
          step.bad ? Icons.close_rounded : Icons.check_rounded,
          size: 18,
          color: step.bad ? accent : Colors.white,
        ),
      );
    } else if (step.active) {
      final core = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: accent, width: 2.2),
        ),
        child: Icon(step.icon, size: 17, color: accent),
      );
      final ctrl = _pulse;
      circle = ctrl == null
          ? core
          : SizedBox(
              width: 42,
              height: 42,
              child: AnimatedBuilder(
                animation: ctrl,
                builder: (_, __) {
                  final t = Curves.easeOut.transform(ctrl.value);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1 + t * 0.55,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: (1 - t) * 0.35),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      core,
                    ],
                  );
                },
              ),
            );
    } else {
      circle = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Cx.surface2,
          border: Border.all(color: const Color(0xFFE0E0E5)),
        ),
        child: Icon(step.icon, size: 16, color: const Color(0xFFC8C8CC)),
      );
    }

    return SizedBox(
      width: 68,
      child: Column(
        children: [
          SizedBox(height: 42, child: Center(child: circle)),
          const SizedBox(height: 8),
          Text(
            step.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WaUi.caption.copyWith(
              fontWeight: hot ? FontWeight.w800 : FontWeight.w600,
              color: hot ? Colors.black : const Color(0xFFB0B0B5),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

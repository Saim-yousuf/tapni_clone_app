import 'package:tapni_app/utils/app_page_transitions.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/repository/review_repo.dart';
import 'package:tapni_app/screens/catalog/stripe_checkout_screen.dart';
import 'package:tapni_app/screens/explore_cart_screen.dart';
import 'package:tapni_app/screens/help/help_center_screen.dart';
import 'package:tapni_app/screens/payments/payment_detail_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/review_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isBusinessView;
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
    final loaded = result.order;
    if (widget.isBusinessView &&
        loaded != null &&
        !loaded.isRead &&
        loaded.id.isNotEmpty) {
      unawaited(_repo.markOrderRead(loaded.id));
    }
  }

  Future<bool?> _confirmSheet({
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Go back',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: title,
                  onBack: () => Navigator.pop(ctx, false),
                ),
                Text(
                  body,
                  style: WaUi.body.copyWith(
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                PillButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: cancelLabel,
                  filled: false,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _confirmThen(OrderStatus status, {required String title}) async {
    final ok = await _confirmSheet(
      title: title,
      body: 'This updates the order for both you and the customer.',
    );
    if (ok == true) await _updateStatus(status);
  }

  Future<void> _refundPaidOrder() async {
    if (_order == null) return;
    final confirm = await _confirmSheet(
      title: 'Issue full refund?',
      body:
          'Refunds the customer to their original payment method. Duplicate refunds are blocked.',
      confirmLabel: 'Refund',
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

  Future<void> _payNow(CatalogOrder order) async {
    final result = await Navigator.of(context).push<StripeCheckoutResult>(
      AppPageRoute(
        builder: (_) => StripeCheckoutScreen(
          orderId: order.id,
          amount: order.totalAmount,
          currency: order.currency,
          customerName: order.displayCustomerName.isNotEmpty
              ? order.displayCustomerName
              : 'Customer',
          businessName: order.businessName,
          paymentAttemptKey:
              'order_pay_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
          guestPhone: order.displayContactPhone.isEmpty
              ? null
              : order.displayContactPhone,
        ),
      ),
    );
    if (!mounted) return;
    await _loadOrder();
    if (!mounted) return;
    if (result != null &&
        result.outcome == StripeCheckoutOutcome.success) {
      showAppToast(
        context,
        'Payment received — business notified',
        kind: AppToastKind.success,
      );
    }
  }

  Future<void> _cancelAsCustomer() async {
    if (_order == null) return;
    final ok = await _confirmSheet(
      title: 'Cancel ${_order!.nounLabel.toLowerCase()}?',
      body:
          'You can cancel while it’s still open. The business will be notified.',
      confirmLabel: 'Yes, cancel',
      cancelLabel: 'Keep it',
    );
    if (ok != true) return;
    setState(() => _isUpdating = true);
    final res = await _repo.cancelOrderAsCustomer(_order!.id);
    if (!mounted) return;
    setState(() => _isUpdating = false);
    if (res.success) {
      await _loadOrder();
      if (mounted) {
        showAppToast(context, 'Cancelled', kind: AppToastKind.success);
      }
    } else {
      showAppToast(
        context,
        res.message ?? 'Could not cancel',
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _claimGuestOrder() async {
    final codeCtrl = TextEditingController(
      text: _order?.guestTrackingCode.trim() ?? '',
    );
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: 'Claim guest order',
                onBack: () => Navigator.pop(ctx),
              ),
              Text(
                'Enter the tracking code from your receipt or SMS.',
                style: WaUi.body.copyWith(
                  color: BarqodyChrome.secondaryText,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'BK-XXXX-XXXX',
                  filled: true,
                  fillColor: BarqodyChrome.fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Claim order',
                onPressed: () => Navigator.pop(ctx, codeCtrl.text.trim()),
              ),
            ],
          ),
        );
      },
    );
    codeCtrl.dispose();
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _isUpdating = true);
    final res = await _repo.claimGuestOrder(trackingCode: code);
    if (!mounted) return;
    setState(() => _isUpdating = false);
    showAppToast(
      context,
      res.success
          ? (res.message ?? 'Order claimed')
          : (res.message ?? 'Could not claim order'),
      kind: res.success ? AppToastKind.success : AppToastKind.error,
    );
    if (res.success) await _loadOrder();
  }

  Future<void> _copyOrderRef(CatalogOrder order) async {
    final ref = order.hasToken
        ? '#${order.tokenNumber}'
        : (order.publicPaymentRef.isNotEmpty
            ? order.publicPaymentRef
            : order.id);
    await Clipboard.setData(ClipboardData(text: ref));
    if (!mounted) return;
    showAppToast(context, 'Copied $ref', kind: AppToastKind.success);
  }

  String _receiptShareText(CatalogOrder order) {
    final buf = StringBuffer();
    buf.writeln(_titleFor(order));
    buf.writeln(
      '${_orderDate(order)} · ${_orderTime(order)} · ${order.status.name}',
    );
    buf.writeln('');
    for (final item in order.items) {
      buf.writeln(
        '${item.quantity}× ${item.name} — ${formatMoney(item.price * item.quantity, currency: order.currency)}',
      );
    }
    buf.writeln('');
    buf.writeln(
      'Total: ${formatMoney(order.totalAmount, currency: order.currency)}',
    );
    buf.writeln('Payment: ${order.paymentLabel}');
    if (order.displayFulfillmentAddress.isNotEmpty) {
      buf.writeln('Address: ${order.displayFulfillmentAddress}');
    }
    return buf.toString().trim();
  }

  Future<void> _shareReceipt(CatalogOrder order) async {
    await Share.share(_receiptShareText(order));
  }

  Future<void> _openPhone(String raw) async {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      showAppToast(context, 'Couldn’t open phone', kind: AppToastKind.error);
    }
  }

  Future<void> _openWhatsApp(String raw) async {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showAppToast(context, 'Couldn’t open WhatsApp', kind: AppToastKind.error);
    }
  }

  Future<void> _openDeliveryMap(CatalogOrder order) async {
    final pin = order.mapCoordinates;
    final Uri uri;
    if (pin != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${pin.lat},${pin.lng}',
      );
    } else {
      final q = Uri.encodeComponent(order.displayFulfillmentAddress);
      if (q.isEmpty) return;
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showAppToast(context, 'Couldn’t open maps', kind: AppToastKind.error);
    }
  }

  Future<void> _openHelp() async {
    await Navigator.of(context).push(
      AppPageRoute(builder: (_) => const HelpCenterScreen()),
    );
  }

  Future<void> _leaveReview(CatalogOrder order) async {
    if (order.businessId.trim().isEmpty) return;
    final result = await showWriteReviewSheet(
      context,
      title: 'Review ${order.businessName}',
    );
    if (result == null || !mounted) return;
    final res = await ReviewRepo().upsertReview(
      targetType: 'business',
      targetId: order.businessId,
      businessId: order.businessId,
      rating: result.rating,
      text: result.text,
      targetLabel: order.businessName,
    );
    if (!mounted) return;
    showAppToast(
      context,
      res.success ? 'Review saved' : (res.message ?? 'Could not save review'),
      kind: res.success ? AppToastKind.success : AppToastKind.error,
    );
  }

  Future<void> _reorder(CatalogOrder order) async {
    if (order.businessId.isEmpty || order.businessLinkId.isEmpty) {
      showAppToast(
        context,
        'Can’t reorder this one — open the business profile instead',
        kind: AppToastKind.warning,
      );
      return;
    }
    final cart = context.read<ExploreCartProvider>();
    final catalogItems = <CatalogItem>[];
    for (final line in order.items) {
      final item = CatalogItem(
        name: line.name,
        price: line.listPrice ?? line.price,
        imageUrl: line.imageUrl,
        offerDiscount: line.offerDiscount,
        discountedPrice: line.offerDiscount ? line.price : 0,
      );
      catalogItems.add(item);
      cart.addItem(
        businessId: order.businessId,
        businessLinkId: order.businessLinkId,
        businessName: order.businessName,
        businessUsername: order.businessUsername,
        catalogType: order.catalogType.isNotEmpty ? order.catalogType : 'menu',
        currency: order.currency,
        catalogItems: [item],
        line: ExploreCartLine(
          item: item,
          quantity: line.quantity,
          notes: line.notes,
          bookingKind: order.kind == 'order' ? 'order' : order.kind,
        ),
      );
    }
    if (!mounted) return;
    showAppToast(
      context,
      '${catalogItems.length} item${catalogItems.length == 1 ? '' : 's'} added to cart',
      kind: AppToastKind.success,
    );
    await Navigator.of(context).push(
      AppPageRoute(builder: (_) => const ExploreCartScreen()),
    );
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

  Future<void> _openMore(CatalogOrder order) async {
    final showPayment = order.paymentMethod.toLowerCase() == 'online' &&
        order.id.isNotEmpty;
    final showClaim = !widget.isBusinessView && order.claimEligible;
    final showRefund = widget.isBusinessView && order.canBusinessRefund;
    final showReorder = !widget.isBusinessView &&
        (order.kind == 'order' || order.kind == 'table') &&
        order.items.isNotEmpty;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: 'Options',
                  onBack: () => Navigator.pop(ctx),
                ),
                _MoreTile(
                  icon: Icons.copy_rounded,
                  label: 'Copy reference',
                  onTap: () => Navigator.pop(ctx, 'copy'),
                ),
                _MoreTile(
                  icon: Icons.ios_share_rounded,
                  label: 'Share receipt',
                  onTap: () => Navigator.pop(ctx, 'share'),
                ),
                if (showPayment)
                  _MoreTile(
                    icon: Icons.payment_outlined,
                    label: 'Payment details',
                    onTap: () => Navigator.pop(ctx, 'payment'),
                  ),
                if (showReorder)
                  _MoreTile(
                    icon: Icons.replay_rounded,
                    label: 'Reorder',
                    onTap: () => Navigator.pop(ctx, 'reorder'),
                  ),
                if (showClaim)
                  _MoreTile(
                    icon: Icons.link_rounded,
                    label: 'Claim this order',
                    onTap: () => Navigator.pop(ctx, 'claim'),
                  ),
                if (showRefund)
                  _MoreTile(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Issue full refund',
                    onTap: () => Navigator.pop(ctx, 'refund'),
                  ),
                _MoreTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help center',
                  onTap: () => Navigator.pop(ctx, 'help'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case 'copy':
        await _copyOrderRef(order);
        break;
      case 'share':
        await _shareReceipt(order);
        break;
      case 'payment':
        await Navigator.of(context).push(
          AppPageRoute(
            builder: (_) => PaymentDetailScreen(orderId: order.id),
          ),
        );
        break;
      case 'reorder':
        await _reorder(order);
        break;
      case 'claim':
        await _claimGuestOrder();
        break;
      case 'refund':
        await _refundPaidOrder();
        break;
      case 'help':
        await _openHelp();
        break;
    }
  }

  Future<void> _reorderSingleItem(CatalogOrderLineItem item) async {
    final order = _order;
    if (order == null) return;
    if (order.businessId.isEmpty || order.businessLinkId.isEmpty) {
      showAppToast(
        context,
        'Can’t add this item right now',
        kind: AppToastKind.warning,
      );
      return;
    }
    final catalogItem = CatalogItem(
      name: item.name,
      price: item.listPrice ?? item.price,
      imageUrl: item.imageUrl,
      offerDiscount: item.offerDiscount,
      discountedPrice: item.offerDiscount ? item.price : 0,
    );
    context.read<ExploreCartProvider>().addItem(
          businessId: order.businessId,
          businessLinkId: order.businessLinkId,
          businessName: order.businessName,
          businessUsername: order.businessUsername,
          catalogType:
              order.catalogType.isNotEmpty ? order.catalogType : 'menu',
          currency: order.currency,
          catalogItems: [catalogItem],
          line: ExploreCartLine(
            item: catalogItem,
            quantity: item.quantity,
            notes: item.notes,
            bookingKind: order.kind == 'order' ? 'order' : order.kind,
          ),
        );
    if (!mounted) return;
    showAppToast(context, 'Added to cart', kind: AppToastKind.success);
    await Navigator.of(context).push(
      AppPageRoute(builder: (_) => const ExploreCartScreen()),
    );
  }

  void _showItemSheet(CatalogOrderLineItem item, String currency) {
    final order = _order;
    final note = item.notes.trim();
    final canOrderAgain = order != null &&
        !widget.isBusinessView &&
        order.status == OrderStatus.completed &&
        (order.kind == 'order' || order.kind == 'table');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: 'Item',
                  onBack: () => Navigator.pop(ctx),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: item.imageUrl.trim().isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: BarqodyChrome.fieldFill,
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: BarqodyChrome.secondaryText,
                                  ),
                                ),
                              )
                            : ColoredBox(
                                color: BarqodyChrome.fieldFill,
                                child: Icon(
                                  Icons.image_outlined,
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.quantity} × ${formatMoney(item.price, currency: currency)}',
                            style: WaUi.body.copyWith(
                              color: BarqodyChrome.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatMoney(
                              item.price * item.quantity,
                              currency: currency,
                            ),
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: BarqodyChrome.fieldFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your note',
                          style: WaUi.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Text(
                    'No special note on this item.',
                    style: WaUi.caption.copyWith(
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                ],
                if (item.hasDiscountSnapshot) ...[
                  const SizedBox(height: 12),
                  _SummaryKV(
                    label: 'Was',
                    value: formatMoney(item.listPrice!, currency: currency),
                  ),
                ],
                if (canOrderAgain) ...[
                  const SizedBox(height: 18),
                  PillButton(
                    label: 'Order again',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _reorderSingleItem(item);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _titleFor(CatalogOrder order) {
    final kind = order.kind;
    final noun =
        (kind == 'appointment' || kind == 'stay') ? 'Booking' : 'Order';
    if (order.hasToken) return '$noun #${order.tokenNumber}';
    return noun;
  }

  String _orderDate(CatalogOrder order) {
    if (order.createdAt == null) return '—';
    final d = order.createdAt!.toLocal();
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  String _orderTime(CatalogOrder order) {
    if (order.createdAt == null) return '—';
    return DateFormat('h:mm a').format(order.createdAt!.toLocal());
  }

  String _prettyDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(v));
    } catch (_) {
      return v;
    }
  }

  String _prettyDateTime(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    try {
      final dt = DateTime.parse(v).toLocal();
      return '${DateFormat('dd-MM-yyyy').format(dt)} · ${DateFormat('h:mm a').format(dt)}';
    } catch (_) {
      return v.replaceFirst('T', ' · ');
    }
  }

  Color _avatarColor(String seed) {
    if (seed.isEmpty) return WaUi.avatarPalette.last;
    return WaUi.avatarPalette[seed.hashCode.abs() % WaUi.avatarPalette.length];
  }

  String _contactPhone(CatalogOrder order) {
    if (widget.isBusinessView) return order.displayContactPhone;
    return '';
  }

  String _paymentChipTone(CatalogOrder order) {
    final label = order.paymentStatusChipLabel.toLowerCase();
    if (label.contains('paid') && !label.contains('unpaid')) return 'good';
    if (label.contains('unpaid') ||
        label == 'failed' ||
        order.canCustomerPayNow) {
      return 'warn';
    }
    if (label.contains('refund') || label.contains('cancel')) return 'muted';
    return 'neutral';
  }

  List<_TimelineEntry> _timelineEntries(CatalogOrder order) {
    if (order.statusHistory.isNotEmpty) {
      final entries = <_TimelineEntry>[];
      if (order.createdAt != null) {
        final firstTo = order.statusHistory.first.to.toLowerCase();
        if (firstTo != 'held' && firstTo != 'pending') {
          entries.add(
            _TimelineEntry(
              title: 'Placed',
              subtitle: 'Order received',
              at: order.createdAt,
              done: true,
            ),
          );
        }
      }
      for (final e in order.statusHistory) {
        entries.add(
          _TimelineEntry(
            title: _statusTimelineTitle(e.to),
            subtitle: e.note.trim().isNotEmpty
                ? e.note.trim()
                : _statusTimelineSubtitle(e.to, order),
            at: e.createdAt,
            done: true,
            isTerminalBad: e.to == 'cancelled' || e.to == 'no_show',
          ),
        );
      }
      return entries;
    }

    final status = order.status;
    final created = order.createdAt;
    if (status == OrderStatus.held || status == OrderStatus.pending) {
      return [
        _TimelineEntry(
          title: 'Placed',
          subtitle: 'Waiting for confirmation',
          at: created,
          done: true,
          active: true,
        ),
        _TimelineEntry(
          title: 'Confirmed',
          subtitle: order.isDelivery
              ? 'Then preparing for delivery'
              : 'Then preparing for pickup',
          done: false,
        ),
        _TimelineEntry(
          title: 'Completed',
          subtitle: order.isDelivery ? 'Delivered' : 'Picked up',
          done: false,
        ),
      ];
    }
    final steps = <_TimelineEntry>[
      _TimelineEntry(
        title: 'Placed',
        subtitle: 'Order received',
        at: created,
        done: true,
      ),
      _TimelineEntry(
        title: 'Confirmed',
        subtitle: order.isDelivery
            ? 'Preparing for delivery'
            : 'Preparing for pickup',
        at: status == OrderStatus.confirmed ||
                status == OrderStatus.completed ||
                status == OrderStatus.noShow
            ? order.updatedAt
            : null,
        done: true,
        active: status == OrderStatus.confirmed,
      ),
    ];
    if (status == OrderStatus.cancelled) {
      steps.add(
        _TimelineEntry(
          title: 'Cancelled',
          subtitle: 'Order was cancelled',
          at: order.updatedAt,
          done: true,
          isTerminalBad: true,
        ),
      );
    } else if (status == OrderStatus.noShow) {
      steps.add(
        _TimelineEntry(
          title: 'Not collected',
          subtitle: 'Marked as uncollected',
          at: order.updatedAt,
          done: true,
          isTerminalBad: true,
        ),
      );
    } else {
      steps.add(
        _TimelineEntry(
          title: 'Completed',
          subtitle: order.isDelivery ? 'Delivered' : 'Picked up',
          at: status == OrderStatus.completed ? order.updatedAt : null,
          done: status == OrderStatus.completed,
          active: status == OrderStatus.confirmed,
        ),
      );
    }
    return steps;
  }

  String _statusTimelineTitle(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'held':
        return 'Held';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'Not collected';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  String _statusTimelineSubtitle(String raw, CatalogOrder order) {
    switch (raw.trim().toLowerCase()) {
      case 'held':
        return 'Awaiting acceptance';
      case 'pending':
        return 'Waiting for confirmation';
      case 'confirmed':
        return order.isDelivery
            ? 'Preparing for delivery'
            : 'Preparing for pickup';
      case 'completed':
        return order.isDelivery ? 'Delivered' : 'Picked up';
      case 'cancelled':
        return 'Order cancelled';
      case 'no_show':
        return 'Not collected';
      default:
        return '';
    }
  }

  String _etaLabel(CatalogOrder order) {
    if (order.scheduledFor.trim().isNotEmpty) {
      return 'Scheduled · ${_prettyDateTime(order.scheduledFor)}';
    }
    if (order.isStay) {
      final cin = _prettyDate(order.checkInDate);
      return cin.isEmpty ? '' : 'Check-in · $cin';
    }
    if (order.isAppointment) {
      final date = _prettyDate(order.bookingDate ?? '');
      final time = (order.bookingTime ?? '').trim();
      if (date.isEmpty && time.isEmpty) return '';
      return [if (date.isNotEmpty) date, if (time.isNotEmpty) time].join(' · ');
    }
    final prep = order.prepTimeLabel;
    switch (order.status) {
      case OrderStatus.held:
      case OrderStatus.pending:
        if (prep.isNotEmpty) {
          return widget.isBusinessView
              ? 'Waiting for confirmation · $prep'
              : 'Waiting for confirmation · $prep';
        }
        return widget.isBusinessView
            ? 'Waiting for your confirmation'
            : 'Waiting for the business to confirm';
      case OrderStatus.confirmed:
        if (prep.isNotEmpty) {
          return order.isDelivery
              ? 'Preparing for delivery · $prep'
              : 'Preparing · $prep';
        }
        return order.isDelivery
            ? 'Confirmed — preparing for delivery'
            : 'Confirmed — we’ll notify when ready';
      case OrderStatus.completed:
        return 'All done';
      case OrderStatus.cancelled:
        return 'This ${order.nounLabel.toLowerCase()} was cancelled';
      case OrderStatus.noShow:
        return 'Marked as not collected';
    }
  }

  List<(String, String)> _overviewRows(CatalogOrder order) {
    final hasBillExtras = order.tipAmount > 0 ||
        order.deliveryFee > 0 ||
        order.couponDiscountAmount > 0 ||
        order.pointsDiscountAmount > 0;
    return [
      if (order.hasToken) ('Token', '#${order.tokenNumber}'),
      ('Order Date', _orderDate(order)),
      ('Order Time', _orderTime(order)),
      (
        'Total Items',
        '${order.items.fold<int>(0, (s, i) => s + i.quantity)}',
      ),
      if (hasBillExtras) ...[
        (
          'Subtotal',
          formatMoney(order.subtotalAmount, currency: order.currency),
        ),
        if (order.deliveryFee > 0)
          (
            'Delivery fee',
            formatMoney(order.deliveryFee, currency: order.currency),
          ),
        if (order.tipAmount > 0)
          (
            'Tip',
            formatMoney(order.tipAmount, currency: order.currency),
          ),
        if (order.couponDiscountAmount > 0)
          (
            order.couponCode.isNotEmpty
                ? 'Coupon (${order.couponCode})'
                : 'Coupon',
            '−${formatMoney(order.couponDiscountAmount, currency: order.currency)}',
          ),
        if (order.pointsDiscountAmount > 0)
          (
            order.pointsRedeemed > 0
                ? 'Points (${order.pointsRedeemed})'
                : 'Points',
            '−${formatMoney(order.pointsDiscountAmount, currency: order.currency)}',
          ),
      ],
    ];
  }

  Future<void> _openDetailsSheet(CatalogOrder order) async {
    final whenRows = _whenRows(order);
    final fulfillRows = _fulfillmentRows(order);
    final paymentRows = _paymentRows(order);
    final phone = _contactPhone(order);
    final eta = _etaLabel(order);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, scrollCtrl) {
              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  SheetHeader(
                    title: 'Order details',
                    onBack: () => Navigator.pop(ctx),
                  ),
                  if (eta.isNotEmpty) ...[
                    Text(
                      eta,
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (phone.isNotEmpty || order.canOpenDeliveryMap) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (phone.isNotEmpty) ...[
                          _QuickChip(
                            icon: Icons.call_outlined,
                            label: 'Call',
                            onTap: () => _openPhone(phone),
                          ),
                          _QuickChip(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'WhatsApp',
                            onTap: () => _openWhatsApp(phone),
                          ),
                        ],
                        if (order.canOpenDeliveryMap)
                          _QuickChip(
                            icon: Icons.map_outlined,
                            label: 'Map',
                            onTap: () => _openDeliveryMap(order),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (whenRows.isNotEmpty) ...[
                    Text(
                      order.isStay ? 'Stay' : 'When',
                      style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(rows: whenRows),
                    const SizedBox(height: 16),
                  ],
                  if (fulfillRows.isNotEmpty) ...[
                    Text(
                      _fulfillmentTitle(order),
                      style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(rows: fulfillRows),
                    if (order.canOpenDeliveryMap) ...[
                      const SizedBox(height: 10),
                      PillButton(
                        label: 'View on map',
                        filled: false,
                        onPressed: () => _openDeliveryMap(order),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  if (paymentRows.isNotEmpty) ...[
                    Text(
                      'Payment',
                      style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(rows: paymentRows),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<(String, String)> _whenRows(CatalogOrder order) {
    final rows = <(String, String)>[];
    if (order.isStay) {
      final cin = _prettyDate(order.checkInDate);
      final cout = _prettyDate(order.checkOutDate);
      if (cin.isNotEmpty) rows.add(('Check-in', cin));
      if (cout.isNotEmpty) rows.add(('Check-out', cout));
      if (order.resourceNames.isNotEmpty) {
        rows.add(('Room', order.resourceNames.join(', ')));
      }
    } else if (order.isAppointment) {
      final date = _prettyDate(order.bookingDate ?? '');
      final time = (order.bookingTime ?? '').trim();
      if (date.isNotEmpty) rows.add(('Date', date));
      if (time.isNotEmpty) rows.add(('Time', time));
      if (order.resourceNames.isNotEmpty) {
        rows.add(('Specialist', order.resourceNames.join(', ')));
      }
    }
    return rows;
  }

  List<(String, String)> _fulfillmentRows(CatalogOrder order) {
    final rows = <(String, String)>[];
    if (order.orderTypeLabel.isNotEmpty &&
        (order.kind == 'order' || order.kind == 'table')) {
      rows.add(('Type', order.orderTypeLabel));
    }
    if (order.deliveryArea.isNotEmpty) {
      rows.add(('Area', order.deliveryArea));
    }
    if (order.tableToken.isNotEmpty) {
      rows.add(('Table', order.tableToken));
    }
    if (order.displayFulfillmentAddress.isNotEmpty) {
      rows.add(('Address', order.displayFulfillmentAddress));
    }
    if (order.scheduledFor.trim().isNotEmpty) {
      rows.add(('Scheduled', _prettyDateTime(order.scheduledFor)));
    }
    if (order.fulfillmentNotes.isNotEmpty) {
      rows.add(('Notes', order.fulfillmentNotes));
    }
    return rows;
  }

  List<(String, String)> _paymentRows(CatalogOrder order) {
    final rows = <(String, String)>[];
    if (order.paymentLabel.isNotEmpty) {
      rows.add(('Method', order.paymentLabel));
    }
    if (order.deliveryFee > 0 ||
        order.tipAmount > 0 ||
        order.couponDiscountAmount > 0 ||
        order.pointsDiscountAmount > 0) {
      rows.add((
        'Subtotal',
        formatMoney(order.subtotalAmount, currency: order.currency),
      ));
      if (order.deliveryFee > 0) {
        rows.add((
          'Delivery fee',
          formatMoney(order.deliveryFee, currency: order.currency),
        ));
      }
      if (order.tipAmount > 0) {
        rows.add((
          'Tip',
          formatMoney(order.tipAmount, currency: order.currency),
        ));
      }
      if (order.couponDiscountAmount > 0) {
        rows.add((
          order.couponCode.isNotEmpty
              ? 'Coupon (${order.couponCode})'
              : 'Coupon',
          '−${formatMoney(order.couponDiscountAmount, currency: order.currency)}',
        ));
      }
      if (order.pointsDiscountAmount > 0) {
        rows.add((
          order.pointsRedeemed > 0
              ? 'Points (${order.pointsRedeemed})'
              : 'Points',
          '−${formatMoney(order.pointsDiscountAmount, currency: order.currency)}',
        ));
      }
    }
    if (order.guestTrackingCode.trim().isNotEmpty) {
      rows.add(('Tracking', order.guestTrackingCode.trim()));
    }
    if (order.publicPaymentRef.isNotEmpty) {
      rows.add(('Reference', order.publicPaymentRef));
    }
    if (order.hasRefund) {
      rows.add(('Refund', order.refundStatus.replaceAll('_', ' ')));
      if (order.refundedAmount > 0) {
        rows.add((
          'Refunded',
          formatMoney(order.refundedAmount, currency: order.currency),
        ));
      }
    }
    if (order.loyaltyReward != null) {
      rows.add(('Rewards', order.loyaltyReward!.summaryLabel));
    }
    return rows;
  }

  String _fulfillmentTitle(CatalogOrder order) {
    if (order.kind == 'table') return 'Table';
    if (order.isDelivery) return 'Delivery';
    if (order.orderType == 'takeaway' || order.orderType == 'pickup') {
      return 'Pickup';
    }
    return 'Details';
  }

  bool _hasBottomActions(CatalogOrder order) {
    if (widget.isBusinessView) {
      return order.status == OrderStatus.held ||
          order.status == OrderStatus.pending ||
          order.status == OrderStatus.confirmed ||
          order.canBusinessRefund;
    }
    return order.canCustomerPayNow ||
        order.canCustomerCancel ||
        order.claimEligible;
  }

  bool _showDoneActions(CatalogOrder order) {
    if (widget.isBusinessView) return false;
    return order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.noShow;
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final hasActions = order != null && _hasBottomActions(order);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title:
                  order != null ? _titleFor(order) : context.l10n.orderDetails,
              trailing: order == null
                  ? null
                  : _CircleIconButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: _isUpdating ? null : () => _openMore(order),
                    ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : order == null
                      ? _ErrorBody(
                          failed: _loadFailed,
                          onRetry: _loadOrder,
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          child: _buildBody(order, hasActions),
                        ),
            ),
            if (order != null && hasActions) _buildActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CatalogOrder order, bool hasActions) {
    final hasExtraDetails = _whenRows(order).isNotEmpty ||
        _fulfillmentRows(order).isNotEmpty ||
        _paymentRows(order).isNotEmpty ||
        _contactPhone(order).isNotEmpty ||
        order.canOpenDeliveryMap ||
        _etaLabel(order).isNotEmpty;
    final personName = widget.isBusinessView
        ? (order.displayCustomerName.isNotEmpty
            ? order.displayCustomerName
            : (order.isGuest ? 'Guest' : '—'))
        : order.businessName;
    final contactPhone = _contactPhone(order);
    final showFulfillmentBadge =
        (order.kind == 'order' || order.kind == 'table') &&
            (order.isDelivery || order.isPickup || order.orderTypeLabel.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFulfillmentBadge) ...[
          _FulfillmentBanner(
            isDelivery: order.isDelivery,
            title: order.isDelivery
                ? 'Delivery order'
                : (order.isPickup ? 'Pickup order' : order.orderTypeLabel),
            subtitle: order.isDelivery
                ? (order.displayFulfillmentAddress.isNotEmpty
                    ? order.displayFulfillmentAddress
                    : (order.deliveryArea.isNotEmpty
                        ? order.deliveryArea
                        : 'Deliver to customer'))
                : (order.scheduledFor.trim().isNotEmpty
                    ? 'Collect · ${_prettyDateTime(order.scheduledFor)}'
                    : 'Customer will collect'),
            onMap: order.canOpenDeliveryMap
                ? () => _openDeliveryMap(order)
                : null,
          ),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PaymentStatusChip(
              label: order.paymentStatusChipLabel,
              tone: _paymentChipTone(order),
            ),
            if (order.tipAmount > 0)
              _PaymentStatusChip(
                label:
                    'Tip · ${formatMoney(order.tipAmount, currency: order.currency)}',
                tone: 'good',
              ),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < order.items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: BarqodyChrome.divider),
          _OrderItemRow(
            item: order.items[i],
            currency: order.currency,
            onTap: () => _showItemSheet(order.items[i], order.currency),
          ),
        ],
        const SizedBox(height: 18),
        _InfoCard(
          rows: _overviewRows(order),
          totalLabel: 'Total amount',
          totalValue: formatMoney(
            order.totalAmount,
            currency: order.currency,
          ),
        ),
        const SizedBox(height: 4),
        _PersonRow(
          name: personName,
          username: widget.isBusinessView
              ? order.customerUsername
              : order.businessUsername,
          subtitle: widget.isBusinessView && contactPhone.isNotEmpty
              ? contactPhone
              : '',
          badge: widget.isBusinessView && order.isGuest ? 'Guest' : null,
          photoUrl: widget.isBusinessView
              ? order.customerPhoto
              : order.businessPhoto,
          avatarColor: _avatarColor(personName),
          onTap: () {
            final id =
                widget.isBusinessView ? order.customerId : order.businessId;
            final uname = widget.isBusinessView
                ? order.customerUsername
                : order.businessUsername;
            if (id.trim().isEmpty && uname.trim().isEmpty) return;
            _viewProfile(
              userId: id.trim().isEmpty ? null : id,
              username: uname,
            );
          },
        ),
        if (widget.isBusinessView && contactPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                icon: Icons.call_outlined,
                label: 'Call',
                onTap: () => _openPhone(contactPhone),
              ),
              _QuickChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp',
                onTap: () => _openWhatsApp(contactPhone),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Order timeline',
          style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _OrderTimeline(entries: _timelineEntries(order)),
        if (hasExtraDetails) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _openDetailsSheet(order),
              child: Text(
                'More details',
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
        if (!hasActions) ...[
          const SizedBox(height: 12),
          _StatusBanner(
            status: order.status,
            noun: order.nounLabel,
            subtitle: _etaLabel(order),
          ),
        ],
        if (_showDoneActions(order) &&
            order.status == OrderStatus.completed) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              if (order.kind == 'order' || order.kind == 'table') ...[
                Expanded(
                  child: _OutlineActionButton(
                    label: 'Reorder',
                    enabled: !_isUpdating,
                    onPressed: () => _reorder(order),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PillButton(
                  label: 'Leave a review',
                  enabled: !_isUpdating,
                  onPressed: () => _leaveReview(order),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActions(CatalogOrder order) {
    final held = widget.isBusinessView && order.status == OrderStatus.held;
    final pending =
        widget.isBusinessView && order.status == OrderStatus.pending;
    final confirmed =
        widget.isBusinessView && order.status == OrderStatus.confirmed;
    final refundOnly = widget.isBusinessView &&
        order.canBusinessRefund &&
        !held &&
        !pending &&
        !confirmed;
    final pay = !widget.isBusinessView && order.canCustomerPayNow;
    final claim = !widget.isBusinessView && order.claimEligible && !pay;
    final cancel = !widget.isBusinessView && order.canCustomerCancel;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (held) ...[
              PillButton(
                label: 'Accept',
                enabled: !_isUpdating,
                loading: _isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.pending,
                  title: 'Accept this order?',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OutlineActionButton(
                      label: 'Confirm now',
                      enabled: !_isUpdating,
                      onPressed: () => _confirmThen(
                        OrderStatus.confirmed,
                        title: 'Confirm this order?',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineActionButton(
                      label: 'Cancel',
                      destructive: true,
                      enabled: !_isUpdating,
                      onPressed: () => _confirmThen(
                        OrderStatus.cancelled,
                        title: 'Cancel this order?',
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (pending) ...[
              PillButton(
                label: 'Confirm',
                enabled: !_isUpdating,
                loading: _isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.confirmed,
                  title: 'Confirm this order?',
                ),
              ),
              const SizedBox(height: 10),
              _OutlineActionButton(
                label: 'Cancel',
                destructive: true,
                enabled: !_isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.cancelled,
                  title: 'Cancel this order?',
                ),
              ),
            ] else if (confirmed) ...[
              Row(
                children: [
                  Expanded(
                    child: _OutlineActionButton(
                      label: 'UnCollected',
                      enabled: !_isUpdating,
                      onPressed: () => _confirmThen(
                        OrderStatus.noShow,
                        title: 'Mark as uncollected?',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineActionButton(
                      label: 'Cancel',
                      destructive: true,
                      enabled: !_isUpdating,
                      onPressed: () => _confirmThen(
                        OrderStatus.cancelled,
                        title: 'Cancel this order?',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PillButton(
                label: 'Mark as Complete',
                enabled: !_isUpdating,
                loading: _isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.completed,
                  title: 'Mark as complete?',
                ),
              ),
            ] else if (refundOnly) ...[
              PillButton(
                label: 'Issue full refund',
                filled: false,
                enabled: !_isUpdating,
                onPressed: _refundPaidOrder,
              ),
            ] else ...[
              // Customer: Pay now for unpaid COD / cash orders.
              if (pay) ...[
                PillButton(
                  label: 'Pay now',
                  enabled: !_isUpdating,
                  onPressed: () => _payNow(order),
                ),
              ],
              if (claim) ...[
                if (pay) const SizedBox(height: 10),
                PillButton(
                  label: 'Claim order',
                  enabled: !_isUpdating,
                  onPressed: _claimGuestOrder,
                ),
              ],
              if (cancel) ...[
                if (pay || claim) const SizedBox(height: 10),
                _OutlineActionButton(
                  label: pay ? 'Cancel' : 'Cancel order',
                  destructive: true,
                  enabled: !_isUpdating,
                  onPressed: _cancelAsCustomer,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final bool failed;
  final VoidCallback onRetry;

  const _ErrorBody({required this.failed, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failed ? 'Couldn’t load this order' : context.l10n.orderNotFound,
              textAlign: TextAlign.center,
              style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              failed
                  ? 'Check your connection and try again.'
                  : 'This order may have been removed, or it isn’t linked to your account.',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
            ),
            if (failed) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                child: PillButton(
                  label: context.l10n.tryAgain,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final OrderStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case OrderStatus.completed:
        return _CircleBadge(
          child: Image.asset(
            'assets/images/png/check-icon-1.png',
            width: 22,
            height: 22,
            color: Colors.white,
            errorBuilder: (_, _, _) => const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        );
      case OrderStatus.cancelled:
        return _CircleBadge(
          child: Image.asset(
            'assets/images/png/cancel-icon.png',
            width: 18,
            height: 18,
            color: Colors.white,
            errorBuilder: (_, _, _) => const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      case OrderStatus.noShow:
        return Image.asset(
          'assets/images/png/order-cance.png',
          width: 56,
          height: 56,
          errorBuilder: (_, _, _) => Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: const Icon(Icons.block_rounded, size: 28),
          ),
        );
      case OrderStatus.confirmed:
      case OrderStatus.held:
      case OrderStatus.pending:
        return Image.asset(
          'assets/images/png/bag-icon.png',
          width: 64,
          height: 64,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.shopping_bag_outlined, size: 56),
        );
    }
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                label,
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: Colors.black),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: BarqodyChrome.fieldFill,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
      title: Text(
        label,
        style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: BarqodyChrome.secondaryText,
      ),
      onTap: onTap,
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CatalogOrderLineItem item;
  final String currency;
  final VoidCallback onTap;

  const _OrderItemRow({
    required this.item,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final note = item.notes.trim();
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
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
                            child: Icon(
                              Icons.image_outlined,
                              color: BarqodyChrome.secondaryText,
                              size: 24,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: BarqodyChrome.fieldFill,
                          child: Icon(
                            Icons.image_outlined,
                            color: BarqodyChrome.secondaryText,
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
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(item.price, currency: currency),
                      style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: $note',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  final String noun;
  final String subtitle;

  const _StatusBanner({
    required this.status,
    required this.noun,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (status) {
      OrderStatus.completed => '$noun Complete',
      OrderStatus.cancelled => '$noun Cancelled',
      OrderStatus.noShow => '$noun Not Collected',
      OrderStatus.confirmed => '$noun Confirmed',
      OrderStatus.held || OrderStatus.pending => '$noun Pending',
    };
    final fallback = switch (status) {
      OrderStatus.completed => 'Your $noun has been completed successfully',
      OrderStatus.cancelled => 'Your $noun has been cancelled',
      OrderStatus.noShow => "You didn't collect your $noun",
      OrderStatus.confirmed => 'Your $noun has been confirmed',
      OrderStatus.held || OrderStatus.pending => 'Your $noun is being processed',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _StatusIcon(status: status),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: 20,
              weight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle.isNotEmpty ? subtitle : fallback,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> rows;
  final String? totalLabel;
  final String? totalValue;

  const _InfoCard({
    required this.rows,
    this.totalLabel,
    this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2.trim().isNotEmpty).toList();
    final showTotal =
        (totalLabel ?? '').isNotEmpty && (totalValue ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (final row in visible) _SummaryKV(label: row.$1, value: row.$2),
          if (showTotal) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFE0E0E5)),
            ),
            Row(
              children: [
                Text(
                  totalLabel!,
                  style: WaUi.body.copyWith(
                    color: BarqodyChrome.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  totalValue!,
                  style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryKV extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryKV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WaUi.body.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  final String username;
  final String subtitle;
  final String? badge;
  final String? photoUrl;
  final Color avatarColor;
  final VoidCallback onTap;

  const _PersonRow({
    required this.name,
    required this.username,
    this.subtitle = '',
    this.badge,
    this.photoUrl,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : '—';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final canOpen = username.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: canOpen ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarColor,
                backgroundImage:
                    hasPhoto ? NetworkImage(photoUrl!.trim()) : null,
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
                              color: BarqodyChrome.fieldFill,
                              borderRadius: BorderRadius.circular(999),
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
                    if (username.trim().isNotEmpty)
                      Text(
                        '@${username.trim()}',
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle.trim(),
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (canOpen)
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

class _CircleBadge extends StatelessWidget {
  final Widget child;

  const _CircleBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool enabled;

  const _OutlineActionButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE53935) : Colors.black;
    return SizedBox(
      height: WaUi.primaryButtonHeight,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.35),
          side: BorderSide(color: color, width: 1.2),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WaUi.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TimelineEntry {
  final String title;
  final String subtitle;
  final DateTime? at;
  final bool done;
  final bool active;
  final bool isTerminalBad;

  const _TimelineEntry({
    required this.title,
    this.subtitle = '',
    this.at,
    this.done = false,
    this.active = false,
    this.isTerminalBad = false,
  });
}

class _OrderTimeline extends StatelessWidget {
  final List<_TimelineEntry> entries;

  const _OrderTimeline({required this.entries});

  String _fmt(DateTime? at) {
    if (at == null) return '';
    return DateFormat('dd MMM · h:mm a').format(at.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _TimelineRow(
              entry: entries[i],
              timeLabel: _fmt(entries[i].at),
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEntry entry;
  final String timeLabel;
  final bool isLast;

  const _TimelineRow({
    required this.entry,
    required this.timeLabel,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = entry.isTerminalBad
        ? const Color(0xFFE53935)
        : (entry.done || entry.active ? Colors.black : const Color(0xFFBDBDBD));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.done || entry.active
                        ? accent
                        : Colors.transparent,
                    border: Border.all(color: accent, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: entry.done
                          ? Colors.black.withValues(alpha: 0.25)
                          : const Color(0xFFD6D6D6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: WaUi.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: entry.done || entry.active
                          ? Colors.black
                          : BarqodyChrome.secondaryText,
                    ),
                  ),
                  if (entry.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfillmentBanner extends StatelessWidget {
  final bool isDelivery;
  final String title;
  final String subtitle;
  final VoidCallback? onMap;

  const _FulfillmentBanner({
    required this.isDelivery,
    required this.title,
    required this.subtitle,
    this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDelivery ? const Color(0xFFEEF6FF) : const Color(0xFFF3F4F6);
    final icon =
        isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onMap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WaUi.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onMap != null)
                Icon(
                  Icons.map_outlined,
                  color: BarqodyChrome.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final String label;
  final String tone;

  const _PaymentStatusChip({
    required this.label,
    this.tone = 'neutral',
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (tone == 'good') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF1B5E20);
    } else if (tone == 'warn') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
    } else if (tone == 'muted') {
      bg = const Color(0xFFF5F5F5);
      fg = const Color(0xFF616161);
    } else {
      bg = BarqodyChrome.fieldFill;
      fg = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: WaUi.caption.copyWith(
          fontWeight: FontWeight.w800,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

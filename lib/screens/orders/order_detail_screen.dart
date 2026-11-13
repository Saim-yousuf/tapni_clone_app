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
import 'package:tapni_app/screens/orders/customer_order_chrome.dart';
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
  bool _billExpanded = false;
  bool _timelineExpanded = true;

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
            CatalogHelper.statusLabel(
              status,
              context.l10n,
              isDelivery: _order?.isDelivery ?? false,
            ),
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
        item.configurationLabel.trim().isNotEmpty
            ? '${item.quantity}× ${item.name} (${item.configurationLabel.trim()}) — ${formatMoney(item.price * item.quantity, currency: order.currency)}'
            : '${item.quantity}× ${item.name} — ${formatMoney(item.price * item.quantity, currency: order.currency)}',
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
    final isBiz = widget.isBusinessView;
    final showPayment = order.paymentMethod.toLowerCase() == 'online' &&
        order.id.isNotEmpty;
    // Primary CTAs live in the bottom bar — don't duplicate them here.
    final bottomShowsReorder = !isBiz &&
        order.status == OrderStatus.completed &&
        (order.kind == 'order' || order.kind == 'table');
    final showReorder = !isBiz &&
        !bottomShowsReorder &&
        (order.kind == 'order' || order.kind == 'table') &&
        order.items.isNotEmpty &&
        (order.status == OrderStatus.completed ||
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.noShow);
    final bottomShowsRefund = isBiz &&
        order.canBusinessRefund &&
        order.status != OrderStatus.held &&
        order.status != OrderStatus.pending &&
        order.status != OrderStatus.confirmed &&
        order.status != OrderStatus.outForDelivery;
    final showRefund = isBiz && order.canBusinessRefund && !bottomShowsRefund;
    // Customer: receipt sheet. Business: ops details (fulfillment / contact).
    final showReceipt = !isBiz;
    final showDetails = isBiz;

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
                if (showReceipt)
                  _MoreTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'View receipt',
                    onTap: () => Navigator.pop(ctx, 'receipt'),
                  ),
                if (showDetails)
                  _MoreTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Order details',
                    onTap: () => Navigator.pop(ctx, 'details'),
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
      case 'receipt':
        await _openReceiptSheet(order);
        break;
      case 'details':
        await _openDetailsSheet(order);
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
                          if (item.configurationLabel.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.configurationLabel.trim(),
                              style: WaUi.body.copyWith(
                                color: BarqodyChrome.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8ED)),
                  const SizedBox(height: 12),
                  Text(
                    widget.isBusinessView ? 'Customer note' : 'Your note',
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
                      color: Colors.black,
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

  DateTime? _historyAt(CatalogOrder order, Set<String> statuses) {
    for (final e in order.statusHistory) {
      if (statuses.contains(e.to.trim().toLowerCase())) return e.createdAt;
    }
    return null;
  }

  /// Customer 4-step rail — only real OrderStatus, no rider / live map steps.
  List<_CustomerProgressStep> _customerProgressSteps(CatalogOrder order) {
    final status = order.status;
    final pending =
        status == OrderStatus.held || status == OrderStatus.pending;
    final confirmed = status == OrderStatus.confirmed;
    final completed = status == OrderStatus.completed;
    final bad =
        status == OrderStatus.cancelled || status == OrderStatus.noShow;

    final thirdTitle = order.isDelivery ? 'On the way' : 'Ready';
    final thirdIcon =
        order.isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded;
    final doneTitle = order.isDelivery ? 'Delivered' : 'Completed';

    if (bad) {
      return [
        _CustomerProgressStep(
          title: 'Placed',
          icon: Icons.receipt_long_rounded,
          done: true,
        ),
        _CustomerProgressStep(
          title: status == OrderStatus.cancelled ? 'Cancelled' : _noShowLabel(order),
          icon: Icons.close_rounded,
          done: true,
          bad: true,
          active: true,
        ),
      ];
    }

    return [
      _CustomerProgressStep(
        title: 'Placed',
        icon: Icons.receipt_long_rounded,
        done: true,
        active: pending,
      ),
      _CustomerProgressStep(
        title: 'Preparing',
        icon: Icons.restaurant_rounded,
        done: confirmed || completed,
        active: confirmed,
      ),
      _CustomerProgressStep(
        title: thirdTitle,
        icon: thirdIcon,
        done: completed,
      ),
      _CustomerProgressStep(
        title: doneTitle,
        icon: Icons.check_rounded,
        done: completed,
      ),
    ];
  }

  String _customerProgressCaption(CatalogOrder order) {
    return CxProgressStep.captionFor(order);
  }

  List<_TimelineEntry> _timelineEntries(CatalogOrder order) {
    final status = order.status;
    final biz = widget.isBusinessView;
    final created = order.createdAt;
    final confirmedAt = _historyAt(order, {'confirmed'}) ??
        (status == OrderStatus.confirmed ||
                status == OrderStatus.completed ||
                status == OrderStatus.noShow
            ? order.updatedAt
            : null);
    final completedAt = _historyAt(order, {'completed'}) ??
        (status == OrderStatus.completed ? order.updatedAt : null);
    final cancelledAt = _historyAt(order, {'cancelled'}) ??
        (status == OrderStatus.cancelled ? order.updatedAt : null);
    final noShowAt = _historyAt(order, {'no_show'}) ??
        (status == OrderStatus.noShow ? order.updatedAt : null);

    final receivedSub = biz
        ? 'Order landed in your queue'
        : 'We received your order';
    final pendingSub = biz
        ? 'Confirm or cancel this order'
        : 'Waiting for the business to confirm';
    final confirmedSub = biz
        ? 'Accepted — kitchen can start'
        : 'Kitchen has your ticket';
    final preparingSub = order.isDelivery
        ? (biz ? 'Kitchen is preparing' : 'Food is being prepared')
        : (biz ? 'Kitchen is preparing' : 'Being prepared for pickup');
    final readySub = order.isDelivery
        ? (biz ? 'Packed — ready for rider' : 'Packed and ready for pickup')
        : (biz ? 'Ready for customer pickup' : 'Ready for you to collect');
    final onDeliverySub =
        biz ? 'Out for delivery' : 'Heading to your door';
    final completedSub = order.isDelivery
        ? (biz ? 'Delivered to customer' : 'Enjoy your meal')
        : (biz ? 'Collected by customer' : 'Enjoy your meal');

    // Terminal bad: short rail ending in cancel / no-show.
    if (status == OrderStatus.cancelled) {
      final reachedConfirm = order.statusHistory
          .any((e) => e.to.trim().toLowerCase() == 'confirmed');
      return [
        _TimelineEntry(
          title: 'Order received',
          subtitle: receivedSub,
          at: created,
          done: true,
        ),
        if (reachedConfirm)
          _TimelineEntry(
            title: 'Confirmed',
            subtitle: confirmedSub,
            at: confirmedAt,
            done: true,
          ),
        _TimelineEntry(
          title: 'Cancelled',
          subtitle: biz ? 'Order was cancelled' : 'Your order was cancelled',
          at: cancelledAt,
          done: true,
          isTerminalBad: true,
        ),
      ];
    }
    if (status == OrderStatus.noShow) {
      return [
        _TimelineEntry(
          title: 'Order received',
          subtitle: receivedSub,
          at: created,
          done: true,
        ),
        _TimelineEntry(
          title: 'Confirmed',
          subtitle: confirmedSub,
          at: confirmedAt,
          done: true,
        ),
        _TimelineEntry(
          title: _noShowLabel(order),
          subtitle: _noShowSubtitle(order),
          at: noShowAt,
          done: true,
          isTerminalBad: true,
        ),
      ];
    }

    final isPending =
        status == OrderStatus.held || status == OrderStatus.pending;
    final isConfirmed = status == OrderStatus.confirmed;
    final isCompleted = status == OrderStatus.completed;
    final pastPending = isConfirmed || isCompleted;

    final steps = <_TimelineEntry>[
      _TimelineEntry(
        title: 'Order received',
        subtitle: receivedSub,
        at: created,
        done: true,
      ),
      _TimelineEntry(
        title: 'Pending',
        subtitle: pendingSub,
        at: pastPending ? (confirmedAt ?? created) : created,
        done: pastPending,
        active: isPending,
      ),
      _TimelineEntry(
        title: 'Confirmed',
        subtitle: confirmedSub,
        at: pastPending ? confirmedAt : null,
        done: pastPending,
        active: isConfirmed,
      ),
      _TimelineEntry(
        title: 'Preparing',
        subtitle: preparingSub,
        done: isCompleted,
      ),
      _TimelineEntry(
        title: 'Ready',
        subtitle: readySub,
        done: isCompleted,
      ),
    ];
    if (order.isDelivery) {
      steps.add(
        _TimelineEntry(
          title: 'On delivery',
          subtitle: onDeliverySub,
          done: isCompleted,
        ),
      );
    }
    steps.add(
      _TimelineEntry(
        title: 'Completed',
        subtitle: completedSub,
        at: isCompleted ? completedAt : null,
        done: isCompleted,
      ),
    );
    return steps;
  }

  /// Same backend status (`no_show`); copy differs by fulfillment.
  String _noShowLabel(CatalogOrder order) =>
      order.isDelivery ? 'Not delivered' : 'Not collected';

  String _noShowSubtitle(CatalogOrder order) {
    if (order.isDelivery) return 'Delivery couldn’t be completed';
    return widget.isBusinessView
        ? 'Customer didn’t pick up'
        : 'You didn’t pick up';
  }

  String _noShowHeroTitle(CatalogOrder order) {
    final noun = order.nounLabel;
    return order.isDelivery ? '$noun Not Delivered' : '$noun Not Collected';
  }

  String _noShowHeroFallback(CatalogOrder order) {
    final noun = order.nounLabel.toLowerCase();
    if (widget.isBusinessView) {
      return order.isDelivery
          ? 'This $noun couldn’t be delivered'
          : 'Customer didn’t collect this $noun';
    }
    return order.isDelivery
        ? 'Your $noun couldn’t be delivered'
        : "You didn’t collect your $noun";
  }

  String _noShowEta(CatalogOrder order) => order.isDelivery
      ? 'Marked as not delivered'
      : 'Marked as not collected';

  String _noShowActionLabel(CatalogOrder order) =>
      order.isDelivery ? 'Couldn’t deliver' : 'Not collected';

  String _noShowConfirmTitle(CatalogOrder order) => order.isDelivery
      ? 'Mark as not delivered?'
      : 'Mark as not collected?';

  String _completeActionLabel(CatalogOrder order) =>
      order.isDelivery ? 'Mark as Delivered' : 'Mark as Complete';

  String _completeConfirmTitle(CatalogOrder order) => order.isDelivery
      ? 'Mark this order as delivered?'
      : 'Mark this order as complete?';

  String _statusHeroTitle(CatalogOrder order) {
    final noun = order.nounLabel;
    return switch (order.status) {
      OrderStatus.completed => '$noun Complete',
      OrderStatus.cancelled => '$noun Cancelled',
      OrderStatus.noShow => _noShowHeroTitle(order),
      OrderStatus.outForDelivery =>
        order.isDelivery ? '$noun On the way' : '$noun Ready',
      OrderStatus.confirmed => '$noun Confirmed',
      OrderStatus.held || OrderStatus.pending => '$noun Pending',
    };
  }

  String _statusHeroFallback(CatalogOrder order) {
    final noun = order.nounLabel.toLowerCase();
    if (widget.isBusinessView) {
      return switch (order.status) {
        OrderStatus.completed => 'This $noun is complete',
        OrderStatus.cancelled => 'This $noun was cancelled',
        OrderStatus.noShow => _noShowHeroFallback(order),
        OrderStatus.outForDelivery => order.isDelivery
            ? 'Out for delivery'
            : 'Ready for customer pickup',
        OrderStatus.confirmed => 'This $noun is confirmed',
        OrderStatus.held || OrderStatus.pending =>
          'Waiting for your confirmation',
      };
    }
    return switch (order.status) {
      OrderStatus.completed => 'Your $noun has been completed successfully',
      OrderStatus.cancelled => 'Your $noun has been cancelled',
      OrderStatus.noShow => _noShowHeroFallback(order),
      OrderStatus.outForDelivery => order.isDelivery
          ? 'Your $noun is on the way'
          : 'Your $noun is ready for pickup',
      OrderStatus.confirmed => 'Your $noun has been confirmed',
      OrderStatus.held || OrderStatus.pending => 'Your $noun is being processed',
    };
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
              ? 'Waiting for your confirmation · $prep'
              : 'Waiting for the business · $prep';
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
        if (order.isDelivery) {
          return 'Confirmed — preparing for delivery';
        }
        return widget.isBusinessView
            ? 'Confirmed — ready when customer collects'
            : 'Confirmed — we’ll notify when ready';
      case OrderStatus.outForDelivery:
        return order.isDelivery
            ? (widget.isBusinessView
                ? 'Out for delivery'
                : 'On the way to you')
            : (widget.isBusinessView
                ? 'Ready for pickup'
                : 'Ready for you to collect');
      case OrderStatus.completed:
        return 'All done';
      case OrderStatus.cancelled:
        return 'This ${order.nounLabel.toLowerCase()} was cancelled';
      case OrderStatus.noShow:
        return _noShowEta(order);
    }
  }

  String _metaLine(CatalogOrder order) {
    final created = order.createdAt?.toLocal();
    final date = created == null
        ? ''
        : DateFormat('dd MMM').format(created);
    final time = created == null
        ? ''
        : DateFormat('h:mm a').format(created);
    return [
      if (order.hasToken) '#${order.tokenNumber}',
      if (date.isNotEmpty) date,
      if (time.isNotEmpty) time,
    ].join(' · ');
  }

  bool _isTerminalStatus(CatalogOrder order) =>
      order.status == OrderStatus.completed ||
      order.status == OrderStatus.cancelled ||
      order.status == OrderStatus.noShow;

  List<(String, String)> _paymentMetaRows(CatalogOrder order) {
    final rows = <(String, String)>[];
    if (order.paymentLabel.isNotEmpty) {
      rows.add(('Method', order.paymentLabel));
    }
    final status = order.paymentStatusChipLabel.trim();
    if (status.isNotEmpty) {
      rows.add(('Status', status));
    }
    if (order.guestTrackingCode.trim().isNotEmpty) {
      rows.add(('Reference', order.guestTrackingCode.trim()));
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

  Future<void> _openInfoSheet({
    required String title,
    List<(String, String)> rows = const [],
    String? body,
    String? caption,
  }) async {
    final visible = rows.where((r) => r.$2.trim().isNotEmpty).toList();
    final hasBody = (body ?? '').trim().isNotEmpty;
    if (visible.isEmpty && !hasBody) return;

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: title,
                  onBack: () => Navigator.pop(ctx),
                ),
                if ((caption ?? '').trim().isNotEmpty) ...[
                  Text(
                    caption!.trim(),
                    style: WaUi.caption.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (hasBody)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _Od.panel,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Text(
                        body!.trim(),
                        style: WaUi.body.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (visible.isNotEmpty) ...[
                  if (hasBody) const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _Od.panel,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _InfoCard(rows: visible),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<(String, String)> _paymentBillRows(CatalogOrder order) {
    final rows = <(String, String)>[];
    final showBreakdown = order.tipAmount > 0 ||
        order.deliveryFee > 0 ||
        order.couponDiscountAmount > 0 ||
        order.pointsDiscountAmount > 0;
    if (showBreakdown) {
      rows.add((
        'Subtotal',
        formatMoney(order.subtotalAmount, currency: order.currency),
      ));
    }
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
    return rows;
  }

  Future<void> _openReceiptSheet(CatalogOrder order) async {
    final billRows = _paymentBillRows(order);
    final totalText = formatMoney(
      order.totalAmount,
      currency: order.currency,
    );
    final ref = order.listReference.isNotEmpty
        ? order.listReference
        : (order.hasToken ? '#${order.tokenNumber}' : order.id);
    final date = _orderDate(order);
    final time = _orderTime(order);
    final merchant = order.businessName.isNotEmpty
        ? order.businessName
        : (widget.isBusinessView ? 'Your business' : 'Business');
    final counterparty = widget.isBusinessView
        ? (order.displayCustomerName.isNotEmpty
            ? order.displayCustomerName
            : (order.isGuest ? 'Guest' : 'Customer'))
        : '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF2F2F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) {
              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: [
                  SheetHeader(
                    title: 'Receipt',
                    onBack: () => Navigator.pop(ctx),
                    padHorizontal: false,
                  ),
                  const SizedBox(height: 8),
                  // Paper receipt card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _ReceiptEdgePainter(top: true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                merchant.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: WaUi.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ORDER RECEIPT',
                                textAlign: TextAlign.center,
                                style: WaUi.caption.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.4,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _ReceiptDash(),
                              const SizedBox(height: 12),
                              _ReceiptKv(label: 'Order', value: ref),
                              if (date.isNotEmpty && date != '—')
                                _ReceiptKv(label: 'Date', value: date),
                              if (time.isNotEmpty && time != '—')
                                _ReceiptKv(label: 'Time', value: time),
                              if (counterparty.isNotEmpty)
                                _ReceiptKv(
                                  label: 'Customer',
                                  value: counterparty,
                                ),
                              if (order.isDelivery || order.isPickup)
                                _ReceiptKv(
                                  label: 'Type',
                                  value: order.isDelivery
                                      ? 'Delivery'
                                      : 'Pickup',
                                ),
                              const SizedBox(height: 10),
                              const _ReceiptDash(),
                              const SizedBox(height: 12),
                              if (order.items.isEmpty)
                                Text(
                                  'No items',
                                  textAlign: TextAlign.center,
                                  style: WaUi.caption.copyWith(
                                    color: BarqodyChrome.secondaryText,
                                  ),
                                )
                              else
                                for (final item in order.items) ...[
                                  _ReceiptItemLine(
                                    qty: item.quantity,
                                    name: item.name,
                                    amount: formatMoney(
                                      item.price * item.quantity,
                                      currency: order.currency,
                                    ),
                                    detail: item.configurationLabel.trim(),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              const _ReceiptDash(),
                              const SizedBox(height: 10),
                              for (final row in billRows)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: _ReceiptKv(
                                    label: row.$1,
                                    value: row.$2,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              const _ReceiptDash(heavy: true),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'TOTAL',
                                    style: WaUi.body.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    totalText,
                                    style: WaUi.body.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              if (order.paymentLabel.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _ReceiptKv(
                                  label: 'Payment',
                                  value: order.paymentLabel,
                                ),
                              ],
                              if (order.displayFulfillmentAddress
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  order.displayFulfillmentAddress.trim(),
                                  textAlign: TextAlign.center,
                                  style: WaUi.caption.copyWith(
                                    color: BarqodyChrome.secondaryText,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              const _ReceiptDash(),
                              const SizedBox(height: 14),
                              Text(
                                'Thank you',
                                textAlign: TextAlign.center,
                                style: WaUi.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Keep this for your records',
                                textAlign: TextAlign.center,
                                style: WaUi.caption.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _ReceiptEdgePainter(top: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PillButton(
                    label: 'Share receipt',
                    onPressed: () => _shareReceipt(order),
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: 'Copy reference',
                    filled: false,
                    onPressed: () => _copyOrderRef(order),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openDetailsSheet(CatalogOrder order) async {
    final whenRows = _whenRows(order);
    final fulfillRows = _fulfillmentRows(order)
        .where((r) => r.$1 != 'Notes')
        .toList();
    final paymentMeta = _paymentMetaRows(order);
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
            initialChildSize: 0.58,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, scrollCtrl) {
              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  SheetHeader(
                    title: 'Order details',
                    onBack: () => Navigator.pop(ctx),
                  ),
                  if (eta.isNotEmpty) ...[
                    Text(
                      eta,
                      style: WaUi.body.copyWith(
                        color: const Color(0xFF5C5C62),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            icon: Icons.place_outlined,
                            label: 'Address',
                            onTap: () => _openDeliveryMap(order),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (whenRows.isNotEmpty) ...[
                    _OdSectionHeader(
                      label: order.isStay ? 'Stay' : 'Schedule',
                    ),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _Od.panel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _InfoCard(rows: whenRows),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (fulfillRows.isNotEmpty) ...[
                    _OdSectionHeader(label: _fulfillmentTitle(order)),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _Od.panel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _InfoCard(rows: fulfillRows),
                      ),
                    ),
                    if (order.canOpenDeliveryMap) ...[
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'Open delivery address',
                        filled: false,
                        onPressed: () => _openDeliveryMap(order),
                      ),
                    ],
                    const SizedBox(height: 18),
                  ],
                  if (paymentMeta.isNotEmpty) ...[
                    const _OdSectionHeader(label: 'Payment'),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _Od.panel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _InfoCard(rows: paymentMeta),
                      ),
                    ),
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
    final cleanNotes = stripLegacyDeliveryDropOffNotes(order.fulfillmentNotes);
    if (cleanNotes.isNotEmpty) {
      rows.add(('Notes', cleanNotes));
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
          order.status == OrderStatus.outForDelivery ||
          order.canBusinessRefund;
    }
    if (order.canCustomerPayNow ||
        order.canCustomerCancel ||
        order.claimEligible) {
      return true;
    }
    return _showDoneActions(order) && order.status == OrderStatus.completed;
  }

  bool _showDoneActions(CatalogOrder order) {
    if (widget.isBusinessView) return false;
    return order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.noShow;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isBusinessView) {
      return _buildCustomerScaffold();
    }

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
                      : RefreshIndicator(
                          color: Colors.black,
                          onRefresh: _loadOrder,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              hasActions ? 20 : 32,
                            ),
                            child: _buildBusinessBody(order),
                          ),
                        ),
            ),
            if (order != null && hasActions) _buildActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessBody(CatalogOrder order) {
    final totalText = formatMoney(order.totalAmount, currency: order.currency);
    final completed = order.status == OrderStatus.completed;
    final customerName = order.displayCustomerName.isNotEmpty
        ? order.displayCustomerName
        : (order.isGuest ? 'Guest' : 'Customer');
    final photo = order.customerPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final contactPhone = _contactPhone(order);
    final address = order.displayFulfillmentAddress.isNotEmpty
        ? order.displayFulfillmentAddress
        : (order.deliveryArea.isNotEmpty
            ? order.deliveryArea
            : (order.isPickup ? 'Customer collects at store' : ''));
    final typeLabel = order.isDelivery
        ? 'Delivery'
        : (order.isPickup ? 'Pickup' : order.orderTypeLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CxProgressBar(
            steps: CxProgressStep.forOrder(order),
            caption: CxProgressStep.captionForBusiness(order),
          ),
        ),
        if (completed) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Cx.greenSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Cx.green.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Cx.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.isDelivery ? 'Delivered' : 'Completed',
                        style: WaUi.body.copyWith(
                          color: Cx.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.isDelivery
                            ? 'This order was delivered to the customer.'
                            : 'This order was collected.',
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.bodyText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Material(
          color: Cx.surface,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          customerName[0].toUpperCase(),
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.body.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (order.isGuest) 'Guest',
                          if (typeLabel.isNotEmpty) typeLabel,
                          if (contactPhone.isNotEmpty) contactPhone,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: Cx.muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (contactPhone.isNotEmpty) ...[
                  _IconActionButton(
                    icon: Icons.call_outlined,
                    onTap: () => _openPhone(contactPhone),
                  ),
                  const SizedBox(width: 6),
                  _IconActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => _openWhatsApp(contactPhone),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (order.isDelivery && address.isNotEmpty) ...[
          const SizedBox(height: 10),
          Material(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: order.canOpenDeliveryMap
                  ? () => _openDeliveryMap(order)
                  : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.place_outlined, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.canOpenDeliveryMap
                                ? 'Delivery address'
                                : 'Deliver to',
                            style: WaUi.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: WaUi.caption.copyWith(
                              color: Cx.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order.canOpenDeliveryMap)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: Cx.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Order items',
          style: WaUi.body.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: Cx.hairline),
                _cxItemRow(order, order.items[i]),
              ],
              if (order.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No items on this order',
                    style: WaUi.body.copyWith(color: Cx.muted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (final row in _paymentBillRows(order))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.$1,
                          style: WaUi.caption.copyWith(color: Cx.muted),
                        ),
                      ),
                      Text(
                        row.$2,
                        style: WaUi.caption.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Cx.hairline),
              ),
              Row(
                children: [
                  Text(
                    'Total',
                    style: WaUi.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    totalText,
                    style: WaUi.body.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PillButton(
          label: 'View receipt',
          filled: false,
          onPressed: () => _openReceiptSheet(order),
        ),
      ],
    );
  }

  Widget _buildCustomerScaffold() {
    final order = _order;
    final hasActions = order != null && _hasBottomActions(order);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : order == null
                      ? _ErrorBody(
                          failed: _loadFailed,
                          onRetry: _loadOrder,
                        )
                      : RefreshIndicator(
                          color: Colors.black,
                          onRefresh: _loadOrder,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              hasActions ? 20 : 28,
                            ),
                            child: _buildCustomerBody(order),
                          ),
                        ),
            ),
            if (order != null && hasActions) _buildActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerBody(CatalogOrder order) {
    final totalText = formatMoney(order.totalAmount, currency: order.currency);
    final completed = order.status == OrderStatus.completed;
    final businessName =
        order.businessName.isNotEmpty ? order.businessName : 'Business';
    final photo = order.businessPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final catalog = order.catalogTypeLabel.isNotEmpty
        ? order.catalogTypeLabel
        : order.kindLabel;
    final address = order.displayFulfillmentAddress.isNotEmpty
        ? order.displayFulfillmentAddress
        : (order.deliveryArea.isNotEmpty
            ? order.deliveryArea
            : (order.isPickup ? 'Collect at store' : ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CxProgressBar(
            steps: CxProgressStep.forOrder(order),
            caption: CxProgressStep.captionFor(order),
          ),
        ),
        if (completed) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Cx.greenSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Cx.green.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Cx.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.isDelivery ? 'Delivered' : 'Completed',
                        style: WaUi.body.copyWith(
                          color: Cx.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.isDelivery
                            ? 'Your order has been delivered. Enjoy!'
                            : 'Your order is complete. Enjoy!',
                        style: WaUi.caption.copyWith(
                          color: Cx.text.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Material(
          color: Cx.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _viewProfile(
              userId: order.businessId.isEmpty ? null : order.businessId,
              username: order.businessUsername,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Cx.surface2,
                    backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            businessName[0].toUpperCase(),
                            style: WaUi.body.copyWith(
                              color: Cx.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WaUi.body.copyWith(
                            color: Cx.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (catalog.isNotEmpty) catalog,
                            if (address.isNotEmpty) address,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WaUi.caption.copyWith(
                            color: Cx.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Cx.muted),
                ],
              ),
            ),
          ),
        ),
        if (order.isDelivery && order.canOpenDeliveryMap) ...[
          const SizedBox(height: 10),
          Material(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openDeliveryMap(order),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.place_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open delivery address',
                            style: WaUi.body.copyWith(
                              color: Cx.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: WaUi.caption.copyWith(
                                color: Cx.muted,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        color: Cx.muted,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Order items',
          style: WaUi.body.copyWith(
            color: Cx.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: Cx.hairline),
                _cxItemRow(order, order.items[i]),
              ],
              if (order.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No items on this order',
                    style: WaUi.body.copyWith(color: Cx.muted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Cx.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (final row in _paymentBillRows(order))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.$1,
                          style: WaUi.caption.copyWith(color: Cx.muted),
                        ),
                      ),
                      Text(
                        row.$2,
                        style: WaUi.caption.copyWith(
                          color: Cx.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Cx.hairline),
              ),
              Row(
                children: [
                  Text(
                    'Total',
                    style: WaUi.body.copyWith(
                      color: Cx.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    totalText,
                    style: WaUi.body.copyWith(
                      color: Cx.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PillButton(
          label: 'View receipt',
          filled: false,
          onPressed: () => _openReceiptSheet(order),
        ),
      ],
    );
  }

  Widget _cxItemRow(CatalogOrder order, CatalogOrderLineItem item) {
    final variant = item.variantName.trim();
    final note = item.notes.trim();
    final img = item.imageUrl.trim();
    final line = formatMoney(
      item.price * item.quantity,
      currency: order.currency,
    );
    final sub = [
      if (variant.isNotEmpty) variant,
      if (note.isNotEmpty) note,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: img.isNotEmpty
                  ? Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Cx.surface2,
                        child: Icon(Icons.fastfood_rounded, color: Cx.muted),
                      ),
                    )
                  : const ColoredBox(
                      color: Cx.surface2,
                      child: Icon(Icons.fastfood_rounded, color: Cx.muted),
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
                  style: WaUi.body.copyWith(
                    color: Cx.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: WaUi.caption.copyWith(color: Cx.muted),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '×${item.quantity}',
                  style: WaUi.caption.copyWith(
                    color: Cx.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            line,
            style: WaUi.body.copyWith(
              color: Cx.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  (String tone, String badge) _statusVisual(CatalogOrder order) {
    return switch (order.status) {
      OrderStatus.completed => ('good', 'Done'),
      OrderStatus.cancelled => ('bad', 'Cancelled'),
      OrderStatus.noShow => ('bad', _noShowLabel(order)),
      OrderStatus.outForDelivery => (
          'live',
          order.isDelivery ? 'On the way' : 'Ready',
        ),
      OrderStatus.confirmed => ('live', 'In progress'),
      OrderStatus.held || OrderStatus.pending => (
          'warn',
          widget.isBusinessView ? 'Needs action' : 'Waiting',
        ),
    };
  }

  Widget _buildBody(CatalogOrder order, bool _) {
    final personName = widget.isBusinessView
        ? (order.displayCustomerName.isNotEmpty
            ? order.displayCustomerName
            : (order.isGuest ? 'Guest' : '—'))
        : order.businessName;
    final contactPhone = _contactPhone(order);
    final showFulfillment =
        (order.kind == 'order' || order.kind == 'table') &&
            (order.isDelivery || order.isPickup || order.orderTypeLabel.isNotEmpty);

    final profileId =
        widget.isBusinessView ? order.customerId : order.businessId;
    final profileUsername = widget.isBusinessView
        ? order.customerUsername
        : order.businessUsername;
    final canOpenProfile =
        profileId.trim().isNotEmpty || profileUsername.trim().isNotEmpty;

    final eta = _etaLabel(order);
    final billRows = _paymentBillRows(order);
    final totalText = formatMoney(
      order.totalAmount,
      currency: order.currency,
    );
    final meta = _metaLine(order);
    final terminal = _isTerminalStatus(order);
    final showTimeline = !terminal || _timelineExpanded;
    final itemCount = order.items.fold<int>(0, (s, e) => s + e.quantity);
    final statusVisual = _statusVisual(order);
    final whenRows = _whenRows(order);
    final paymentMeta = _paymentMetaRows(order);
    final fulfillExtras = _fulfillmentRows(order)
        .where((r) => r.$1 == 'Area' || r.$1 == 'Table' || r.$1 == 'Scheduled')
        .toList();

    const sectionGap = 20.0;
    const labelToPanel = 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Order progress — reference timeline with pulse on active step
        _OdPanel(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Order progress',
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (terminal)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(
                        () => _timelineExpanded = !_timelineExpanded,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          _timelineExpanded ? 'Hide' : 'Show',
                          style: WaUi.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (showTimeline) ...[
                const SizedBox(height: 18),
                if (!widget.isBusinessView)
                  _CustomerProgressBar(
                    steps: _customerProgressSteps(order),
                    caption: _customerProgressCaption(order),
                  )
                else
                  _OrderTimeline(entries: _timelineEntries(order)),
              ],
            ],
          ),
        ),
        // Outcome banner only when finished — live status lives in the timeline
        if (terminal) ...[
          const SizedBox(height: sectionGap),
          _StatusHero(
            title: _statusHeroTitle(order),
            subtitle: eta.isNotEmpty ? eta : _statusHeroFallback(order),
            meta: meta,
            tone: statusVisual.$1,
            badge: statusVisual.$2,
          ),
        ],
        const SizedBox(height: sectionGap),

        // Where / how — address map only (no live Track on Map / rider)
        if (showFulfillment) ...[
          _FulfillmentBanner(
            isDelivery: order.isDelivery,
            title: order.isDelivery
                ? 'Delivery'
                : (order.isPickup ? 'Pickup' : order.orderTypeLabel),
            subtitle: order.isDelivery
                ? (order.displayFulfillmentAddress.isNotEmpty
                    ? order.displayFulfillmentAddress
                    : (order.deliveryArea.isNotEmpty
                        ? order.deliveryArea
                        : (widget.isBusinessView
                            ? 'Deliver to customer'
                            : 'Delivery address pending')))
                : (order.scheduledFor.trim().isNotEmpty
                    ? 'Collect · ${_prettyDateTime(order.scheduledFor)}'
                    : 'Collect at store'),
            onMap: order.canOpenDeliveryMap
                ? () => _openDeliveryMap(order)
                : null,
            mapLabel: 'Address',
          ),
          if (fulfillExtras.isNotEmpty) ...[
            const SizedBox(height: 10),
            _OdNavTile(
              icon: Icons.info_outline_rounded,
              title: 'Fulfillment details',
              subtitle:
                  fulfillExtras.map((e) => '${e.$1}: ${e.$2}').join(' · '),
              onTap: () => _openInfoSheet(
                title: 'Fulfillment details',
                rows: fulfillExtras,
              ),
            ),
          ],
          const SizedBox(height: sectionGap),
        ],

        if (whenRows.isNotEmpty) ...[
          _OdNavTile(
            icon: Icons.event_outlined,
            title: order.isStay ? 'Stay details' : 'Schedule details',
            subtitle: whenRows.map((e) => e.$2).take(2).join(' · '),
            onTap: () => _openInfoSheet(
              title: order.isStay ? 'Stay details' : 'Schedule details',
              rows: whenRows,
            ),
          ),
          const SizedBox(height: sectionGap),
        ],

        // 4) Items receipt
        _OdSectionHeader(
          label: 'Items',
          trailing: itemCount > 0
              ? '$itemCount item${itemCount == 1 ? '' : 's'}'
              : null,
        ),
        const SizedBox(height: labelToPanel),
        _OdPanel(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: order.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No items on this order',
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < order.items.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: _Od.hairline,
                        ),
                      _OrderItemRow(
                        item: order.items[i],
                        currency: order.currency,
                        onTap: () =>
                            _showItemSheet(order.items[i], order.currency),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: sectionGap),

        // 5) Bill
        const _OdSectionHeader(label: 'Bill'),
        const SizedBox(height: labelToPanel),
        _OdPanel(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: WaUi.caption.copyWith(
                            color: BarqodyChrome.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalText,
                          style: WaUi.toolsTitleOf(
                            size: 28,
                            weight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PaymentStatusChip(
                    label: order.paymentStatusChipLabel,
                    tone: _paymentChipTone(order),
                  ),
                ],
              ),
              if (billRows.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: _Od.hairline),
                InkWell(
                  onTap: () => setState(() => _billExpanded = !_billExpanded),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          _billExpanded ? 'Hide breakdown' : 'View breakdown',
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _billExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_billExpanded) ...[
                  _InfoCard(rows: billRows),
                  const SizedBox(height: 4),
                ],
              ],
              if (paymentMeta.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(height: 1, thickness: 1, color: _Od.hairline),
                _OdNavTile(
                  dense: true,
                  icon: Icons.receipt_long_outlined,
                  title: 'Payment details',
                  subtitle: [
                    if (order.paymentLabel.isNotEmpty) order.paymentLabel,
                    if (order.publicPaymentRef.isNotEmpty) 'Ref available',
                    if (order.hasRefund) 'Refund info',
                  ].where((e) => e.trim().isNotEmpty).join(' · '),
                  onTap: () => _openInfoSheet(
                    title: 'Payment details',
                    rows: paymentMeta,
                    caption: 'Method, reference, and refund info for this order',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: sectionGap),

        // 6) Who
        _OdSectionHeader(
          label: widget.isBusinessView ? 'Customer' : 'Business',
        ),
        const SizedBox(height: labelToPanel),
        _OdPanel(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _PersonRow(
                  name: personName,
                  username: profileUsername,
                  subtitle: widget.isBusinessView && contactPhone.isNotEmpty
                      ? contactPhone
                      : '',
                  badge:
                      widget.isBusinessView && order.isGuest ? 'Guest' : null,
                  photoUrl: widget.isBusinessView
                      ? order.customerPhoto
                      : order.businessPhoto,
                  avatarColor: _avatarColor(personName),
                  showChevron: canOpenProfile &&
                      !(widget.isBusinessView && contactPhone.isNotEmpty),
                  onTap: canOpenProfile
                      ? () => _viewProfile(
                            userId:
                                profileId.trim().isEmpty ? null : profileId,
                            username: profileUsername,
                          )
                      : null,
                ),
              ),
              if (widget.isBusinessView && contactPhone.isNotEmpty) ...[
                const SizedBox(width: 8),
                _IconActionButton(
                  icon: Icons.call_outlined,
                  onTap: () => _openPhone(contactPhone),
                ),
                const SizedBox(width: 8),
                _IconActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => _openWhatsApp(contactPhone),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildActions(CatalogOrder order) {
    final held = widget.isBusinessView && order.status == OrderStatus.held;
    final pending =
        widget.isBusinessView && order.status == OrderStatus.pending;
    final confirmed =
        widget.isBusinessView && order.status == OrderStatus.confirmed;
    final onTheWay =
        widget.isBusinessView && order.status == OrderStatus.outForDelivery;
    final refundOnly = widget.isBusinessView &&
        order.canBusinessRefund &&
        !held &&
        !pending &&
        !confirmed &&
        !onTheWay;
    final pay = !widget.isBusinessView && order.canCustomerPayNow;
    final claim = !widget.isBusinessView && order.claimEligible && !pay;
    final cancel = !widget.isBusinessView && order.canCustomerCancel;
    final doneComplete = !widget.isBusinessView &&
        _showDoneActions(order) &&
        order.status == OrderStatus.completed;

    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: _Od.hairline, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                label: 'Confirm order',
                enabled: !_isUpdating,
                loading: _isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.confirmed,
                  title: 'Confirm this order and start preparing?',
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
              PillButton(
                label: order.isDelivery
                    ? 'Out for delivery'
                    : 'Mark as ready',
                enabled: !_isUpdating,
                loading: _isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.outForDelivery,
                  title: order.isDelivery
                      ? 'Mark this order out for delivery?'
                      : 'Mark this order ready for pickup?',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OutlineActionButton(
                      label: _noShowActionLabel(order),
                      enabled: !_isUpdating,
                      onPressed: () => _confirmThen(
                        OrderStatus.noShow,
                        title: _noShowConfirmTitle(order),
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
            ] else if (onTheWay) ...[
              PillButton(
                label: _completeActionLabel(order),
                enabled: !_isUpdating,
                loading: _isUpdating,
                onPressed: () => _confirmThen(
                  OrderStatus.completed,
                  title: _completeConfirmTitle(order),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OutlineActionButton(
                      label: _noShowActionLabel(order),
                      enabled: !_isUpdating,
                      onPressed: () => _confirmThen(
                        OrderStatus.noShow,
                        title: _noShowConfirmTitle(order),
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
            ] else if (refundOnly) ...[
              PillButton(
                label: 'Issue full refund',
                filled: false,
                enabled: !_isUpdating,
                onPressed: _refundPaidOrder,
              ),
            ] else if (doneComplete) ...[
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
            ] else ...[
              // Customer: Pay now primary, Cancel secondary.
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

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: Colors.black),
        ),
      ),
    );
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
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: const Color(0xFFE0E0E5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                label,
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  height: 1,
                  color: Colors.black,
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
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 22, color: Colors.black),
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

/// Local order-detail design tokens (quiet receipt).
class _Od {
  static const Color panel = Color(0xFFF6F6F4);
  static const Color hairline = Color(0xFFE8E8E4);
  static const Color delivery = Color(0xFFE8EEF5);
  static const Color pickup = Color(0xFFF1F0EC);
  static const Color goodBg = Color(0xFFE7F4EA);
  static const Color goodFg = Color(0xFF1B5E3B);
  static const Color warnBg = Color(0xFFFFF1E0);
  static const Color warnFg = Color(0xFF8A4B12);
  static const Color badBg = Color(0xFFFCECEC);
  static const Color badFg = Color(0xFFB42318);
  static const Color liveBg = Color(0xFF111111);
  static const Color liveFg = Colors.white;
}

class _OdPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _OdPanel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 4, 14, 4),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _Od.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _OdSectionHeader extends StatelessWidget {
  final String label;
  final String? trailing;

  const _OdSectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: WaUi.body.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
        if ((trailing ?? '').trim().isNotEmpty)
          Text(
            trailing!.trim(),
            style: WaUi.caption.copyWith(
              color: BarqodyChrome.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _OdNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dense;

  const _OdNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = dense ? 12.0 : 16.0;
    return Material(
      color: dense ? Colors.transparent : _Od.panel,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            dense ? 0 : 14,
            dense ? 12 : 14,
            dense ? 0 : 10,
            dense ? 8 : 14,
          ),
          child: Row(
            children: [
              Container(
                width: dense ? 36 : 40,
                height: dense ? 36 : 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: dense ? 18 : 20, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
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
    final unit = formatMoney(item.price, currency: currency);
    final line = formatMoney(item.lineTotal, currency: currency);
    final note = item.notes.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: item.imageUrl.trim().isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: Colors.white,
                            child: Icon(
                              Icons.image_outlined,
                              color: BarqodyChrome.secondaryText,
                              size: 20,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: Colors.white,
                          child: Icon(
                            Icons.image_outlined,
                            color: BarqodyChrome.secondaryText,
                            size: 20,
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
                      '${item.quantity}× ${item.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: Colors.black,
                      ),
                    ),
                    if (item.configurationLabel.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.configurationLabel.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      unit,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: _Od.warnFg,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.caption.copyWith(
                                color: _Od.warnFg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                line,
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final String tone;
  final String badge;

  const _StatusHero({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.tone,
    required this.badge,
  });

  (Color, Color) _pillColors() {
    switch (tone) {
      case 'good':
        return (_Od.goodBg, _Od.goodFg);
      case 'bad':
        return (_Od.badBg, _Od.badFg);
      case 'live':
        return (_Od.liveBg, _Od.liveFg);
      case 'warn':
        return (_Od.warnBg, _Od.warnFg);
      default:
        return (const Color(0xFFEEEEEE), Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _pillColors();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.$1,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge,
            style: WaUi.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.$2,
              fontSize: 11.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: WaUi.toolsTitleOf(
            size: 26,
            weight: FontWeight.w800,
            color: Colors.black,
            height: 1.15,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: WaUi.body.copyWith(
              color: const Color(0xFF5C5C62),
              height: 1.4,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
        if (meta.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            meta,
            style: WaUi.caption.copyWith(
              color: BarqodyChrome.secondaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final row in visible) _SummaryKV(label: row.$1, value: row.$2),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                fontSize: 14,
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
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 14,
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
  final bool showChevron;
  final VoidCallback? onTap;

  const _PersonRow({
    required this.name,
    required this.username,
    this.subtitle = '',
    this.badge,
    this.photoUrl,
    required this.avatarColor,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : '—';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final canOpen = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WaUi.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
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
                            color: Colors.white,
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
                  if (username.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${username.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canOpen && showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: BarqodyChrome.secondaryText,
              ),
          ],
        ),
      ),
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
  /// Progress chrome matches Tapni black; red only for terminal-bad steps.
  static const Color accent = Colors.black;
  static const Color bad = Color(0xFFE53935);
  static const Color muted = Color(0xFFC8C8CC);
  static const Color lineMuted = Color(0xFFE6E6EA);

  final List<_TimelineEntry> entries;

  const _OrderTimeline({required this.entries});

  String _fmt(DateTime? at) {
    if (at == null) return '';
    return DateFormat('MMM d, y, h:mm a').format(at.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            timeLabel: _fmt(entries[i].at),
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatefulWidget {
  final _TimelineEntry entry;
  final String timeLabel;
  final bool isLast;

  const _TimelineRow({
    required this.entry,
    required this.timeLabel,
    required this.isLast,
  });

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;

  bool get _shouldPulse =>
      widget.entry.active && !widget.entry.isTerminalBad;

  @override
  void initState() {
    super.initState();
    if (_shouldPulse) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _TimelineRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldPulse && _pulseCtrl == null) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    } else if (!_shouldPulse && _pulseCtrl != null) {
      _pulseCtrl!.dispose();
      _pulseCtrl = null;
    }
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  Widget _activeMarker() {
    const accent = _OrderTimeline.accent;
    final core = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: accent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
          ),
        ),
      ),
    );

    final pulse = _pulseCtrl;
    if (pulse == null) {
      return SizedBox(width: 32, height: 32, child: Center(child: core));
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = Curves.easeOut.transform(pulse.value);
          final scale = 1.0 + (t * 1.15);
          final opacity = (1.0 - t) * 0.32;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: opacity * 0.28),
                    border: Border.all(
                      color: accent.withValues(alpha: opacity),
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
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isLast = widget.isLast;
    final timeLabel = widget.timeLabel;
    final isDone = entry.done && !entry.active;
    final isHot = entry.done || entry.active;
    const accent = _OrderTimeline.accent;
    const bad = _OrderTimeline.bad;
    const muted = _OrderTimeline.muted;

    final titleColor = entry.isTerminalBad
        ? bad
        : (isHot ? Colors.black : muted);
    final subColor = isHot
        ? const Color(0xFF6B6B70)
        : const Color(0xFFC5C5CA);

    Widget marker;
    if (entry.isTerminalBad && entry.done) {
      marker = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: bad, width: 1.8),
        ),
        child: const Icon(Icons.close_rounded, size: 13, color: bad),
      );
    } else if (isDone) {
      marker = Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: accent,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    } else if (entry.active) {
      marker = _activeMarker();
    } else {
      marker = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: muted,
        ),
      );
    }

    // Line under done steps stays accent; under active/upcoming stays muted.
    final lineColor =
        isDone ? accent : _OrderTimeline.lineMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                SizedBox(
                  height: 32,
                  child: Center(child: marker),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 4,
                bottom: isLast ? 2 : 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            height: 1.2,
                            fontSize: 15,
                          ),
                        ),
                        if (entry.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            entry.subtitle,
                            style: WaUi.caption.copyWith(
                              color: subColor,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (timeLabel.isNotEmpty && isHot) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        timeLabel,
                        textAlign: TextAlign.right,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          height: 1.25,
                        ),
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
  final String mapLabel;

  const _FulfillmentBanner({
    required this.isDelivery,
    required this.title,
    required this.subtitle,
    this.onMap,
    this.mapLabel = 'Address',
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDelivery ? _Od.delivery : _Od.pickup;
    final icon =
        isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onMap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: const Color(0xFF5C5C62),
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onMap != null) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mapLabel,
                      style: WaUi.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerProgressStep {
  final String title;
  final IconData icon;
  final bool done;
  final bool active;
  final bool bad;

  const _CustomerProgressStep({
    required this.title,
    required this.icon,
    this.done = false,
    this.active = false,
    this.bad = false,
  });
}

class _CustomerProgressBar extends StatelessWidget {
  final List<_CustomerProgressStep> steps;
  final String caption;

  const _CustomerProgressBar({
    required this.steps,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              ? const Color(0xFFE53935)
                              : Colors.black)
                          : const Color(0xFFE0E0E5),
                    ),
                  ),
                ),
              _CustomerProgressNode(step: steps[i]),
            ],
          ],
        ),
        if (caption.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: WaUi.caption.copyWith(
              color: BarqodyChrome.secondaryText,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomerProgressNode extends StatefulWidget {
  final _CustomerProgressStep step;

  const _CustomerProgressNode({required this.step});

  @override
  State<_CustomerProgressNode> createState() => _CustomerProgressNodeState();
}

class _CustomerProgressNodeState extends State<_CustomerProgressNode>
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
  void didUpdateWidget(covariant _CustomerProgressNode oldWidget) {
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
    final color = step.bad
        ? const Color(0xFFE53935)
        : (hot ? Colors.black : const Color(0xFFC8C8CC));

    Widget circle;
    if (step.done && !step.active) {
      circle = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: step.bad ? Colors.white : Colors.black,
          border: step.bad ? Border.all(color: color, width: 1.8) : null,
        ),
        child: Icon(
          step.bad ? Icons.close_rounded : Icons.check_rounded,
          size: 18,
          color: step.bad ? color : Colors.white,
        ),
      );
    } else if (step.active) {
      final core = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color, width: 2.2),
        ),
        child: Icon(step.icon, size: 17, color: color),
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
                              color: color.withValues(alpha: (1 - t) * 0.35),
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
          color: const Color(0xFFF2F2F5),
          border: Border.all(color: const Color(0xFFE0E0E5)),
        ),
        child: Icon(step.icon, size: 16, color: color),
      );
    }

    return SizedBox(
      width: 64,
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
      bg = _Od.goodBg;
      fg = _Od.goodFg;
    } else if (tone == 'warn') {
      bg = _Od.warnBg;
      fg = _Od.warnFg;
    } else if (tone == 'muted') {
      bg = const Color(0xFFEEEEEE);
      fg = BarqodyChrome.secondaryText;
    } else {
      bg = Colors.white;
      fg = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: WaUi.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.1,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReceiptDash extends StatelessWidget {
  final bool heavy;

  const _ReceiptDash({this.heavy = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.5,
      width: double.infinity,
      child: CustomPaint(
        painter: _ReceiptDashPainter(heavy: heavy),
      ),
    );
  }
}

class _ReceiptDashPainter extends CustomPainter {
  final bool heavy;

  _ReceiptDashPainter({required this.heavy});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = heavy ? Colors.black : const Color(0xFFBDBDBD)
      ..strokeWidth = heavy ? 1.6 : 1.1
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptDashPainter oldDelegate) =>
      oldDelegate.heavy != heavy;
}

class _ReceiptEdgePainter extends CustomPainter {
  final bool top;

  _ReceiptEdgePainter({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const zig = 8.0;
    if (top) {
      path.moveTo(0, size.height);
      var x = 0.0;
      var up = true;
      while (x < size.width) {
        path.lineTo(x + zig / 2, up ? 0 : size.height);
        x += zig / 2;
        up = !up;
      }
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      var x = 0.0;
      var down = true;
      while (x < size.width) {
        path.lineTo(x + zig / 2, down ? size.height : 0);
        x += zig / 2;
        down = !down;
      }
      path.lineTo(size.width, 0);
      path.close();
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFF2F2F7));
  }

  @override
  bool shouldRepaint(covariant _ReceiptEdgePainter oldDelegate) =>
      oldDelegate.top != top;
}

class _ReceiptKv extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptKv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: WaUi.caption.copyWith(
                color: BarqodyChrome.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WaUi.caption.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemLine extends StatelessWidget {
  final int qty;
  final String name;
  final String amount;
  final String detail;

  const _ReceiptItemLine({
    required this.qty,
    required this.name,
    required this.amount,
    this.detail = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${qty}x',
              style: WaUi.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              amount,
              style: WaUi.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              detail,
              style: WaUi.caption.copyWith(
                color: BarqodyChrome.secondaryText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

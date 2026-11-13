import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/catalog/checkout_payment_method_sheet.dart';
import 'package:tapni_app/screens/catalog/order_placed_screen.dart';
import 'package:tapni_app/screens/explore_delivery_address_sheet.dart';
import 'package:tapni_app/screens/login_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/catalog_checkout.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/own_catalog_guard.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/storefront_status_apply.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/app_toast.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Cart → checkout: contact, payment, address, bill, place order.
class ExploreCheckoutScreen extends StatefulWidget {
  const ExploreCheckoutScreen({super.key});

  @override
  State<ExploreCheckoutScreen> createState() => _ExploreCheckoutScreenState();
}

class _ExploreCheckoutScreenState extends State<ExploreCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _placing = false;
  bool _prefilled = false;

  bool get _isSignedIn {
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    return token.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromProfile();
      _refreshDeliveryFees();
    });
  }

  void _prefillFromProfile() {
    if (_prefilled || !mounted) return;
    final profile = context.read<ProfileProvider>().profile;
    if (_nameCtrl.text.trim().isEmpty && profile.name.trim().isNotEmpty) {
      _nameCtrl.text = profile.name.trim();
    }
    if (_phoneCtrl.text.trim().isEmpty && profile.phone.trim().isNotEmpty) {
      _phoneCtrl.text = profile.phone.trim();
    }
    _prefilled = true;
    if (mounted) setState(() {});
  }

  Future<void> _refreshDeliveryFees() async {
    if (!mounted) return;
    final cart = context.read<ExploreCartProvider>();
    final slugs = cart.vendors
        .map((v) => v.websiteSlug.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (slugs.isEmpty) return;
    final repo = CatalogRepo();
    for (final slug in slugs) {
      try {
        final res = await repo.getPublicStorefrontStatus(websiteSlug: slug);
        if (!mounted || !res.success) continue;
        final raw = res.data;
        final map = raw is Map
            ? Map<String, dynamic>.from(
                raw['data'] is Map ? raw['data'] as Map : raw,
              )
            : <String, dynamic>{};
        if (map.isEmpty) continue;
        applyStorefrontStatusMap(cart, map, websiteSlug: slug);
      } catch (_) {}
    }
  }

  Future<void> _pickSchedule() async {
    final cart = context.read<ExploreCartProvider>();
    final now = DateTime.now();
    final initial = () {
      final raw = cart.scheduledFor.trim();
      if (raw.isEmpty) {
        return now.add(const Duration(hours: 1));
      }
      final parsed = DateTime.tryParse(raw);
      return parsed ?? now.add(const Duration(hours: 1));
    }();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 14)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (picked.isBefore(now.add(const Duration(minutes: 20)))) {
      showAppToast(
        context,
        'Pick a time at least 20 minutes from now',
        kind: AppToastKind.warning,
      );
      return;
    }
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    cart.setScheduledFor('$y-$m-$d'
        'T$hh:$mm');
  }

  String _scheduleLabel(String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return 'Choose time';
    final local = TimeOfDay.fromDateTime(parsed);
    final date =
        '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
    return '$date · ${local.format(context)}';
  }

  CheckoutPaymentMethod get _payMethod {
    final cart = context.read<ExploreCartProvider>();
    return cart.paymentMethod == 'online'
        ? CheckoutPaymentMethod.online
        : CheckoutPaymentMethod.cashOnDelivery;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(
      AppPageRoute(builder: (_) => const LoginScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editAddress() async {
    await showExploreDeliveryAddressSheet(context);
  }

  List<Map<String, dynamic>> _orderItems(List<ExploreCartLine> lines) {
    return lines
        .map(
          (line) => {
            if (line.item.id.isNotEmpty) 'catalogItemId': line.item.id,
            'name': line.item.name,
            'price': line.unitPrice,
            'quantity': line.quantity,
            if (line.notes.isNotEmpty) 'notes': line.notes,
            if (line.item.category.isNotEmpty) 'category': line.item.category,
            if (line.item.imageUrl.isNotEmpty) 'image': line.item.imageUrl,
            if (line.variantId.isNotEmpty) 'variantId': line.variantId,
            if (line.optionIds.isNotEmpty) 'optionIds': line.optionIds,
            if (line.displayConfigurationLabel.isNotEmpty)
              'configurationLabel': line.displayConfigurationLabel,
          },
        )
        .toList();
  }

  List<_VendorPlaceBatch> _batchesForVendor(ExploreCartVendor vendor) {
    final stay = <ExploreCartLine>[];
    final appt = <ExploreCartLine>[];
    final order = <ExploreCartLine>[];
    for (final line in vendor.lines) {
      if (line.hasStay) {
        stay.add(line);
      } else if (line.hasAppointment) {
        appt.add(line);
      } else {
        order.add(line);
      }
    }

    final batches = <_VendorPlaceBatch>[];
    for (final line in stay) {
      batches.add(
        _VendorPlaceBatch(
          lines: [line],
          bookingKind: 'stay',
          bookingDate: '',
          bookingTime: '',
          resourceId: line.resourceId,
          checkInDate: line.checkInDate,
          checkOutDate: line.checkOutDate,
        ),
      );
    }

    final groups = <String, List<ExploreCartLine>>{};
    for (final line in appt) {
      final key = [
        line.resourceId,
        line.bookingDate,
        line.bookingTime,
      ].join('|');
      groups.putIfAbsent(key, () => []).add(line);
    }
    for (final entry in groups.entries) {
      final first = entry.value.first;
      batches.add(
        _VendorPlaceBatch(
          lines: entry.value,
          bookingKind: 'appointment',
          bookingDate: first.bookingDate,
          bookingTime: first.bookingTime,
          resourceId: first.resourceId,
          checkInDate: '',
          checkOutDate: '',
        ),
      );
    }

    if (order.isNotEmpty) {
      batches.add(
        _VendorPlaceBatch(
          lines: order,
          bookingKind: 'order',
          bookingDate: '',
          bookingTime: '',
          resourceId: '',
          checkInDate: '',
          checkOutDate: '',
        ),
      );
    }
    return batches;
  }

  Future<void> _submit() async {
    final cart = context.read<ExploreCartProvider>();
    if (cart.isEmpty) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isDelivery = cart.isDelivery;
    final signedIn = _isSignedIn;
    final profile = context.read<ProfileProvider>().profile;
    final orderName = _nameCtrl.text.trim();
    final orderPhone = _phoneCtrl.text.trim();
    var customerUsername = signedIn ? (profile.username ?? '') : '';
    var customerName = orderName.isNotEmpty
        ? orderName
        : (signedIn ? profile.name : '');
    String? guestPhone = orderPhone;
    final displayAddress = cart.deliveryDisplayAddress.trim();
    var guestAddress = displayAddress;
    final deliveryLat = isDelivery ? cart.deliveryLat : null;
    final deliveryLng = isDelivery ? cart.deliveryLng : null;
    final prepMins = cart.prepTimeMinutes;
    var guestNotes = cart.deliveryNotes;
    if (signedIn) {
      final contactLine = 'Order contact: $orderName · $orderPhone';
      guestNotes =
          guestNotes.isEmpty ? contactLine : '$contactLine\n$guestNotes';
    }

    if (cart.belowMinOrder) {
      showAppToast(
        context,
        'Minimum order is ${formatMoney(cart.minOrderAmount, currency: cart.activeVendors.isNotEmpty ? cart.activeVendors.first.currency : 'PKR')}',
        kind: AppToastKind.warning,
      );
      return;
    }

    if (isDelivery) {
      if (!cart.acceptsDelivery) {
        showAppToast(
          context,
          'Delivery is not available right now',
          kind: AppToastKind.warning,
        );
        return;
      }
      if (cart.deliveryAreas.isNotEmpty && cart.deliveryArea.trim().isEmpty) {
        showAppToast(
          context,
          'Choose a delivery area',
          kind: AppToastKind.warning,
        );
        return;
      }
      if (guestAddress.isEmpty) {
        showAppToast(
          context,
          'Enter a delivery address',
          kind: AppToastKind.warning,
        );
        await _editAddress();
        return;
      }
    } else {
      if (!cart.acceptsPickup) {
        showAppToast(
          context,
          'Pickup is not available right now',
          kind: AppToastKind.warning,
        );
        return;
      }
      guestAddress = '';
    }

    if (cart.canScheduleWhileClosed && cart.scheduledFor.trim().isEmpty) {
      showAppToast(
        context,
        'Restaurant is closed — pick a schedule time',
        kind: AppToastKind.warning,
      );
      await _pickSchedule();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final vendors = List<ExploreCartVendor>.from(cart.vendors)
        .where((v) => v.lines.isNotEmpty)
        .toList();
    if (vendors.isEmpty) return;

    if (!signedIn) {
      final missingSlug = vendors.any((v) => v.websiteSlug.trim().isEmpty);
      if (missingSlug) {
        showAppToastMessenger(
          messenger,
          'Guest checkout needs a website cart. Sign in or add items from a business website.',
          kind: AppToastKind.warning,
        );
        return;
      }
    }

    if (signedIn &&
        vendors.any(
          (v) => OwnCatalogGuard.isOwnBusinessOf(
            context,
            businessId: v.businessId,
            businessUsername: v.businessUsername,
            websiteSlug: v.websiteSlug,
          ),
        )) {
      showAppToastMessenger(
        messenger,
        OwnCatalogGuard.message,
        kind: AppToastKind.warning,
      );
      return;
    }

    final blocked = vendors.where((v) => v.orderBlockedLabel != null).toList();
    if (blocked.isNotEmpty) {
      showAppToastMessenger(
        messenger,
        blocked.first.ordersPaused
            ? "We're not accepting orders right now. Please check back soon!"
            : 'This restaurant is closed right now. Please check back soon!',
        kind: AppToastKind.warning,
      );
      return;
    }

    setState(() => _placing = true);
    final repo = CatalogRepo();
    final placed = <_PlacedExploreOrder>[];
    final orderType = isDelivery ? 'delivery' : 'takeaway';
    final payMethod = _payMethod;
    final tipAmount = cart.effectiveTip;
    final scheduledFor = cart.scheduleOrdersEnabled
        ? cart.scheduledFor.trim()
        : '';
    final deliveryArea =
        isDelivery ? cart.deliveryArea.trim() : '';

    for (final vendor in vendors) {
      final batches = _batchesForVendor(vendor);
      var vendorOk = true;
      for (final batch in batches) {
        final orderItems = _orderItems(batch.lines);
        final itemCount = batch.lines.fold<int>(
          0,
          (sum, line) => sum + line.quantity,
        );
        final batchTotal = batch.lines.fold<double>(
          0,
          (sum, line) => sum + line.lineTotal,
        );
        final vendorFee = isDelivery
            ? vendor.deliveryFeeForSubtotal(vendor.total)
            : 0.0;
        // Tip applied once on the first vendor/batch only.
        final tipForBatch =
            placed.isEmpty && vendor == vendors.first ? tipAmount : 0.0;
        final chargeTotal = batchTotal + vendorFee + tipForBatch;
        final slug = vendor.websiteSlug.trim();
        final useWebsiteOrder = slug.isNotEmpty;
        final isMenuOrder = batch.bookingKind == 'order';

        final order = await CatalogCheckout.placeWithPayment(
          context: context,
          presetMethod: payMethod,
          pushSuccessScreen: false,
          totalAmount: chargeTotal,
          currency: vendor.currency,
          customerName: customerName,
          customerUsername: customerUsername,
          guestPhone: guestPhone,
          businessName: vendor.businessName,
          businessUsername: vendor.businessUsername,
          totalItems: itemCount,
          bookingKind: batch.bookingKind,
          publicGuestPayment: !signedIn,
          placeOrder: ({
            required String paymentMethod,
            required String idempotencyKey,
          }) {
            if (useWebsiteOrder) {
              return repo.placePublicOrder(
                websiteSlug: slug,
                items: orderItems,
                guestName: customerName,
                guestPhone: orderPhone,
                guestAddress: guestAddress.isEmpty ? null : guestAddress,
                notes: guestNotes.isEmpty ? null : guestNotes,
                orderType: isMenuOrder ? orderType : null,
                deliveryArea:
                    deliveryArea.isEmpty ? null : deliveryArea,
                scheduledFor:
                    scheduledFor.isEmpty ? null : scheduledFor,
                tipAmount: tipForBatch > 0 ? tipForBatch : null,
                fulfillmentLat: deliveryLat,
                fulfillmentLng: deliveryLng,
                prepTimeMinutes: prepMins > 0 ? prepMins : null,
                bookingDate:
                    batch.bookingDate.isEmpty ? null : batch.bookingDate,
                bookingTime:
                    batch.bookingTime.isEmpty ? null : batch.bookingTime,
                resourceId:
                    batch.resourceId.isEmpty ? null : batch.resourceId,
                bookingKind: batch.bookingKind,
                checkInDate:
                    batch.checkInDate.isEmpty ? null : batch.checkInDate,
                checkOutDate:
                    batch.checkOutDate.isEmpty ? null : batch.checkOutDate,
                paymentMethod: paymentMethod,
                idempotencyKey: idempotencyKey,
                authorization: signedIn,
              );
            }
            return repo.placeOrder(
              businessId: vendor.businessId,
              businessLinkId: vendor.businessLinkId,
              catalogType: vendor.catalogType,
              items: orderItems,
              orderType: isMenuOrder ? orderType : null,
              guestPhone: orderPhone.isEmpty ? null : orderPhone,
              fulfillmentAddress:
                  guestAddress.isEmpty ? null : guestAddress,
              fulfillmentNotes: guestNotes.isEmpty ? null : guestNotes,
              deliveryArea:
                  deliveryArea.isEmpty ? null : deliveryArea,
              scheduledFor:
                  scheduledFor.isEmpty ? null : scheduledFor,
              tipAmount: tipForBatch > 0 ? tipForBatch : null,
              fulfillmentLat: deliveryLat,
              fulfillmentLng: deliveryLng,
              prepTimeMinutes: prepMins > 0 ? prepMins : null,
              bookingDate:
                  batch.bookingDate.isEmpty ? null : batch.bookingDate,
              bookingTime:
                  batch.bookingTime.isEmpty ? null : batch.bookingTime,
              resourceId:
                  batch.resourceId.isEmpty ? null : batch.resourceId,
              bookingKind: batch.bookingKind,
              checkInDate:
                  batch.checkInDate.isEmpty ? null : batch.checkInDate,
              checkOutDate:
                  batch.checkOutDate.isEmpty ? null : batch.checkOutDate,
              paymentMethod: paymentMethod,
              idempotencyKey: idempotencyKey,
            );
          },
        );

        if (order == null) {
          vendorOk = false;
          break;
        }

        placed.add(
          _PlacedExploreOrder(
            businessName: vendor.businessName,
            businessUsername: vendor.businessUsername.isNotEmpty
                ? vendor.businessUsername
                : vendor.websiteSlug,
            currency: vendor.currency.isNotEmpty
                ? vendor.currency
                : order.currency,
            token: order.tokenNumber,
            orderId: order.id,
            totalItems: itemCount,
            totalAmount:
                order.totalAmount > 0 ? order.totalAmount : batchTotal,
            bookingKind: batch.bookingKind,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            paymentSimulated: order.paymentSimulated,
          ),
        );
      }
      if (!vendorOk) break;
      cart.removeVendor(vendor.businessLinkId);
    }

    if (!mounted) return;
    setState(() => _placing = false);
    if (placed.isEmpty) return;

    if (placed.length == 1) {
      final one = placed.first;
      await nav.pushReplacement(
        AppPageRoute(
          builder: (_) => OrderPlacedScreen(
            token: one.token,
            customerUsername: customerUsername,
            customerName: customerName,
            guestPhone: guestPhone,
            businessUsername: one.businessUsername,
            businessName: one.businessName,
            totalItems: one.totalItems,
            totalAmount: one.totalAmount,
            currency: one.currency,
            orderId: one.orderId,
            bookingKind: one.bookingKind,
            paymentMethod: one.paymentMethod,
            paymentStatus: one.paymentStatus,
            paymentSimulated: one.paymentSimulated,
            orderType: orderType,
            fulfillmentAddress: isDelivery && displayAddress.isNotEmpty
                ? displayAddress
                : null,
          ),
        ),
      );
      return;
    }

    showAppToastMessenger(
      messenger,
      '${placed.length} orders placed — view in My Orders & Bookings',
      kind: AppToastKind.success,
    );
    await nav.pushReplacement(
      AppPageRoute(
        builder: (_) => const OrdersListScreen(isBusinessView: false),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: BarqodyChrome.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  bool _needsFulfillment(List<ExploreCartVendor> vendors) {
    return vendors.any(
      (v) =>
          v.catalogType == 'menu' ||
          v.catalogType == 'catalog' ||
          v.catalogType == 'products' ||
          v.websiteSlug.trim().isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<ExploreCartProvider>();
    final vendors = cart.vendors.where((v) => v.lines.isNotEmpty).toList();
    final signedIn = _isSignedIn;
    final currencies = vendors.map((v) => v.currency).toSet();
    final isDelivery = cart.isDelivery;
    final deliveryTotal = cart.deliveryFeesTotal;
    final tipTotal = cart.effectiveTip;
    final payable = cart.payableTotal;
    final totalMoney = currencies.length == 1
        ? formatMoney(payable, currency: currencies.first)
        : null;
    final moneyCur = currencies.length == 1 ? currencies.first : null;
    final needsFulfill = _needsFulfillment(vendors);
    final isOnline = cart.paymentMethod == 'online';
    final placeLabel = totalMoney == null
        ? context.l10n.placeOrder
        : '${context.l10n.placeOrder} ($totalMoney)';
    final areas = cart.deliveryAreas;
    final showTips = cart.tipsEnabled;
    final showSchedule = cart.scheduleOrdersEnabled;
    final tipPresets = <double>[0, 50, 100, 200];

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Checkout'),
            Expanded(
              child: vendors.isEmpty
                  ? Center(
                      child: Text(
                        'Your cart is empty',
                        style: WaUi.body.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          AppAppear(
                            index: 0,
                            child: _section(
                              title: 'Payment',
                              child: _PaySegment(
                                isOnline: isOnline,
                                onChanged: (online) => cart.setPaymentMethod(
                                  online ? 'online' : 'cash_on_delivery',
                                ),
                              ),
                            ),
                          ),
                          if (needsFulfill && isDelivery) ...[
                            const SizedBox(height: 12),
                            AppAppear(
                              index: 1,
                              child: _CheckoutNavCard(
                                icon: Icons.location_on_outlined,
                                title: 'Deliver address',
                                value: cart.deliveryDisplayAddress.isEmpty
                                    ? 'Add address'
                                    : cart.deliveryDisplayAddress,
                                onTap: _editAddress,
                              ),
                            ),
                            if (areas.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              AppAppear(
                                index: 2,
                                child: _section(
                                  title: 'Delivery area',
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final area in areas)
                                        _CheckoutChip(
                                          label: area,
                                          selected: cart.deliveryArea == area,
                                          onTap: () =>
                                              cart.setDeliveryArea(area),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (needsFulfill && !isDelivery) ...[
                            const SizedBox(height: 12),
                            AppAppear(
                              index: 1,
                              child: _CheckoutNavCard(
                                icon: Icons.storefront_outlined,
                                title: 'Pickup',
                                value: vendors.first.businessName.isNotEmpty
                                    ? vendors.first.businessName
                                    : 'Pickup at venue',
                                onTap: null,
                              ),
                            ),
                          ],
                          if (showSchedule) ...[
                            const SizedBox(height: 12),
                            AppAppear(
                              index: 3,
                              child: _CheckoutNavCard(
                                icon: Icons.schedule_rounded,
                                title: cart.canScheduleWhileClosed
                                    ? 'Schedule (required)'
                                    : 'Schedule (optional)',
                                value: cart.scheduledFor.isEmpty
                                    ? (cart.canScheduleWhileClosed
                                        ? 'Pick a time'
                                        : 'As soon as possible')
                                    : _scheduleLabel(cart.scheduledFor),
                                onTap: _pickSchedule,
                                onClear: cart.scheduledFor.isEmpty ||
                                        cart.canScheduleWhileClosed
                                    ? null
                                    : () => cart.setScheduledFor(''),
                              ),
                            ),
                          ],
                          if (cart.prepTimeLabel.isNotEmpty &&
                              cart.scheduledFor.isEmpty) ...[
                            const SizedBox(height: 12),
                            AppAppear(
                              index: 3,
                              child: _CheckoutNavCard(
                                icon: Icons.timer_outlined,
                                title: isDelivery
                                    ? 'Estimated prep'
                                    : 'Ready in',
                                value: cart.prepTimeLabel,
                                onTap: null,
                              ),
                            ),
                          ],
                          if (showTips) ...[
                            const SizedBox(height: 12),
                            AppAppear(
                              index: 4,
                              child: _section(
                                title: 'Tip',
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tip in tipPresets)
                                      _CheckoutChip(
                                        label: tip <= 0
                                            ? 'No tip'
                                            : (moneyCur == null
                                                ? tip.toStringAsFixed(0)
                                                : formatMoney(
                                                    tip,
                                                    currency: moneyCur,
                                                  )),
                                        selected: tipTotal == tip ||
                                            (tip <= 0 && tipTotal <= 0),
                                        onTap: () => cart.setTipAmount(tip),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          AppAppear(
                            index: 5,
                            child: _section(
                              title: 'Contact',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _nameCtrl,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: _fieldDecoration('Name'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: _fieldDecoration(
                                      'Phone for this order',
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                  if (!signedIn) ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: WaUi.primaryButtonHeight,
                                      child: OutlinedButton(
                                        onPressed: _openLogin,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          side: const BorderSide(
                                            color: Colors.black,
                                            width: 1.2,
                                          ),
                                          shape: const StadiumBorder(),
                                        ),
                                        child: const Text(
                                          'Login BarQody',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppAppear(
                            index: 6,
                            child: _section(
                              title: 'Bill',
                              child: Column(
                                children: [
                                  _summaryRow(
                                    'Subtotal',
                                    moneyCur == null
                                        ? cart.total.toStringAsFixed(0)
                                        : formatMoney(
                                            cart.total,
                                            currency: moneyCur,
                                          ),
                                  ),
                                  if (isDelivery) ...[
                                    const SizedBox(height: 8),
                                    _summaryRow(
                                      'Delivery',
                                      deliveryTotal <= 0
                                          ? 'Free'
                                          : (moneyCur == null
                                              ? deliveryTotal.toStringAsFixed(0)
                                              : formatMoney(
                                                  deliveryTotal,
                                                  currency: moneyCur,
                                                )),
                                    ),
                                  ],
                                  if (tipTotal > 0) ...[
                                    const SizedBox(height: 8),
                                    _summaryRow(
                                      'Tip',
                                      moneyCur == null
                                          ? tipTotal.toStringAsFixed(0)
                                          : formatMoney(
                                              tipTotal,
                                              currency: moneyCur,
                                            ),
                                    ),
                                  ],
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(
                                      height: 1,
                                      color: BarqodyChrome.divider,
                                    ),
                                  ),
                                  _summaryRow(
                                    'Total',
                                    totalMoney ??
                                        '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                                    strong: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (vendors.isNotEmpty)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: BarqodyChrome.divider),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _CheckoutPlaceCta(
                    label: placeLabel,
                    loading: _placing,
                    onPressed: _placing ? null : _submit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BarqodyChrome.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: WaUi.body.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                color: strong ? Colors.black : BarqodyChrome.secondaryText,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: WaUi.body.copyWith(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _CheckoutNavCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BarqodyChrome.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BarqodyChrome.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WaUi.label.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: BarqodyChrome.secondaryText,
                )
              else if (onTap != null)
                const Icon(
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

class _CheckoutChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CheckoutChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.98,
      duration: AppMotion.tab,
      curve: AppMotion.easeOut,
      child: Material(
        color: selected ? Colors.black : BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: AppMotion.tab,
            curve: AppMotion.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: WaUi.body.copyWith(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaySegment extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const _PaySegment({
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BarqodyChrome.fieldFill,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: _PaySegTab(
                label: 'Cash',
                selected: !isOnline,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _PaySegTab(
                label: 'Online',
                selected: isOnline,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaySegTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaySegTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Center(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutPlaceCta extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _CheckoutPlaceCta({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = (m.buttonH + 8).clamp(58.0, 66.0);
    final canTap = onPressed != null && !loading;

    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: AuthUi.primaryButtonShadow(m),
      ),
      child: Material(
        color: Colors.black,
        elevation: 0,
        borderRadius: BorderRadius.circular(h / 2),
        child: InkWell(
          onTap: canTap ? onPressed : null,
          borderRadius: BorderRadius.circular(h / 2),
          child: AnimatedOpacity(
            duration: AppMotion.content,
            opacity: canTap || loading ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(
                          fontSize: m.s(AuthUi.buttonLabelSize),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacedExploreOrder {
  final String businessName;
  final String businessUsername;
  final String currency;
  final int token;
  final String? orderId;
  final int totalItems;
  final double totalAmount;
  final String bookingKind;
  final String paymentMethod;
  final String paymentStatus;
  final bool paymentSimulated;

  const _PlacedExploreOrder({
    required this.businessName,
    required this.businessUsername,
    required this.currency,
    required this.token,
    required this.orderId,
    required this.totalItems,
    required this.totalAmount,
    this.bookingKind = 'order',
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.paymentSimulated = false,
  });
}

class _VendorPlaceBatch {
  final List<ExploreCartLine> lines;
  final String bookingKind;
  final String bookingDate;
  final String bookingTime;
  final String resourceId;
  final String checkInDate;
  final String checkOutDate;

  const _VendorPlaceBatch({
    required this.lines,
    required this.bookingKind,
    required this.bookingDate,
    required this.bookingTime,
    required this.resourceId,
    required this.checkInDate,
    required this.checkOutDate,
  });
}

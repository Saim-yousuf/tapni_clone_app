import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/catalog/checkout_payment_method_sheet.dart';
import 'package:tapni_app/screens/catalog/order_placed_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/utils/catalog_checkout.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/catalog_item_detail_sheet.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class ExploreCartScreen extends StatefulWidget {
  const ExploreCartScreen({super.key});

  @override
  State<ExploreCartScreen> createState() => _ExploreCartScreenState();
}

class _ExploreCartScreenState extends State<ExploreCartScreen> {
  bool _placing = false;

  bool get _isSignedIn {
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    return token.trim().isNotEmpty;
  }

  List<Map<String, dynamic>> _orderItems(List<ExploreCartLine> lines) {
    return lines
        .map(
          (line) => {
            if (line.item.id.isNotEmpty) 'catalogItemId': line.item.id,
            'name': line.item.name,
            'price': line.item.displayPrice,
            'quantity': line.quantity,
            if (line.notes.isNotEmpty) 'notes': line.notes,
            if (line.item.category.isNotEmpty) 'category': line.item.category,
            if (line.item.imageUrl.isNotEmpty) 'image': line.item.imageUrl,
          },
        )
        .toList();
  }

  /// Split a vendor basket into place-order batches (appointment slots / stays).
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

  Future<_GuestCheckoutDetails?> _promptGuestDetails() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<_GuestCheckoutDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetHeader(
                    title: 'Continue as guest',
                    padHorizontal: false,
                    onBack: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to place the order without creating an account.',
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: WaUi.primaryButtonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.pop(
                          ctx,
                          _GuestCheckoutDetails(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    notesCtrl.dispose();
    return result;
  }

  Future<void> _addMore(ExploreCartVendor vendor) async {
    final cart = context.read<ExploreCartProvider>();
    final available = vendor.catalogItems.where((i) => i.isActive).toList();
    if (available.isEmpty) return;

    final selected = await showModalBottomSheet<CatalogItem>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  title: 'Add more from ${vendor.businessName}',
                  onBack: () => Navigator.pop(ctx),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: available.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = available[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: WaUi.searchBg,
                                      child: const Icon(Icons.fastfood_outlined),
                                    ),
                                  )
                                : Container(
                                    color: WaUi.searchBg,
                                    child: const Icon(Icons.fastfood_outlined),
                                  ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: WaUi.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item.price > 0
                              ? formatMoney(
                                  item.price,
                                  currency: vendor.currency,
                                )
                              : 'Free',
                        ),
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final detail = await showCatalogItemDetailSheet(
      context: context,
      item: selected,
      currency: vendor.currency,
    );
    if (detail == null || !mounted || detail.quantity <= 0) return;

    cart.addItem(
      businessId: vendor.businessId,
      businessLinkId: vendor.businessLinkId,
      businessName: vendor.businessName,
      catalogType: vendor.catalogType,
      currency: vendor.currency,
      catalogItems: vendor.catalogItems,
      line: ExploreCartLine(
        item: selected,
        quantity: detail.quantity,
        notes: detail.notes,
      ),
    );
  }

  /// Places CatalogOrder(s) per vendor via shared [CatalogCheckout].
  /// Signed-in → POST /api/catalog/orders.
  /// Guest → POST /api/catalog/public/orders (requires websiteSlug).
  Future<void> _placeOrders() async {
    final cart = context.read<ExploreCartProvider>();
    if (cart.isEmpty) return;

    final signedIn = _isSignedIn;
    final profile = context.read<ProfileProvider>().profile;
    var customerUsername = profile.username ?? '';
    var customerName = profile.name;
    String? guestPhone;
    var guestAddress = '';
    var guestNotes = '';

    if (!signedIn) {
      final guest = await _promptGuestDetails();
      if (guest == null || !mounted) return;
      customerName = guest.name;
      customerUsername = '';
      guestPhone = guest.phone;
      guestAddress = guest.address;
      guestNotes = guest.notes;
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

    final grandTotal = vendors.fold<double>(
      0,
      (sum, v) =>
          sum +
          v.lines.fold<double>(
            0,
            (s, line) => s + (line.item.displayPrice * line.quantity),
          ),
    );
    final currency = vendors.first.currency;

    final method = await showCheckoutPaymentMethodSheet(
      context,
      totalAmount: grandTotal,
      currency: currency,
    );
    if (method == null || !mounted) return;

    setState(() => _placing = true);
    final repo = CatalogRepo();
    final placed = <_PlacedExploreOrder>[];
    String? lastError;

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
          (sum, line) => sum + (line.item.displayPrice * line.quantity),
        );

        final order = await CatalogCheckout.placeWithPayment(
          context: context,
          presetMethod: method,
          pushSuccessScreen: false,
          totalAmount: batchTotal,
          currency: vendor.currency,
          customerName: customerName,
          customerUsername: customerUsername,
          guestPhone: guestPhone,
          businessName: vendor.businessName,
          totalItems: itemCount,
          bookingKind: batch.bookingKind,
          publicGuestPayment: !signedIn,
          placeOrder: ({
            required String paymentMethod,
            required String idempotencyKey,
          }) {
            if (signedIn) {
              return repo.placeOrder(
                businessId: vendor.businessId,
                businessLinkId: vendor.businessLinkId,
                catalogType: vendor.catalogType,
                items: orderItems,
                bookingDate: batch.bookingDate.isEmpty
                    ? null
                    : batch.bookingDate,
                bookingTime: batch.bookingTime.isEmpty
                    ? null
                    : batch.bookingTime,
                resourceId:
                    batch.resourceId.isEmpty ? null : batch.resourceId,
                bookingKind: batch.bookingKind,
                checkInDate: batch.checkInDate.isEmpty
                    ? null
                    : batch.checkInDate,
                checkOutDate: batch.checkOutDate.isEmpty
                    ? null
                    : batch.checkOutDate,
                paymentMethod: paymentMethod,
                idempotencyKey: idempotencyKey,
              );
            }
            return repo.placePublicOrder(
              websiteSlug: vendor.websiteSlug,
              items: orderItems,
              guestName: customerName,
              guestPhone: guestPhone ?? '',
              guestAddress: guestAddress.isEmpty ? null : guestAddress,
              notes: guestNotes.isEmpty ? null : guestNotes,
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
              authorization: false,
            );
          },
        );

        if (order == null) {
          lastError = 'Could not place order for ${vendor.businessName}';
          vendorOk = false;
          break;
        }

        placed.add(
          _PlacedExploreOrder(
            businessName: vendor.businessName,
            businessUsername: '',
            currency: vendor.currency.isNotEmpty
                ? vendor.currency
                : order.currency,
            token: order.tokenNumber,
            orderId: order.id,
            totalItems: itemCount,
            totalAmount:
                order.totalAmount > 0 ? order.totalAmount : batchTotal,
            bookingKind: batch.bookingKind,
          ),
        );
      }
      if (!vendorOk) break;
      cart.removeVendor(vendor.businessLinkId);
    }

    if (!mounted) return;
    setState(() => _placing = false);

    if (lastError != null) {
      showAppToastMessenger(
            messenger,
            lastError,
            kind: AppToastKind.error,
          );
    }
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
            businessUsername: one.businessUsername.isNotEmpty
                ? one.businessUsername
                : one.businessName,
            totalItems: one.totalItems,
            totalAmount: one.totalAmount,
            currency: one.currency,
            orderId: one.orderId,
            bookingKind: one.bookingKind,
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<ExploreCartProvider>();
    final vendors = cart.vendors;
    final currencies = cart.vendors.map((v) => v.currency).toSet();
    final totalMoney = currencies.length == 1
        ? formatMoney(cart.total, currency: currencies.first)
        : null;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: 'Cart',
              trailing: CircleAssetButton(
                asset: 'assets/images/png/bag-icon.png',
                iconSize: 18,
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/png/bag-icon.png',
                              width: 64,
                              height: 64,
                              color: BarqodyChrome.secondaryText
                                  .withValues(alpha: 0.4),
                              errorBuilder: (_, _, _) => Icon(
                                Icons.shopping_bag_outlined,
                                size: 56,
                                color: BarqodyChrome.secondaryText
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Your cart is empty',
                              textAlign: TextAlign.center,
                              style: WaUi.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add items from Explore or a business website in the app to place an order.',
                              textAlign: TextAlign.center,
                              style: WaUi.body.copyWith(
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        BarqodyChrome.sidePad,
                        12,
                        BarqodyChrome.sidePad,
                        24,
                      ),
                      children: [
                        ...vendors.expand((vendor) {
                          final lineWidgets = <Widget>[];
                          for (var i = 0; i < vendor.lines.length; i++) {
                            final line = vendor.lines[i];
                            if (i > 0) {
                              lineWidgets.add(
                                const Divider(
                                  height: 24,
                                  color: BarqodyChrome.divider,
                                ),
                              );
                            }
                            lineWidgets.add(
                              _CartTile(
                                line: line,
                                currency: vendor.currency,
                                onRemove: () => cart.removeLine(
                                  businessLinkId: vendor.businessLinkId,
                                  lineIndex: i,
                                ),
                                onQtyChanged: (qty) => cart.updateQuantity(
                                  businessLinkId: vendor.businessLinkId,
                                  lineIndex: i,
                                  quantity: qty,
                                ),
                              ),
                            );
                          }

                          return [
                            if (cart.vendorCount > 1) ...[
                              const SizedBox(height: 8),
                              Text(
                                vendor.businessName,
                                style: WaUi.title.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatMoney(
                                  vendor.total,
                                  currency: vendor.currency,
                                ),
                                style: WaUi.label.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            ...lineWidgets,
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _addMore(vendor),
                                icon: Image.asset(
                                  'assets/images/png/plus-icon.png',
                                  width: 14,
                                  height: 14,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                  ),
                                ),
                                label: Text(
                                  'Add more from ${vendor.businessName}',
                                  style: WaUi.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (cart.vendorCount > 1)
                              const Padding(
                                padding: EdgeInsets.only(top: 16, bottom: 8),
                                child: Divider(
                                  height: 1,
                                  color: BarqodyChrome.divider,
                                ),
                              ),
                          ];
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.placeOrder,
                            style: WaUi.body.copyWith(
                              fontSize: 15,
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                          if (totalMoney != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              totalMoney,
                              style: WaUi.toolsTitleOf(
                                size: 18,
                                weight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: WaUi.primaryButtonHeight,
                      child: ElevatedButton(
                        onPressed: _placing ? null : _placeOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.black.withValues(alpha: 0.35),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: const StadiumBorder(),
                        ),
                        child: _placing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.l10n.placeOrder,
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
            ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final ExploreCartLine line;
  final String currency;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _CartTile({
    required this.line,
    required this.currency,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = line.item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _thumbPlaceholder(),
                  )
                : _thumbPlaceholder(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(line.lineTotal, currency: currency),
                style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              if (line.hasAppointment) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (line.resourceName.isNotEmpty) line.resourceName,
                    line.bookingDate,
                    line.bookingTime,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.label.copyWith(color: BarqodyChrome.secondaryText),
                ),
              ],
              if (line.hasStay) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (line.resourceName.isNotEmpty) line.resourceName,
                    '${line.checkInDate} → ${line.checkOutDate}',
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.label.copyWith(color: BarqodyChrome.secondaryText),
                ),
              ],
              if (line.notes.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  line.notes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.label.copyWith(color: BarqodyChrome.secondaryText),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyCircle(
              filled: true,
              onTap: () => onQtyChanged(line.quantity + 1),
              child: Image.asset(
                'assets/images/png/plus-icon.png',
                width: 12,
                height: 12,
                color: Colors.white,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.add,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${line.quantity}',
                style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (line.quantity <= 1)
              _QtyCircle(
                filled: false,
                borderColor: Colors.redAccent,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                onTap: onRemove,
                child: Image.asset(
                  'assets/images/png/order-delete.png',
                  width: 14,
                  height: 14,
                  color: Colors.redAccent.shade700,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Colors.redAccent.shade700,
                  ),
                ),
              )
            else
              _QtyCircle(
                filled: false,
                onTap: () => onQtyChanged(line.quantity - 1),
                child: Image.asset(
                  'assets/images/png/minus-icon.png',
                  width: 12,
                  height: 12,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.remove,
                    size: 14,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: BarqodyChrome.fieldFill,
      child: const Icon(Icons.fastfood_outlined, color: BarqodyChrome.bodyText),
    );
  }
}

class _QtyCircle extends StatelessWidget {
  final bool filled;
  final VoidCallback onTap;
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  const _QtyCircle({
    required this.filled,
    required this.onTap,
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? Colors.black
          : (backgroundColor ?? Colors.transparent),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: filled
                ? null
                : Border.all(
                    color: borderColor ?? Colors.black,
                    width: 1.2,
                  ),
          ),
          alignment: Alignment.center,
          child: child,
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

  const _PlacedExploreOrder({
    required this.businessName,
    required this.businessUsername,
    required this.currency,
    required this.token,
    required this.orderId,
    required this.totalItems,
    required this.totalAmount,
    this.bookingKind = 'order',
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

class _GuestCheckoutDetails {
  final String name;
  final String phone;
  final String address;
  final String notes;

  const _GuestCheckoutDetails({
    required this.name,
    required this.phone,
    this.address = '',
    this.notes = '',
  });
}

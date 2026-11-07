import 'dart:math' as math;

import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/explore_checkout_screen.dart';
import 'package:tapni_app/screens/explore_delivery_address_sheet.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/storefront_status_apply.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/app_rolling_text.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/catalog_item_detail_sheet.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class ExploreCartScreen extends StatefulWidget {
  const ExploreCartScreen({super.key});

  @override
  State<ExploreCartScreen> createState() => _ExploreCartScreenState();
}

class _ExploreCartScreenState extends State<ExploreCartScreen> {
  PageController? _fulfillPage;
  int _fulfillIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cart = context.read<ExploreCartProvider>();
      _fulfillIndex = cart.isDelivery ? 0 : 1;
      _fulfillPage = PageController(initialPage: _fulfillIndex);
      setState(() {});
      _refreshStorefrontStatus();
    });
  }

  @override
  void dispose() {
    _fulfillPage?.dispose();
    super.dispose();
  }

  void _onFulfillPageChanged(int index) {
    _fulfillIndex = index;
    context.read<ExploreCartProvider>().setFulfillMode(
          index == 0 ? 'delivery' : 'takeaway',
        );
    setState(() {});
  }

  void _goFulfillTab(int index) {
    if (_fulfillIndex == index) return;
    setState(() => _fulfillIndex = index);
    context.read<ExploreCartProvider>().setFulfillMode(
          index == 0 ? 'delivery' : 'takeaway',
        );
    final page = _fulfillPage;
    if (page != null && page.hasClients) {
      page.animateToPage(
        index,
        duration: AppMotion.content,
        curve: Curves.easeOutCubic,
      );
    }
  }

  double _rawDeliveryFee(List<ExploreCartVendor> vendors) {
    return vendors.fold<double>(
      0,
      (sum, v) => sum + v.deliveryFeeForSubtotal(v.total),
    );
  }

  /// Pull live closed/paused + ordering rules so CTA / tabs stay in sync.
  Future<void> _refreshStorefrontStatus() async {
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
        applyStorefrontStatusMap(cart, map, websiteSlug: slug);
      } catch (_) {
        /* keep last-known cart flags */
      }
    }
    if (!mounted) return;
    final nextIndex = cart.isDelivery ? 0 : 1;
    if (_fulfillIndex != nextIndex) {
      setState(() => _fulfillIndex = nextIndex);
      final page = _fulfillPage;
      if (page != null && page.hasClients) {
        page.jumpToPage(nextIndex);
      }
    }
  }


  Future<void> _editCartLine({
    required ExploreCartVendor vendor,
    required int lineIndex,
  }) async {
    if (lineIndex < 0 || lineIndex >= vendor.lines.length) return;
    final line = vendor.lines[lineIndex];
    final detail = await showCatalogItemDetailSheet(
      context: context,
      item: line.item,
      currency: vendor.currency,
      initialQty: line.quantity,
      initialNotes: line.notes,
      title: 'Edit item',
    );
    if (detail == null || !mounted) return;
    context.read<ExploreCartProvider>().updateLine(
          businessLinkId: vendor.businessLinkId,
          lineIndex: lineIndex,
          quantity: detail.quantity,
          notes: detail.notes,
        );
  }

  Future<List<CatalogItem>> _resolveAddMoreCatalog(
    ExploreCartVendor vendor,
  ) async {
    final snapshot = vendor.catalogItems.where((i) => i.isActive).toList();
    if (snapshot.length > 1) return snapshot;

    try {
      final repo = AuthRepo();
      final res = vendor.businessId.trim().isNotEmpty
          ? await repo.profileById(id: vendor.businessId.trim())
          : (vendor.websiteSlug.trim().isNotEmpty
              ? await repo.profileByUsername(
                  username: vendor.websiteSlug.trim(),
                )
              : null);
      if (res == null || !res.success || res.data == null) return snapshot;

      final raw = res.data;
      Map<String, dynamic>? userJson;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final nested = map['user'] ?? map['data'] ?? map;
        if (nested is Map) {
          userJson = Map<String, dynamic>.from(nested);
          if (userJson['user'] is Map) {
            userJson = Map<String, dynamic>.from(userJson['user'] as Map);
          }
        }
      }
      if (userJson == null) return snapshot;

      final profile = UserProfile.fromApiJson(userJson);
      final linkId = vendor.businessLinkId.trim();
      final type = vendor.catalogType.trim();
      final links = profile.socialLinks.where((l) => l.isCatalogLink).toList();
      final byId = linkId.isEmpty
          ? <SocialLink>[]
          : links.where((l) => l.id == linkId).toList();
      final SocialLink? match = byId.isNotEmpty
          ? byId.first
          : () {
              final byType = links
                  .where((l) => catalogTypesMatch(l.catalogType, type))
                  .toList();
              if (byType.isNotEmpty) return byType.first;
              return links.isNotEmpty ? links.first : null;
            }();

      final items = (match?.catalogItems ?? const <CatalogItem>[])
          .where((i) => i.isActive)
          .toList();
      if (items.isEmpty) return snapshot;

      if (mounted) {
        context.read<ExploreCartProvider>().setVendorCatalogItems(
              businessLinkId: vendor.businessLinkId,
              catalogItems: items,
            );
      }
      return items;
    } catch (_) {
      return snapshot;
    }
  }

  Future<void> _addMore(ExploreCartVendor vendor) async {
    final cart = context.read<ExploreCartProvider>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
    final available = await _resolveAddMoreCatalog(vendor);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (available.isEmpty) {
      showAppToast(
        context,
        'No more items available',
        kind: AppToastKind.warning,
      );
      return;
    }

    final inCartQty = <String, int>{};
    for (final line in vendor.lines) {
      final id = line.item.id.trim();
      final key = id.isNotEmpty
          ? 'id:$id'
          : 'name:${line.item.name.trim().toLowerCase()}';
      inCartQty[key] = (inCartQty[key] ?? 0) + line.quantity;
    }

    final selected = await showModalBottomSheet<CatalogItem>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return _AddMoreItemsSheet(
          items: available,
                                  currency: vendor.currency,
          inCartQtyByKey: inCartQty,
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
      businessUsername: vendor.businessUsername,
      catalogType: vendor.catalogType,
      currency: vendor.currency,
      websiteSlug: vendor.websiteSlug,
      ordersPaused: vendor.ordersPaused,
      isClosedNow: vendor.isClosedNow,
      catalogItems: vendor.catalogItems,
      line: ExploreCartLine(
        item: selected,
        quantity: detail.quantity,
        notes: detail.notes,
      ),
    );
  }

  bool _needsFulfillment(List<ExploreCartVendor> vendors) {
    // Any regular order line gets Delivery | Pickup tabs.
    return vendors.any(
      (v) => v.lines.any((line) => !line.hasAppointment && !line.hasStay),
    );
  }

  Future<void> _openCheckout() async {
    final cart = context.read<ExploreCartProvider>();
    if (cart.isEmpty) return;
    final vendors = cart.vendors.where((v) => v.lines.isNotEmpty).toList();
    if (vendors.isEmpty) return;
    if (cart.isDelivery && !cart.acceptsDelivery) {
      showAppToast(
        context,
        'Delivery is not available. Switch to pickup.',
              kind: AppToastKind.warning,
            );
      cart.setFulfillMode('takeaway');
        return;
      }
    if (!cart.isDelivery && !cart.acceptsPickup) {
      showAppToast(
        context,
        'Pickup is not available. Switch to delivery.',
        kind: AppToastKind.warning,
      );
      cart.setFulfillMode('delivery');
      return;
    }
    if (cart.belowMinOrder) {
      final cur = vendors.length == 1 ? vendors.first.currency : 'PKR';
      showAppToast(
        context,
        'Minimum order is ${formatMoney(cart.minOrderAmount, currency: cur)}',
        kind: AppToastKind.warning,
      );
      return;
    }
    final blocked = vendors.where((v) => v.orderBlockedLabel != null).toList();
    if (blocked.isNotEmpty) {
      showAppToast(
      context,
        blocked.first.ordersPaused
            ? 'This restaurant is not accepting orders right now.'
            : 'This restaurant is closed right now.',
        kind: AppToastKind.warning,
      );
      return;
    }
    if (cart.isDelivery &&
        cart.deliveryAreas.isNotEmpty &&
        cart.deliveryArea.trim().isEmpty) {
      showAppToast(
        context,
        'Choose a delivery area to continue',
        kind: AppToastKind.warning,
      );
      return;
    }
    if (cart.isDelivery &&
        _needsFulfillment(vendors) &&
        cart.deliveryDisplayAddress.isEmpty) {
      final saved = await showExploreDeliveryAddressSheet(context);
      if (!saved || !mounted) return;
      if (cart.deliveryDisplayAddress.isEmpty) {
        showAppToast(
          context,
          'Add a delivery address to continue',
          kind: AppToastKind.warning,
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => const ExploreCheckoutScreen()),
    );
  }

  Future<void> _editDeliveryAddress() async {
    await showExploreDeliveryAddressSheet(context);
  }

  Widget _buildCartPage({
    required ExploreCartProvider cart,
    required List<ExploreCartVendor> vendors,
    required Set<String> currencies,
    required bool isDeliveryPage,
    required ExploreCartVendor? primaryVendor,
    bool showLocation = true,
  }) {
    final deliveryFee = isDeliveryPage ? _rawDeliveryFee(vendors) : null;
    final pageTotal = cart.total + (deliveryFee ?? 0);
    final currency = currencies.length == 1 ? currencies.first : null;
    final areas = cart.deliveryAreas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BarqodyChrome.sidePad,
        14,
        BarqodyChrome.sidePad,
        24,
      ),
      children: [
        if (showLocation) ...[
          AppAppear(
            index: 0,
            child: _LocationCard(
              isDelivery: isDeliveryPage,
              pickupLabel: primaryVendor == null
                  ? 'Store'
                  : (primaryVendor.businessName.isNotEmpty
                      ? primaryVendor.businessName
                      : (primaryVendor.businessUsername.isNotEmpty
                          ? '@${primaryVendor.businessUsername}'
                          : 'Store')),
              pickupHint: primaryVendor?.websiteSlug.trim().isNotEmpty == true
                  ? 'Pickup at the counter'
                  : 'Show this order at the venue',
              deliveryAddress: cart.deliveryDisplayAddress,
              onDeliveryTap: _editDeliveryAddress,
            ),
          ),
          if (isDeliveryPage && areas.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppAppear(
              index: 1,
              child: _DeliveryAreaChips(
                areas: areas,
                selected: cart.deliveryArea,
                onSelected: cart.setDeliveryArea,
              ),
            ),
          ],
          if (cart.canScheduleWhileClosed) ...[
            const SizedBox(height: 12),
            AppAppear(
              index: 2,
              child: _OrderingBanner(
                icon: Icons.schedule_rounded,
                text:
                    'Closed now — you can still schedule for later at checkout.',
              ),
            ),
          ],
          if (cart.belowMinOrder) ...[
            const SizedBox(height: 12),
            AppAppear(
              index: 3,
              child: _OrderingBanner(
                icon: Icons.shopping_bag_outlined,
                text: currency == null
                    ? 'Minimum order not reached yet'
                    : 'Add ${formatMoney(cart.minOrderShortfall, currency: currency)} more to reach the minimum',
              ),
            ),
          ],
          if (cart.prepTimeLabel.isNotEmpty &&
              cart.scheduledFor.isEmpty) ...[
            const SizedBox(height: 12),
            AppAppear(
              index: 3,
              child: _OrderingBanner(
                icon: Icons.timer_outlined,
                text: isDeliveryPage
                    ? '${cart.prepTimeLabel} after confirmation'
                    : '${cart.prepTimeLabel} for pickup after confirmation',
              ),
            ),
          ],
          if (isDeliveryPage &&
              primaryVendor != null &&
              primaryVendor.freeDeliveryAbove > 0 &&
              primaryVendor.deliveryFee > 0) ...[
            const SizedBox(height: 12),
            AppAppear(
              index: 4,
              child: _FreeDeliveryProgress(
                subtotal: cart.total,
                freeAbove: primaryVendor.freeDeliveryAbove,
                currency: primaryVendor.currency,
              ),
            ),
          ],
          const SizedBox(height: 22),
        ],
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
                key: ValueKey(
                  '${isDeliveryPage ? 'd' : 'p'}-${vendor.businessLinkId}-$i-${line.item.id}-${line.item.name}',
                ),
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
                onEditDetails: () => _editCartLine(
                  vendor: vendor,
                  lineIndex: i,
          ),
        ),
      );
          }

          return [
            ...lineWidgets,
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: BarqodyChrome.fieldFill,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _addMore(vendor),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/png/plus-icon.png',
                          width: 12,
                          height: 12,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.add_rounded,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add more items',
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (vendor != vendors.last)
              const Padding(
                padding: EdgeInsets.only(top: 22, bottom: 10),
                child: Divider(
                  height: 1,
                  color: BarqodyChrome.divider,
                ),
              )
            else
              const SizedBox(height: 28),
          ];
        }),
        _BillBlock(
          subtotal: cart.total,
          deliveryFee: deliveryFee,
          total: pageTotal,
          itemCount: cart.itemCount,
          currency: currencies.length == 1 ? currencies.first : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<ExploreCartProvider>();
    final vendors = cart.vendors.where((v) => v.lines.isNotEmpty).toList();
    final currencies = vendors.map((v) => v.currency).toSet();
    final showFulfill = !cart.isEmpty && _needsFulfillment(vendors);
    final primaryVendor = vendors.isNotEmpty ? vendors.first : null;
    final bothModes = cart.acceptsDelivery && cart.acceptsPickup;
    final fulfillReady = showFulfill && bothModes && _fulfillPage != null;
    final singleModeTitle = !showFulfill
        ? 'Cart'
        : (cart.isDelivery ? 'Delivery' : 'Pickup');

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    CircleBackButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: fulfillReady
                          ? Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 268),
                                child: _FulfillSegment(
                                  index: _fulfillIndex,
                                  pageController: _fulfillPage,
                                  onChanged: _goFulfillTab,
                                ),
                              ),
                            )
                          : Text(
                              singleModeTitle,
                              textAlign: TextAlign.center,
                              style: WaUi.toolsTitleOf(
                                size: 20,
                                weight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: BarqodyChrome.divider),
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
                  : fulfillReady
                      ? PageView(
                          controller: _fulfillPage,
                          onPageChanged: _onFulfillPageChanged,
                          physics: const BouncingScrollPhysics(
                            parent: PageScrollPhysics(),
                      ),
                      children: [
                            _buildCartPage(
                              cart: cart,
                              vendors: vendors,
                              currencies: currencies,
                              isDeliveryPage: true,
                              primaryVendor: primaryVendor,
                            ),
                            _buildCartPage(
                              cart: cart,
                              vendors: vendors,
                              currencies: currencies,
                              isDeliveryPage: false,
                              primaryVendor: primaryVendor,
                            ),
                          ],
                        )
                      : _buildCartPage(
                          cart: cart,
                          vendors: vendors,
                          currencies: currencies,
                          isDeliveryPage: cart.isDelivery,
                          primaryVendor: primaryVendor,
                          showLocation: showFulfill,
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
                child: Builder(
                  builder: (context) {
                    final blocked = vendors
                        .map((v) => v.orderBlockedLabel)
                        .whereType<String>()
                        .toList();
                    final blockedLabel = blocked.isEmpty
                        ? null
                        : (blocked.contains('Orders paused')
                            ? 'Orders paused'
                            : 'Restaurant closed');
                    final minBlocked = cart.belowMinOrder;
                    final label = blockedLabel ??
                        (minBlocked ? 'Add more items' : 'Continue');
                    return _PlaceOrderCta(
                      label: label,
                      amountLabel: '',
                      compareValue: null,
                      loading: false,
                      blocked: blockedLabel != null || minBlocked,
                      onPressed: (blockedLabel != null || minBlocked)
                          ? null
                          : _openCheckout,
                    );
                  },
                ),
                                ),
                              ),
                            );
  }
}

class _FulfillSegment extends StatelessWidget {
  final int index;
  final PageController? pageController;
  final ValueChanged<int> onChanged;

  const _FulfillSegment({
    required this.index,
    required this.pageController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final thumbW = (w - 6) / 2;

          Widget thumb(double page) {
            return Positioned(
              left: 3 + (page.clamp(0.0, 1.0) * thumbW),
              top: 3,
              bottom: 3,
              width: thumbW,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            );
          }

          double pageValue() {
            if (pageController != null && pageController!.hasClients) {
              return pageController!.page ?? index.toDouble();
            }
            return index.toDouble();
          }

          return DecoratedBox(
            decoration: BoxDecoration(
              color: BarqodyChrome.fieldFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedBuilder(
              animation: pageController ?? const AlwaysStoppedAnimation(0),
              builder: (context, _) {
                final page = pageValue();
                return Stack(
                  children: [
                    thumb(page),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onChanged(0),
                            child: Center(
                              child: Text(
                                'Delivery',
                                style: WaUi.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: page < 0.5
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onChanged(1),
                            child: Center(
                              child: Text(
                                'Pickup',
                                  style: WaUi.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: page >= 0.5
                                      ? Colors.white
                                      : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final bool isDelivery;
  final String pickupLabel;
  final String pickupHint;
  final String deliveryAddress;
  final VoidCallback onDeliveryTap;

  const _LocationCard({
    required this.isDelivery,
    required this.pickupLabel,
    required this.pickupHint,
    required this.deliveryAddress,
    required this.onDeliveryTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = deliveryAddress.trim().isNotEmpty;
    final title = isDelivery
        ? (hasAddress ? deliveryAddress : 'Add delivery address')
        : pickupLabel;
    final subtitle = isDelivery
        ? (hasAddress ? 'Change address' : 'Tap to set where we deliver')
        : pickupHint;
    final canTap = isDelivery;

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: canTap ? onDeliveryTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDelivery
                      ? Icons.location_on_rounded
                      : Icons.storefront_rounded,
                  size: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                      isDelivery
                          ? 'Deliver this order to'
                          : 'Pickup this order at',
                      style: WaUi.label.copyWith(
                              color: BarqodyChrome.secondaryText,
                        fontWeight: FontWeight.w600,
                            ),
                          ),
                    const SizedBox(height: 4),
                            Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w800,
                                color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.label.copyWith(
                        color: canTap && !hasAddress && isDelivery
                            ? Colors.black
                            : BarqodyChrome.secondaryText,
                        fontWeight: canTap && !hasAddress && isDelivery
                            ? FontWeight.w600
                            : FontWeight.w500,
                              ),
                            ),
                          ],
                ),
              ),
              if (!isDelivery) ...[
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BarqodyChrome.divider),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.near_me_outlined,
                    size: 22,
                    color: Colors.black87,
                  ),
                ),
              ] else
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

class _BillBlock extends StatelessWidget {
  final double subtotal;
  final double? deliveryFee;
  final double total;
  final int itemCount;
  final String? currency;

  const _BillBlock({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.itemCount,
    required this.currency,
  });

  String _money(double v) {
    if (currency == null) return v.toStringAsFixed(0);
    return formatMoney(v, currency: currency!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Subtotal', _money(subtotal)),
        if (deliveryFee != null) ...[
          const SizedBox(height: 12),
          _row(
            'Delivery',
            deliveryFee! <= 0 ? 'Free' : _money(deliveryFee!),
          ),
        ],
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            return CustomPaint(
              size: Size(c.maxWidth, 1),
              painter: _DashPainter(color: BarqodyChrome.divider),
            );
          },
        ),
        const SizedBox(height: 14),
        _row(
          'Total ($itemCount item${itemCount == 1 ? '' : 's'})',
          _money(total),
          strong: true,
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: WaUi.body.copyWith(
              color: strong ? Colors.black : BarqodyChrome.bodyText,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              fontSize: strong ? 16 : 15,
            ),
          ),
        ),
        Text(
          value,
          style: WaUi.body.copyWith(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            fontSize: strong ? 16 : 15,
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PlaceOrderCta extends StatelessWidget {
  final String label;
  final String amountLabel;
  final double? compareValue;
  final bool loading;
  final bool blocked;
  final VoidCallback? onPressed;

  const _PlaceOrderCta({
    required this.label,
    required this.amountLabel,
    this.compareValue,
    required this.loading,
    this.blocked = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = (m.buttonH + 8).clamp(58.0, 66.0);
    final canTap = onPressed != null && !loading && !blocked;
    final bg = blocked ? const Color(0xFFD32F2F) : Colors.black;

    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: blocked ? null : AuthUi.primaryButtonShadow(m),
      ),
      child: Material(
        color: bg,
                          elevation: 0,
        borderRadius: BorderRadius.circular(h / 2),
        child: InkWell(
          onTap: canTap ? onPressed : null,
          borderRadius: BorderRadius.circular(h / 2),
          child: AnimatedOpacity(
            duration: AppMotion.content,
            opacity: canTap || loading || blocked ? 1 : 0.45,
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
                  : blocked
                      ? Center(
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
                        )
                      : amountLabel.trim().isEmpty
                          ? Center(
                              child: Text(
                                label,
                                style: WaUi.body.copyWith(
                                  fontSize: m.s(AuthUi.buttonLabelSize),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: WaUi.body.copyWith(
                                      fontSize: m.s(AuthUi.buttonLabelSize),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                AppRollingText(
                                  amountLabel,
                                  textAlign: TextAlign.right,
                                  compareValue: compareValue == null
                                      ? null
                                      : (compareValue! * 100).round(),
                                  style: WaUi.body.copyWith(
                                    fontSize: m.s(AuthUi.buttonLabelSize),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                  height: m.s(AuthUi.buttonLabelSize) + 4,
                                ),
                              ],
                            ),
            ),
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
  final VoidCallback onEditDetails;

  const _CartTile({
    super.key,
    required this.line,
    required this.currency,
    required this.onRemove,
    required this.onQtyChanged,
    required this.onEditDetails,
  });

  @override
  Widget build(BuildContext context) {
    final item = line.item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEditDetails,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
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
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
              ),
              const SizedBox(height: 4),
                          AppRollingMoney(
                formatMoney(line.lineTotal, currency: currency),
                            compareValue: line.lineTotal,
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
              ),
              if (line.hasAppointment) ...[
                const SizedBox(height: 2),
                Text(
                  [
                                if (line.resourceName.isNotEmpty)
                                  line.resourceName,
                    line.bookingDate,
                    line.bookingTime,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                              style: WaUi.label.copyWith(
                                color: BarqodyChrome.secondaryText,
                              ),
                ),
              ],
              if (line.hasStay) ...[
                const SizedBox(height: 2),
                Text(
                  [
                                if (line.resourceName.isNotEmpty)
                                  line.resourceName,
                    '${line.checkInDate} → ${line.checkOutDate}',
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                              style: WaUi.label.copyWith(
                                color: BarqodyChrome.secondaryText,
                              ),
                ),
              ],
                const SizedBox(height: 2),
                Text(
                            line.notes.isNotEmpty
                                ? line.notes
                                : 'Add note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                            style: WaUi.label.copyWith(
                              color: line.notes.isNotEmpty
                                  ? BarqodyChrome.secondaryText
                                  : Colors.black54,
                              fontWeight: line.notes.isNotEmpty
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              decoration: line.notes.isEmpty
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _QtyStepper(
          quantity: line.quantity,
          onIncrement: () => onQtyChanged(line.quantity + 1),
          onDecrement: () => onQtyChanged(line.quantity - 1),
          onRemove: onRemove,
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

class _QtyStepper extends StatefulWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _QtyStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<_QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<_QtyStepper> {
  @override
  Widget build(BuildContext context) {
    final qty = widget.quantity;
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyCircle(
              filled: true,
          onTap: widget.onIncrement,
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
        AppRollingText(
          '$qty',
          compareValue: qty,
          width: 36,
          height: 28,
          style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.86, end: 1).animate(anim),
                  child: child,
                ),
              );
            },
            child: qty <= 1
                ? _QtyCircle(
                    key: const ValueKey('delete'),
                filled: false,
                borderColor: Colors.redAccent,
                    backgroundColor:
                        Colors.redAccent.withValues(alpha: 0.12),
                    onTap: widget.onRemove,
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
                : _QtyCircle(
                    key: const ValueKey('minus'),
                filled: false,
                    onTap: widget.onDecrement,
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
          ),
        ),
      ],
    );
  }
}

class _QtyCircle extends StatefulWidget {
  final bool filled;
  final VoidCallback onTap;
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  const _QtyCircle({
    super.key,
    required this.filled,
    required this.onTap,
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  State<_QtyCircle> createState() => _QtyCircleState();
}

class _QtyCircleState extends State<_QtyCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1, end: 0.82).animate(
      CurvedAnimation(
        parent: _press,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _press.forward();
    if (mounted) {
      widget.onTap();
      await _press.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: widget.filled
          ? Colors.black
            : (widget.backgroundColor ?? Colors.transparent),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
          onTap: _handleTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
              border: widget.filled
                ? null
                : Border.all(
                      color: widget.borderColor ?? Colors.black,
                    width: 1.2,
                  ),
          ),
          alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _OrderingBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OrderingBanner({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: WaUi.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeDeliveryProgress extends StatelessWidget {
  final double subtotal;
  final double freeAbove;
  final String currency;

  const _FreeDeliveryProgress({
    required this.subtotal,
    required this.freeAbove,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = subtotal + 1e-9 >= freeAbove;
    final progress = freeAbove <= 0
        ? 1.0
        : (subtotal / freeAbove).clamp(0.0, 1.0);
    final remain = (freeAbove - subtotal).clamp(0, freeAbove);
    return Container(
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
            unlocked
                ? 'Free delivery unlocked'
                : 'Add ${formatMoney(remain, currency: currency)} more for free delivery',
            style: WaUi.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppMotion.content,
              curve: AppMotion.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  color: Colors.black,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAreaChips extends StatelessWidget {
  final List<String> areas;
  final String selected;
  final ValueChanged<String> onSelected;

  const _DeliveryAreaChips({
    required this.areas,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery area',
          style: WaUi.body.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final area in areas)
              AnimatedScale(
                scale: selected == area ? 1.0 : 0.98,
                duration: AppMotion.tab,
                curve: AppMotion.easeOut,
                child: Material(
                  color: selected == area
                      ? Colors.black
                      : BarqodyChrome.fieldFill,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () => onSelected(area),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        area,
                        style: WaUi.body.copyWith(
                          color:
                              selected == area ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AddMoreItemsSheet extends StatelessWidget {
  final List<CatalogItem> items;
  final String currency;
  final Map<String, int> inCartQtyByKey;

  const _AddMoreItemsSheet({
    required this.items,
    required this.currency,
    required this.inCartQtyByKey,
  });

  int _qtyFor(CatalogItem item) {
    final id = item.id.trim();
    if (id.isNotEmpty) return inCartQtyByKey['id:$id'] ?? 0;
    final name = item.name.trim().toLowerCase();
    if (name.isEmpty) return 0;
    return inCartQtyByKey['name:$name'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Add more items',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final inCartQty = _qtyFor(item);
                  final alreadyInCart = inCartQty > 0;
                  final priceLabel = item.price > 0
                      ? formatMoney(item.price, currency: currency)
                      : 'Free';
                  final ctaLabel = alreadyInCart
                      ? (inCartQty > 1
                          ? 'In cart ($inCartQty)'
                          : 'In cart')
                      : 'Add';
                  return Material(
                    color: BarqodyChrome.fieldFill,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, item),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _thumbPlaceholder(),
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
                                    style: WaUi.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    alreadyInCart
                                        ? '$priceLabel · Add more'
                                        : priceLabel,
                                    style: WaUi.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: alreadyInCart
                                          ? BarqodyChrome.bodyText
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: alreadyInCart
                                  ? Colors.white
                                  : Colors.black,
                              shape: StadiumBorder(
                                side: alreadyInCart
                                    ? const BorderSide(
                                        color: Colors.black,
                                        width: 1.2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pop(context, item),
                                customBorder: const StadiumBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    ctaLabel,
                                    style: WaUi.body.copyWith(
                                      color: alreadyInCart
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_outlined,
        color: BarqodyChrome.bodyText,
      ),
    );
  }
}

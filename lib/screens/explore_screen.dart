import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/screens/explore_cart_screen.dart';
import 'package:tapni_app/screens/explore_search_screen.dart';
import 'package:tapni_app/screens/explore_see_all_screen.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/business_categories.dart';
import 'package:tapni_app/utils/explore_actions.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';
import 'package:tapni_app/widgets/shop_product_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Theme-aware colors for explore screens (light + dark).
class _ExploreTheme {
  final Color scaffold;
  final Color surface;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color border;
  final Color searchFill;
  final Color chipUnselected;
  final Color chipBorder;
  final Color emptyIconBg;
  final Color locationIconBg;
  final Color locationIconBorder;
  final Color categoryTagBg;
  final Color categoryTagText;
  final Color imageFallbackStart;
  final Color imageFallbackEnd;
  final Color imageFallbackIcon;
  final Color shadow;
  final Color ratingBadgeBg;
  final Color accent;
  final Color onAccent;
  final Color sectionIconBg;
  final LinearGradient promoGradient;
  final Color promoTitleColor;
  final Color promoSubtitleColor;
  final Color promoButtonBg;
  final Color promoButtonText;

  const _ExploreTheme._({
    required this.scaffold,
    required this.surface,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.border,
    required this.searchFill,
    required this.chipUnselected,
    required this.chipBorder,
    required this.emptyIconBg,
    required this.locationIconBg,
    required this.locationIconBorder,
    required this.categoryTagBg,
    required this.categoryTagText,
    required this.imageFallbackStart,
    required this.imageFallbackEnd,
    required this.imageFallbackIcon,
    required this.shadow,
    required this.ratingBadgeBg,
    required this.accent,
    required this.onAccent,
    required this.sectionIconBg,
    required this.promoGradient,
    required this.promoTitleColor,
    required this.promoSubtitleColor,
    required this.promoButtonBg,
    required this.promoButtonText,
  });

  factory _ExploreTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _ExploreTheme._(
      scaffold: theme.scaffoldBackgroundColor,
      surface: isDark ? const Color(0xFF1A1A1A) : AppTheme.cardLightBg,
      primaryText: theme.colorScheme.onSurface,
      secondaryText:
          isDark ? const Color(0xFFB0B3B8) : WaUi.secondaryText,
      mutedText: isDark ? const Color(0xFF8A8D91) : const Color(0xFF94A3B8),
      border: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE2E8F0),
      searchFill: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF8FAFC),
      chipUnselected: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF0F2F5),
      chipBorder: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE9EDEF),
      emptyIconBg: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF5F6F8),
      locationIconBg: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF0F2F5),
      locationIconBorder:
          isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE9EDEF),
      categoryTagBg: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF1F5F9),
      categoryTagText:
          isDark ? const Color(0xFFB0B3B8) : const Color(0xFF475569),
      imageFallbackStart:
          isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF4F5F7),
      imageFallbackEnd:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE6E9ED),
      imageFallbackIcon:
          isDark ? const Color(0xFF8A8D91) : const Color(0xFF9AA3AB),
      shadow: isDark ? Colors.black54 : Colors.black,
      ratingBadgeBg: isDark ? const Color(0xFF2A2B2C) : Colors.white,
      accent: isDark ? AppTheme.secondaryWhite : AppTheme.primaryBlack,
      onAccent: isDark ? AppTheme.primaryBlack : AppTheme.secondaryWhite,
      sectionIconBg: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF0F2F5),
      promoGradient: isDark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2B2C), Color(0xFF1A1A1A)],
            )
          : AppTheme.goldGradient,
      promoTitleColor: AppTheme.secondaryWhite,
      promoSubtitleColor:
          isDark ? const Color(0xFFB0B3B8) : const Color(0xCCFFFFFF),
      promoButtonBg: AppTheme.secondaryWhite,
      promoButtonText: AppTheme.primaryBlack,
    );
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repo = ExploreRepo();
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ExploreBusiness> _businesses = [];
  List<ExploreOffer> _offers = [];
  List<ExploreItem> _items = [];
  List<ExploreBanner> _banners = [];
  List<ExploreCategoryItem> _categories = [];
  bool _loading = true;
  String? _error;
  double? _lat;
  double? _lng;
  String _locationHint = 'Set your location';
  double _radiusKm = 50;
  bool _businessPromoDismissed = false;
  final _bannerController = PageController();
  int _bannerPage = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final count = _banners.isEmpty ? 3 : _banners.length;
      if (count <= 1) return;
      final next = (_bannerPage + 1) % count;
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      setState(() => _bannerPage = next);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final permitted = await LocationHelper.ensurePermission();
    if (permitted) {
      final loc = await LocationHelper.getCurrentLocation();
      if (loc != null) {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _locationHint = 'Near you';
      }
    }

    if (_lat == null || _lng == null) {
      _locationHint = 'Enable location for nearby results';
    }

    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await Future.wait([
      _repo.getNearby(
        lat: _lat,
        lng: _lng,
        radiusKm: _radiusKm,
      ),
      _repo.getBanners(),
      _repo.getCategories(),
    ]);

    if (!mounted) return;

    final res = results[0];
    final bannersRes = results[1];
    final categoriesRes = results[2];

    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load explore feed';
        _businesses = [];
        _offers = [];
        _items = [];
      });
      return;
    }

    final parsed = _repo.parseNearby(res.data);
    final banners = bannersRes.success
        ? _repo.parseBanners(bannersRes.data)
        : <ExploreBanner>[];
    final categories = categoriesRes.success
        ? _repo.parseCategories(categoriesRes.data)
        : <ExploreCategoryItem>[];

    final isEmptyFeed = parsed.businesses.isEmpty &&
        parsed.offers.isEmpty &&
        parsed.items.isEmpty;

    // Silently widen range if nothing nearby — user doesn't manage radius.
    if (isEmptyFeed && _lat != null && _lng != null && _radiusKm < 100) {
      final nextRadius = (_radiusKm < 50 ? 50.0 : 100.0);
      if (nextRadius > _radiusKm) {
        _radiusKm = nextRadius;
        final wider = await _repo.getNearby(
          lat: _lat,
          lng: _lng,
          radiusKm: _radiusKm,
        );
        if (!mounted) return;
        if (wider.success) {
          final widerParsed = _repo.parseNearby(wider.data);
          setState(() {
            _loading = false;
            _businesses = widerParsed.businesses;
            _offers = widerParsed.offers;
            _items = widerParsed.items;
            _banners = banners;
            _categories = categories;
            if (_bannerPage >= (_banners.isEmpty ? 3 : _banners.length)) {
              _bannerPage = 0;
            }
            _updateLocationHintFromBusinesses(widerParsed.businesses);
          });
          return;
        }
      }
    }

    setState(() {
      _loading = false;
      _businesses = parsed.businesses;
      _offers = parsed.offers;
      _items = parsed.items;
      _banners = banners;
      _categories = categories;
      if (_bannerPage >= (_banners.isEmpty ? 3 : _banners.length)) {
        _bannerPage = 0;
      }
      _updateLocationHintFromBusinesses(parsed.businesses);
    });
  }

  void _updateLocationHintFromBusinesses(List<ExploreBusiness> businesses) {
    if (_lat == null || _lng == null) {
      _locationHint = 'Enable location for nearby results';
      return;
    }
    if (businesses.isEmpty) {
      _locationHint = 'Near you';
      return;
    }
    final first = businesses.first;
    if (first.locationLabel.isNotEmpty) {
      _locationHint = first.locationLabel;
    } else {
      _locationHint = 'Near you';
    }
  }

  void _handleBannerTap(ExploreBanner banner) {
    switch (banner.actionType) {
      case 'become_business':
        SubcriptionSheet.show(context);
        break;
      case 'offers':
        _openSeeAll(kind: ExploreSeeAllKind.offers, offers: _offers);
        break;
      case 'page_products':
        _openSeeAll(kind: ExploreSeeAllKind.items, items: _productItems);
        break;
      case 'page_services':
        _openSeeAll(kind: ExploreSeeAllKind.services, items: _serviceItems);
        break;
      case 'page_businesses':
        _openSeeAll(
          kind: ExploreSeeAllKind.businesses,
          businesses: _businesses,
        );
        break;
      case 'business':
        final username = banner.actionUrl.trim().replaceFirst(RegExp(r'^@'), '');
        if (username.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScannedProfileScreen(username: username),
          ),
        );
        break;
      case 'url':
        _openBannerUrl(banner.actionUrl);
        break;
      default:
        break;
    }
  }

  Future<void> _openBannerUrl(String raw) async {
    var url = raw.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<ExploreItem> get _productItems =>
      _items.where((i) => !i.isService).toList();

  List<ExploreItem> get _serviceItems =>
      _items.where((i) => i.isService).toList();

  void _openSearch({
    String? industry,
    ExploreSearchTab initialTab = ExploreSearchTab.items,
    bool autofocus = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreSearchScreen(
          offers: _offers,
          items: _items,
          businesses: _businesses,
          categories: _categories,
          lat: _lat,
          lng: _lng,
          radiusKm: _radiusKm,
          industry: industry,
          initialTab: initialTab,
          autofocus: autofocus,
        ),
      ),
    );
  }

  void _openItem(ExploreItem item) {
    ExploreActions.openCatalogItem(context, item);
  }

  void _openOffer(ExploreOffer offer) {
    ExploreActions.openOffer(context, offer);
  }

  void _openBusiness(ExploreBusiness business) {
    if (business.username.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannedProfileScreen(username: business.username),
      ),
    );
  }

  void _openSeeAll({
    required ExploreSeeAllKind kind,
    List<ExploreOffer> offers = const [],
    List<ExploreItem> items = const [],
    List<ExploreBusiness> businesses = const [],
  }) {
    // Same listing screen as Search — only the type tab filter differs.
    switch (kind) {
      case ExploreSeeAllKind.items:
        _openSearch(
          initialTab: ExploreSearchTab.catalog,
          autofocus: false,
        );
        return;
      case ExploreSeeAllKind.services:
        _openSearch(
          initialTab: ExploreSearchTab.services,
          autofocus: false,
        );
        return;
      case ExploreSeeAllKind.businesses:
        _openSearch(
          initialTab: ExploreSearchTab.business,
          autofocus: false,
        );
        return;
      case ExploreSeeAllKind.offers:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExploreSeeAllScreen(
              kind: kind,
              offers: offers,
              items: items,
              businesses: businesses,
            ),
          ),
        );
    }
  }

  static String _priceLabel(double price, {required String fallback}) {
    if (price <= 0) return fallback;
    final whole = price == price.roundToDouble();
    return whole
        ? 'Rs ${price.toStringAsFixed(0)}'
        : 'Rs ${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ExploreTheme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.scaffold,
      drawer: _ExploreDrawer(
        colors: colors,
        locationHint: _locationHint,
        onRefreshLocation: () {
          Navigator.of(context).pop();
          _bootstrap();
        },
        onSearch: () {
          Navigator.of(context).pop();
          _openSearch(autofocus: true);
        },
        onCart: () {
          Navigator.of(context).pop();
          _openCart();
        },
        onOrders: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OrdersListScreen(isBusinessView: false),
            ),
          );
        },
        onNotifications: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
        onBecomeBusiness: () {
          Navigator.of(context).pop();
          SubcriptionSheet.show(context);
        },
        onRewardOffers: () {
          Navigator.of(context).pop();
          if (_offers.isEmpty) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text('No reward offers nearby yet'),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                ),
              );
            return;
          }
          _openSeeAll(kind: ExploreSeeAllKind.offers, offers: _offers);
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: Column(
            children: [
              _buildHeader(colors),
              Expanded(
                child: RefreshIndicator(
                  color: colors.accent,
                  onRefresh: _load,
                  
                  child: _buildBody(colors),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCart() {
    final cart = context.read<ExploreCartProvider>();
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Your cart is empty'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExploreCartScreen()),
    );
  }

  Widget _buildHeader(_ExploreTheme colors) {
    return Container(
      color: colors.scaffold,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Menu',
                  onPressed: () =>
                      _scaffoldKey.currentState?.openDrawer(),
                  icon: Icon(
                    Icons.menu_rounded,
                    color: colors.primaryText,
                    size: 26,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Marketplace',
                      style: WaUi.toolsTitleOf(
                        color: colors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cart',
                  onPressed: _openCart,
                  icon: Consumer<ExploreCartProvider>(
                    builder: (context, cart, _) {
                      return Badge(
                        isLabelVisible: cart.hasItems,
                        backgroundColor: colors.accent,
                        label: Text(
                          '${cart.itemCount}',
                          style: TextStyle(color: colors.onAccent),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 24,
                          color: colors.primaryText,
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.notifications,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: colors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                height: 48,
                padding: const EdgeInsets.only(left: 14, right: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A3B3C)
                      : WaUi.searchBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF8A8D91)
                          : const Color(0xFF667781),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF8A8D91)
                              : const Color(0xFF667781),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(_ExploreTheme colors) {
    if (_loading) {
      return _ExploreSkeleton(colors: colors);
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 88),
          Icon(Icons.wifi_off_outlined, size: 48, color: colors.secondaryText),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(color: colors.secondaryText),
          ),
          Center(
            child: TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(foregroundColor: colors.accent),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final offers = _offers;
    final products = _productItems;
    final services = _serviceItems;
    final businesses = _businesses;
    final isPro = context.watch<ProfileProvider>().profile.isPro;

    final isEmpty = offers.isEmpty &&
        products.isEmpty &&
        services.isEmpty &&
        businesses.isEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 8),

        // 1. Banner slider
        _ExploreBannerCarousel(
          controller: _bannerController,
          currentPage: _bannerPage,
          banners: _banners,
          onPageChanged: (index) => setState(() => _bannerPage = index),
          colors: colors,
          onBannerTap: _handleBannerTap,
          onBecomeBusiness: () => SubcriptionSheet.show(context),
          onExploreOffers: () {
            if (offers.isNotEmpty) {
              _openSeeAll(kind: ExploreSeeAllKind.offers, offers: offers);
            }
          },
        ),

        const SizedBox(height: 20),

        // 2. Categories with icons
        _ExploreCategoryIconGrid(
          categories: _categories,
          selectedCategory: null,
          colors: colors,
          onSelect: (category) {
            if (category == null || category.isEmpty) return;
            _openSearch(
              industry: category,
              initialTab: ExploreSearchTab.business,
              autofocus: false,
            );
          },
        ),

        if (isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.emptyIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 36,
                color: colors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing nearby yet',
            textAlign: TextAlign.center,
            style: WaUi.headline.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Offers, items, services and businesses will appear when nearby PRO profiles complete their Business Profile.',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                color: colors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),

          // 3. Products nearby
          if (products.isNotEmpty) ...[
            _sectionHeader(
              title: 'Products nearby',
              icon: Icons.storefront_rounded,
              colors: colors,
              onViewAll: () => _openSeeAll(
                kind: ExploreSeeAllKind.items,
                items: products,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final cardW = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: products.take(6).map((item) {
                      return SizedBox(
                        width: cardW,
                        child: _ProductCard(
                          item: item,
                          onTap: () => _openItem(item),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
          if (!isPro && !_businessPromoDismissed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _ExplorePromoBanner(
                colors: colors,
                onTap: () => SubcriptionSheet.show(context),
                onDismiss: () =>
                    setState(() => _businessPromoDismissed = true),
              ),
            ),
          if (offers.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionHeader(
              title: 'Reward Offers',
              icon: Icons.card_giftcard_rounded,
              colors: colors,
              onViewAll: offers.length > 1
                  ? () => _openSeeAll(
                        kind: ExploreSeeAllKind.offers,
                        offers: offers,
                      )
                  : null,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: _RewardOfferCard.listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                itemCount: offers.length.clamp(0, 8),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _RewardOfferCard(
                    offer: offers[index],
                    colors: colors,
                    onTap: () => _openOffer(offers[index]),
                  );
                },
              ),
            ),
          ],
          if (services.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionHeader(
              title: 'Services',
              icon: Icons.design_services_rounded,
              colors: colors,
              onViewAll: () => _openSeeAll(
                kind: ExploreSeeAllKind.services,
                items: services,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final cardW = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: services.take(6).map((item) {
                      return SizedBox(
                        width: cardW,
                        child: _ProductCard(
                          item: item,
                          onTap: () => _openItem(item),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
          if (businesses.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader(
              title: 'Businesses nearby',
              icon: Icons.storefront_rounded,
              colors: colors,
              onViewAll: () => _openSeeAll(
                kind: ExploreSeeAllKind.businesses,
                businesses: businesses,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: businesses
                    .take(8)
                    .map(
                      (biz) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BusinessCard(
                          business: biz,
                          colors: colors,
                          onTap: () => _openBusiness(biz),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required IconData icon,
    required _ExploreTheme colors,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.2,
                letterSpacing: -0.3,
                color: colors.primaryText,
              ),
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExploreDrawer extends StatelessWidget {
  final _ExploreTheme colors;
  final String locationHint;
  final VoidCallback onRefreshLocation;
  final VoidCallback onSearch;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onNotifications;
  final VoidCallback onBecomeBusiness;
  final VoidCallback onRewardOffers;

  const _ExploreDrawer({
    required this.colors,
    required this.locationHint,
    required this.onRefreshLocation,
    required this.onSearch,
    required this.onCart,
    required this.onOrders,
    required this.onNotifications,
    required this.onBecomeBusiness,
    required this.onRewardOffers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = context.watch<ProfileProvider>().profile.isPro;
    final cartCount = context.watch<ExploreCartProvider>().itemCount;
    final l10n = context.l10n;
    final softBg = isDark ? const Color(0xFF111111) : const Color(0xFFF7F7F7);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final ink = isDark ? Colors.white : Colors.black;

    return Drawer(
      backgroundColor: softBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      color: ink,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Nearby shops, offers & more',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                children: [
                  _DrawerTile(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                    subtitle: locationHint,
                    colors: colors,
                    cardBg: cardBg,
                    onTap: onRefreshLocation,
                  ),
                  _DrawerTile(
                    icon: Icons.search_rounded,
                    title: 'Search nearby',
                    subtitle: 'Items, services, catalog & shops',
                    colors: colors,
                    cardBg: cardBg,
                    onTap: onSearch,
                  ),
                  _DrawerTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My cart',
                    subtitle: cartCount > 0
                        ? '$cartCount item${cartCount == 1 ? '' : 's'} waiting'
                        : 'Your bag is empty',
                    colors: colors,
                    cardBg: cardBg,
                    trailing: cartCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '$cartCount',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                    onTap: onCart,
                  ),
                  _DrawerTile(
                    icon: Icons.receipt_long_rounded,
                    title: l10n.myOrders,
                    subtitle: 'Track what you ordered',
                    colors: colors,
                    cardBg: cardBg,
                    onTap: onOrders,
                  ),
                  _DrawerTile(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Reward offers',
                    subtitle: 'Stamps & freebies nearby',
                    colors: colors,
                    cardBg: cardBg,
                    onTap: onRewardOffers,
                  ),
                  _DrawerTile(
                    icon: Icons.notifications_none_rounded,
                    title: l10n.notifications,
                    subtitle: 'Updates & alerts',
                    colors: colors,
                    cardBg: cardBg,
                    onTap: onNotifications,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      'For your business',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.mutedText,
                      ),
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.storefront_rounded,
                    title: isPro ? 'Business Pro' : 'Become a Business',
                    subtitle: isPro
                        ? 'You’re all set with Pro'
                        : 'List products & get nearby customers',
                    colors: colors,
                    cardBg: cardBg,
                    accentIcon: true,
                    onTap: onBecomeBusiness,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _ExploreTheme colors;
  final Color cardBg;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool accentIcon;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.cardBg,
    required this.onTap,
    this.trailing,
    this.accentIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : Colors.black;
    final iconColor = ink;
    final iconBg = ink.withValues(alpha: isDark ? 0.10 : 0.06);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: colors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ] else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.mutedText.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreBannerCarousel extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final List<ExploreBanner> banners;
  final ValueChanged<int> onPageChanged;
  final _ExploreTheme colors;
  final ValueChanged<ExploreBanner> onBannerTap;
  final VoidCallback onBecomeBusiness;
  final VoidCallback onExploreOffers;

  const _ExploreBannerCarousel({
    required this.controller,
    required this.currentPage,
    required this.banners,
    required this.onPageChanged,
    required this.colors,
    required this.onBannerTap,
    required this.onBecomeBusiness,
    required this.onExploreOffers,
  });

  List<ExploreBanner> get _slides {
    if (banners.isNotEmpty) return banners;
    return const [
      ExploreBanner(
        id: 'fallback-1',
        tag: 'BUSINESS',
        title: 'BECOME A\nBUSINESS',
        subtitle: 'List products, offers & get nearby customers',
        buttonText: 'GET STARTED',
        gradientStart: '#0F766E',
        gradientEnd: '#EA580C',
        actionType: 'become_business',
      ),
      ExploreBanner(
        id: 'fallback-2',
        tag: 'NEAR YOU',
        title: 'EXPLORE\nLOCAL DEALS',
        subtitle: 'Discover offers & shops around you',
        buttonText: 'EXPLORE NOW',
        gradientStart: '#14532D',
        gradientEnd: '#CA8A04',
        actionType: 'offers',
      ),
      ExploreBanner(
        id: 'fallback-3',
        tag: 'PRO',
        title: 'GROW YOUR\nVISIBILITY',
        subtitle: 'Orders, loyalty & attendance tools',
        buttonText: 'TRY BUSINESS PRO',
        gradientStart: '#18181B',
        gradientEnd: '#3F3F46',
        actionType: 'become_business',
      ),
    ];
  }

  Color _hex(String raw, Color fallback) {
    var hex = raw.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return fallback;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? fallback : Color(value);
  }

  VoidCallback _tapFor(ExploreBanner banner) {
    return () {
      if (banners.isEmpty) {
        if (banner.actionType == 'offers') {
          onExploreOffers();
        } else {
          onBecomeBusiness();
        }
        return;
      }
      onBannerTap(banner);
    };
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final b = slides[index];
              final start = _hex(b.gradientStart, const Color(0xFF0F766E));
              final end = _hex(b.gradientEnd, const Color(0xFFEA580C));
              final hasOverlayText = b.tag.isNotEmpty ||
                  b.title.isNotEmpty ||
                  b.subtitle.isNotEmpty ||
                  b.buttonText.isNotEmpty;
              final imageOnly = b.image.isNotEmpty && !hasOverlayText;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: _tapFor(b),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (b.image.isNotEmpty)
                          CachedAppImage(
                            url: b.image,
                            fit: BoxFit.cover,
                            placeholder: const ImageShimmerPlaceholder(),
                            error: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [start, end],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          )
                        else
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [start, end],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        if (!imageOnly && b.image.isNotEmpty)
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        if (!imageOnly)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (b.tag.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      b.tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                if (b.title.isNotEmpty)
                                  Text(
                                    b.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                      letterSpacing: -0.4,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (b.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    b.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (b.buttonText.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      b.buttonText,
                                      style: const TextStyle(
                                        color: Color(0xFF0F766E),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final active = index == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF10A375)
                    : colors.secondaryText.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

IconData _materialIconFromName(String name) {
  switch (name) {
    case 'devices_rounded':
      return Icons.devices_rounded;
    case 'shopping_bag_rounded':
      return Icons.shopping_bag_rounded;
    case 'spa_rounded':
      return Icons.spa_rounded;
    case 'school_rounded':
      return Icons.school_rounded;
    case 'account_balance_rounded':
      return Icons.account_balance_rounded;
    case 'home_work_rounded':
      return Icons.home_work_rounded;
    case 'restaurant_rounded':
      return Icons.restaurant_rounded;
    case 'movie_rounded':
      return Icons.movie_rounded;
    case 'storefront_rounded':
      return Icons.storefront_rounded;
    case 'checkroom_rounded':
      return Icons.checkroom_rounded;
    default:
      return Icons.category_rounded;
  }
}

class _ExploreCategoryIconGrid extends StatelessWidget {
  final List<ExploreCategoryItem> categories;
  final String? selectedCategory;
  final _ExploreTheme colors;
  final ValueChanged<String?> onSelect;

  const _ExploreCategoryIconGrid({
    required this.categories,
    required this.selectedCategory,
    required this.colors,
    required this.onSelect,
  });

  List<ExploreCategoryItem> get _items {
    if (categories.isNotEmpty) return categories;
    return kBusinessCategories
        .asMap()
        .entries
        .map(
          (e) => ExploreCategoryItem(
            id: e.value,
            name: e.value,
            label: e.value,
            icon: 'category_rounded',
            sortOrder: e.key,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: colors.primaryText,
                ),
              ),
              if (selectedCategory != null)
                GestureDetector(
                  onTap: () => onSelect(null),
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final cat = items[index];
              final label = cat.label.isNotEmpty
                  ? cat.label
                  : businessCategoryLabel(context, cat.name);
              final isSelected = selectedCategory == cat.name;
              final icon = _materialIconFromName(cat.icon);

              return GestureDetector(
                onTap: () => onSelect(cat.name),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accent.withValues(alpha: 0.12)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: cat.iconUrl.isNotEmpty
                            ? CachedAppImage(
                                url: cat.iconUrl,
                                fit: BoxFit.cover,
                                placeholder: const ImageShimmerPlaceholder(),
                                error: Icon(
                                  icon,
                                  size: 26,
                                  color: isSelected
                                      ? colors.accent
                                      : colors.secondaryText,
                                ),
                              )
                            : Icon(
                                icon,
                                size: 26,
                                color: isSelected
                                    ? colors.accent
                                    : colors.secondaryText,
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? colors.accent
                              : colors.primaryText,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExplorePromoBanner extends StatelessWidget {
  final _ExploreTheme colors;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const _ExplorePromoBanner({
    required this.colors,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const titleColor = Colors.white;
    const bodyColor = Color(0xFF94A3B8);
    const accentGreen = Color(0xFF10A375);
    const iconBgStart = Color(0xFF134E3A);
    const iconBgEnd = Color(0xFF0B3D2E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF0B2E24)],
          ),
          border: Border.all(
            color: accentGreen.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: accentGreen.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [iconBgStart, iconBgEnd],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentGreen.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: accentGreen,
                    size: 26,
                  ),
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
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  'Become a Business',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                    color: titleColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onDismiss != null)
                            GestureDetector(
                              onTap: onDismiss,
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: bodyColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.unlockBusinessProDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: bodyColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.tryBusinessPro,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: Colors.white,
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

class _RewardOfferCard extends StatelessWidget {
  static const double cardWidth = 200;
  static const double previewRatio = 0.72;
  static double get previewHeight => cardWidth / previewRatio;
  // Title + business + button + paddings (with text-scale headroom)
  static const double footerHeight = 118;
  static double get listHeight => previewHeight + footerHeight;

  final ExploreOffer offer;
  final _ExploreTheme colors;
  final VoidCallback onTap;

  const _RewardOfferCard({
    required this.offer,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = offer.toRewardProgram();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: listHeight,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  offer.hasDesign
                      ? ColoredBox(
                          color: colors.surface,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: cardWidth,
                              height: cardWidth /
                                  offer.design!.aspectRatio.clamp(0.55, 0.85),
                              child: LoyaltyCardDesignRenderer(
                                design: offer.design!,
                                borderRadius: 0,
                                shadows: const [],
                              ),
                            ),
                          ),
                        )
                      : _ClassicRewardPreview(program: program),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF111827), Color(0xFF374151)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 12,
                            color: Color(0xFF10A375),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'REWARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: footerHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title.isNotEmpty
                          ? offer.title
                          : 'Special Reward Offer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      offer.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'View Offer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

class _ClassicRewardPreview extends StatelessWidget {
  final RewardProgram program;

  const _ClassicRewardPreview({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = program.theme;
    return ColoredBox(
      color: theme.cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.label.isNotEmpty)
              Text(
                program.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.cardTextColor.withValues(alpha: 0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.cardTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                program.stamps.clamp(1, 8),
                (i) => RewardStampSlot(
                  filled: false,
                  theme: theme,
                  stampIconUrl: program.stampIcon,
                  unstampIconUrl: program.unstampIcon,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  // Used only for skeleton dimensions:
  static const double cardWidth = 170;
  static double get cardHeight => ShopProductCard.heightForWidth(cardWidth);
  static double get imageHeight =>
      cardWidth / ShopProductCard.imageAspectRatio;

  final ExploreItem item;
  final VoidCallback onTap;

  const _ProductCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShopProductCard(
      title: item.name,
      imageUrl: item.image,
      category: item.category,
      sellerName: item.businessName,
      price: item.price,
      avgRating: item.avgRating,
      badgeLabel: item.isService ? 'Service' : 'Shop Product',
      onTap: onTap,
      isDark: isDark,
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ExploreItem item;
  final _ExploreTheme colors;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  static String _formatTitle(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Tall image on the left
            SizedBox(
              width: 110,
              height: 110,
              child: Container(
                color: const Color(0xFFF4F4F5),
                child: _exploreImage(
                  item.image,
                  Icons.content_cut_rounded,
                  colors,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category or business
                    Text(
                      item.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Title
                    Text(
                      _formatTitle(item.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    // Address
                    if (item.businessAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF71717A),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.businessAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF71717A),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: Text(
                            _ExploreScreenState._priceLabel(
                              item.price,
                              fallback: '',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ),
                        // Book button
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Rating
                    if (item.avgRating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _BusinessCard extends StatelessWidget {
  final ExploreBusiness business;
  final _ExploreTheme colors;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.business,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = business.coverPhoto?.isNotEmpty == true
        ? business.coverPhoto
        : business.profilePhoto;
    final categoryLabel = business.businessCategory.isEmpty
        ? ''
        : businessCategoryLabel(context, business.businessCategory);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Square image
            SizedBox(
              width: 90,
              height: 90,
              child: Container(
                color: const Color(0xFFF4F4F5),
                child: _exploreImage(
                  photo,
                  Icons.storefront_outlined,
                  colors,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ),
                        if (business.distanceKm != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${business.distanceKm!.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Stars
                        if (business.reviewCount > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${business.avgRating.toStringAsFixed(1)} (${business.reviewCount})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ] else
                          Text(
                            'New Store',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: colors.secondaryText,
                            ),
                          ),
                        const Spacer(),
                        // Visit button
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Visit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _ExploreSkeleton extends StatelessWidget {
  final _ExploreTheme colors;

  const _ExploreSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),

          // 1. Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: 18,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ShimmerBox(
                  width: i == 0 ? 18 : 8,
                  height: 8,
                  borderRadius: 4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Categories
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 110, height: 17, borderRadius: 6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, _) => const _SkeletonCategoryChip(),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Products nearby (2-col grid)
          _SkeletonSectionHeader(titleWidth: 148, borderColor: colors.border),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final cardW = (constraints.maxWidth - spacing) / 2;
                final cardH = ShopProductCard.heightForWidth(cardW);
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(
                    4,
                    (_) => SizedBox(
                      width: cardW,
                      height: cardH,
                      child: _SkeletonProductCard(
                        borderColor: colors.border,
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 4. Reward Offers (horizontal)
          _SkeletonSectionHeader(titleWidth: 128, borderColor: colors.border),
          const SizedBox(height: 14),
          SizedBox(
            height: _RewardOfferCard.listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) =>
                  _SkeletonRewardCard(borderColor: colors.border),
            ),
          ),

          const SizedBox(height: 24),

          // 5. Services (2-col grid, same card shape)
          _SkeletonSectionHeader(titleWidth: 88, borderColor: colors.border),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final cardW = (constraints.maxWidth - spacing) / 2;
                final cardH = ShopProductCard.heightForWidth(cardW);
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(
                    2,
                    (_) => SizedBox(
                      width: cardW,
                      height: cardH,
                      child: _SkeletonProductCard(
                        borderColor: colors.border,
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 6. Businesses nearby (row cards)
          _SkeletonSectionHeader(titleWidth: 168, borderColor: colors.border),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SkeletonBusinessCard(borderColor: colors.border),
                const SizedBox(height: 12),
                _SkeletonBusinessCard(borderColor: colors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  final double titleWidth;
  final bool showViewAll;
  final Color borderColor;

  const _SkeletonSectionHeader({
    required this.titleWidth,
    this.showViewAll = true,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ShimmerBox(width: titleWidth, height: 18, borderRadius: 6),
          const Spacer(),
          if (showViewAll)
            const ShimmerBox(width: 56, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

class _SkeletonCategoryChip extends StatelessWidget {
  const _SkeletonCategoryChip();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 72,
      child: Column(
        children: [
          ShimmerBox(width: 58, height: 58, borderRadius: 18),
          SizedBox(height: 6),
          ShimmerBox(width: 48, height: 10, borderRadius: 4),
          SizedBox(height: 4),
          ShimmerBox(width: 36, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

class _SkeletonRewardCard extends StatelessWidget {
  final Color borderColor;

  const _SkeletonRewardCard({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _RewardOfferCard.cardWidth,
      height: _RewardOfferCard.listHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ShimmerBox(
                  width: _RewardOfferCard.cardWidth,
                  height: _RewardOfferCard.previewHeight,
                  borderRadius: 0,
                ),
                const Positioned(
                  top: 10,
                  left: 10,
                  child: ShimmerBox(width: 72, height: 22, borderRadius: 14),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _RewardOfferCard.footerHeight,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 96, height: 12, borderRadius: 6),
                  Spacer(),
                  ShimmerBox(
                    width: double.infinity,
                    height: 32,
                    borderRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  final Color borderColor;
  final double width;
  final double height;

  const _SkeletonProductCard({
    required this.borderColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final imageH = width / ShopProductCard.imageAspectRatio;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ShimmerBox(
                width: width,
                height: imageH,
                borderRadius: 0,
              ),
              const Positioned(
                top: 8,
                left: 8,
                child: ShimmerBox(width: 78, height: 20, borderRadius: 20),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: width * 0.78, height: 12, borderRadius: 6),
                  const SizedBox(height: 6),
                  ShimmerBox(width: width * 0.55, height: 12, borderRadius: 6),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 92, height: 18, borderRadius: 12),
                  const SizedBox(height: 8),
                  ShimmerBox(width: width * 0.62, height: 10, borderRadius: 6),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 80, height: 12, borderRadius: 6),
                  const Spacer(),
                  ShimmerBox(width: width - 20, height: 1, borderRadius: 1),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 72, height: 15, borderRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBusinessCard extends StatelessWidget {
  final Color borderColor;

  const _SkeletonBusinessCard({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Row(
        children: [
          ShimmerBox(width: 90, height: 90, borderRadius: 0),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ShimmerBox(
                            width: 120,
                            height: 14,
                            borderRadius: 6,
                          ),
                        ),
                      ),
                      ShimmerBox(width: 44, height: 18, borderRadius: 10),
                    ],
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(width: 88, height: 11, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 140, height: 11, borderRadius: 6),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ShimmerBox(width: 56, height: 12, borderRadius: 6),
                      Spacer(),
                      ShimmerBox(width: 58, height: 28, borderRadius: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _exploreImage(String? url, IconData icon, _ExploreTheme colors) {
  final fallback = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.imageFallbackStart, colors.imageFallbackEnd],
      ),
    ),
    child: Icon(icon, size: 34, color: colors.imageFallbackIcon),
  );

  if (url == null || url.isEmpty) return fallback;

  return CachedAppImage(
    url: url,
    fit: BoxFit.cover,
    placeholder: const ImageShimmerPlaceholder(),
    error: fallback,
  );
}

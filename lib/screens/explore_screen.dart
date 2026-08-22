import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/screens/explore_cart_screen.dart';
import 'package:tapni_app/screens/explore_see_all_screen.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/business_categories.dart';
import 'package:tapni_app/utils/explore_actions.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repo = ExploreRepo();
  final _searchController = TextEditingController();

  List<ExploreBusiness> _businesses = [];
  List<ExploreOffer> _offers = [];
  List<ExploreItem> _items = [];
  bool _loading = true;
  String? _error;
  String? _selectedIndustry;
  double? _lat;
  double? _lng;
  String _locationHint = 'Set your location';
  double _radiusKm = 15;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
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

    final res = await _repo.getNearby(
      lat: _lat,
      lng: _lng,
      radiusKm: _radiusKm,
      industry: _selectedIndustry,
      city: (_lat == null && _searchController.text.trim().isNotEmpty)
          ? _searchController.text.trim()
          : null,
    );

    if (!mounted) return;

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
    setState(() {
      _loading = false;
      _businesses = parsed.businesses;
      _offers = parsed.offers;
      _items = parsed.items;
      if (_businesses.isNotEmpty) {
        final first = _businesses.first;
        if (first.locationLabel.isNotEmpty) {
          _locationHint = first.locationLabel;
        } else if (_lat != null) {
          _locationHint = 'Near you';
        }
      }
    });
  }

  List<ExploreItem> get _allCatalog {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.businessName.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ExploreItem> get _productItems =>
      _allCatalog.where((i) => !i.isService).toList();

  List<ExploreItem> get _serviceItems =>
      _allCatalog.where((i) => i.isService).toList();

  List<ExploreBusiness> get _filteredBusinesses {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _businesses;
    return _businesses
        .where(
          (b) =>
              b.displayName.toLowerCase().contains(q) ||
              b.businessCategory.toLowerCase().contains(q) ||
              b.city.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ExploreOffer> get _filteredOffers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _offers;
    return _offers
        .where(
          (o) =>
              o.title.toLowerCase().contains(q) ||
              o.businessName.toLowerCase().contains(q),
        )
        .toList();
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

  static String _priceLabel(double price, {required String fallback}) {
    if (price <= 0) return fallback;
    final whole = price == price.roundToDouble();
    return whole
        ? 'Rs ${price.toStringAsFixed(0)}'
        : 'Rs ${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: WaUi.navGreen,
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final searching = _searchController.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 14),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: _bootstrap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WaUi.chipBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: WaUi.navGreen,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _bootstrap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to refresh location',
                        style: WaUi.label.copyWith(
                          color: WaUi.secondaryText,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _HeaderIconButton(
                tooltip: 'Cart',
                onPressed: () {
                  final cart = context.read<ExploreCartProvider>();
                  if (cart.isEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
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
                    MaterialPageRoute(
                      builder: (_) => const ExploreCartScreen(),
                    ),
                  );
                },
                icon: Consumer<ExploreCartProvider>(
                  builder: (context, cart, _) {
                    return Badge(
                      isLabelVisible: cart.hasItems,
                      backgroundColor: WaUi.navGreen,
                      label: Text('${cart.itemCount}'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    );
                  },
                ),
              ),
              _HeaderIconButton(
                tooltip: context.l10n.notifications,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_lat == null) _load();
            },
            decoration: InputDecoration(
              hintText: 'Search items, services, offers...',
              hintStyle: WaUi.body.copyWith(
                color: const Color(0xFF8B97A0),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF8B97A0),
              ),
              suffixIcon: searching
                  ? IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF8B97A0),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD7DCE1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedIndustry == null,
                  onTap: () {
                    setState(() => _selectedIndustry = null);
                    _load();
                  },
                ),
                ...kBusinessCategories.map((category) {
                  final selected = _selectedIndustry == category;
                  return _CategoryChip(
                    label: businessCategoryLabel(context, category),
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedIndustry = selected ? null : category;
                      });
                      _load();
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _ExploreSkeleton();
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 88),
          const Icon(Icons.wifi_off_outlined, size: 48, color: WaUi.secondaryText),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: WaUi.secondaryText),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(foregroundColor: WaUi.navGreen),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final offers = _filteredOffers;
    final products = _productItems;
    final services = _serviceItems;
    final businesses = _filteredBusinesses;

    final isEmpty = offers.isEmpty &&
        products.isEmpty &&
        services.isEmpty &&
        businesses.isEmpty;

    if (isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 88),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 36,
                color: WaUi.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing nearby yet',
            textAlign: TextAlign.center,
            style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Offers, items, services and businesses will appear when nearby PRO profiles complete their Business Profile.',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: WaUi.secondaryText, height: 1.4),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _radiusKm = (_radiusKm + 10).clamp(5, 100);
                  _selectedIndustry = null;
                });
                _load();
              },
              style: TextButton.styleFrom(foregroundColor: WaUi.navGreen),
              child: Text('Widen to ${_radiusKm.toInt()} km'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (offers.isNotEmpty) ...[
          const SizedBox(height: 18),
          _sectionHeader(
            title: 'Reward offers',
            onViewAll: offers.length > 1
                ? () => _openSeeAll(
                      kind: ExploreSeeAllKind.offers,
                      offers: offers,
                    )
                : null,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _RewardOfferCard.listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: offers.length.clamp(0, 8),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _RewardOfferCard(
                  offer: offers[index],
                  onTap: () => _openOffer(offers[index]),
                );
              },
            ),
          ),
        ],
        if (products.isNotEmpty) ...[
          const SizedBox(height: 26),
          _sectionHeader(
            title: 'Items',
            onViewAll: () => _openSeeAll(
              kind: ExploreSeeAllKind.items,
              items: products,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _ProductCard.cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length.clamp(0, 10),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _ProductCard(
                  item: products[index],
                  onTap: () => _openItem(products[index]),
                );
              },
            ),
          ),
        ],
        if (services.isNotEmpty) ...[
          const SizedBox(height: 26),
          _sectionHeader(
            title: 'Services',
            onViewAll: () => _openSeeAll(
              kind: ExploreSeeAllKind.services,
              items: services,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: services
                  .take(5)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ServiceCard(
                        item: item,
                        onTap: () => _openItem(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (businesses.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionHeader(
            title: 'Businesses nearby',
            onViewAll: () => _openSeeAll(
              kind: ExploreSeeAllKind.businesses,
              businesses: businesses,
            ),
          ),
          const SizedBox(height: 12),
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
                        onTap: () => _openBusiness(biz),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: WaUi.sectionHeader.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: WaUi.navGreen,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: WaUi.label.copyWith(
                  color: WaUi.navGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: icon,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.black : const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? Colors.black : const Color(0xFFE6E9ED),
              ),
            ),
            child: Text(
              label,
              style: WaUi.label.copyWith(
                color: selected ? Colors.white : WaUi.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardOfferCard extends StatelessWidget {
  static const double cardWidth = 164;
  static const double previewRatio = 0.65;
  static double get previewHeight => cardWidth / previewRatio;
  static double get listHeight => previewHeight + 34;

  final ExploreOffer offer;
  final VoidCallback onTap;

  const _RewardOfferCard({
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = offer.toRewardProgram();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: previewHeight,
                width: cardWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: offer.hasDesign
                        ? ColoredBox(
                            color: Colors.white,
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
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                offer.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.label.copyWith(
                  color: const Color(0xFF54656F),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
                ),
              ),
            const SizedBox(height: 4),
            Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.cardTextColor,
                fontSize: 13,
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
                  size: 22,
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
  static const double cardHeight = 242;
  static const double cardWidth = 164;
  static const double imageHeight = 128;

  final ExploreItem item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _exploreImage(item.image, Icons.lunch_dining_outlined),
                    if (item.avgRating > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Color(0xFFF5A623),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.avgRating.toStringAsFixed(1),
                                style: WaUi.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  color: WaUi.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.label.copyWith(
                          color: const Color(0xFF667781),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _ExploreScreenState._priceLabel(
                                item.price,
                                fallback: 'View',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 15,
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
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ExploreItem item;
  final VoidCallback onTap;

  const _ServiceCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: _exploreImage(item.image, Icons.content_cut_rounded),
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
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (item.avgRating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF5A623),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.avgRating.toStringAsFixed(1),
                              style: WaUi.label.copyWith(
                                fontWeight: FontWeight.w700,
                                color: WaUi.primaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.label.copyWith(
                          color: const Color(0xFF667781),
                          fontSize: 12,
                        ),
                      ),
                      if (item.businessAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Color(0xFF8B97A0),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.businessAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WaUi.label.copyWith(
                                  color: const Color(0xFF8B97A0),
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
                          Expanded(
                            child: Text(
                              _ExploreScreenState._priceLabel(
                                item.price,
                                fallback: 'Book',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Details',
                              style: WaUi.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
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
}

class _BusinessCard extends StatelessWidget {
  final ExploreBusiness business;
  final VoidCallback onTap;

  const _BusinessCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = business.coverPhoto?.isNotEmpty == true
        ? business.coverPhoto
        : business.profilePhoto;
    final categoryLabel = business.businessCategory.isEmpty
        ? ''
        : businessCategoryLabel(context, business.businessCategory);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 7,
                child: _exploreImage(photo, Icons.storefront_outlined),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (categoryLabel.isNotEmpty) categoryLabel,
                        if (business.distanceKm != null)
                          '${business.distanceKm!.toStringAsFixed(1)} km',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.label.copyWith(color: WaUi.secondaryText),
                    ),
                    if (business.reviewCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF5A623),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${business.avgRating.toStringAsFixed(1)} (${business.reviewCount})',
                            style: WaUi.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: WaUi.primaryText,
                            ),
                          ),
                        ],
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
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 18),
          const _SkeletonSectionHeader(titleWidth: 130),
          const SizedBox(height: 12),
          SizedBox(
            height: _RewardOfferCard.listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const _SkeletonRewardCard(),
            ),
          ),
          const SizedBox(height: 26),
          const _SkeletonSectionHeader(titleWidth: 70),
          const SizedBox(height: 12),
          SizedBox(
            height: _ProductCard.cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const _SkeletonProductCard(),
            ),
          ),
          const SizedBox(height: 26),
          const _SkeletonSectionHeader(titleWidth: 90, showViewAll: false),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SkeletonServiceCard(),
                SizedBox(height: 12),
                _SkeletonServiceCard(),
                SizedBox(height: 12),
                _SkeletonServiceCard(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SkeletonSectionHeader(titleWidth: 168),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SkeletonBusinessCard(),
                SizedBox(height: 12),
                _SkeletonBusinessCard(),
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

  const _SkeletonSectionHeader({
    required this.titleWidth,
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _SkeletonRewardCard extends StatelessWidget {
  const _SkeletonRewardCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _RewardOfferCard.cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: _RewardOfferCard.cardWidth,
            height: _RewardOfferCard.previewHeight,
            borderRadius: 18,
          ),
          const SizedBox(height: 8),
          const ShimmerBox(width: 108, height: 12, borderRadius: 6),
        ],
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ProductCard.cardWidth,
      height: _ProductCard.cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: _ProductCard.cardWidth,
            height: _ProductCard.imageHeight,
            borderRadius: 0,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(11, 10, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 118, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 86, height: 12, borderRadius: 6),
                  Spacer(),
                  Row(
                    children: [
                      ShimmerBox(width: 64, height: 14, borderRadius: 6),
                      Spacer(),
                      ShimmerBox(
                        width: 28,
                        height: 28,
                        shape: BoxShape.circle,
                      ),
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

class _SkeletonServiceCard extends StatelessWidget {
  const _SkeletonServiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 92, height: 92, borderRadius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ShimmerBox(
                          width: 140,
                          height: 15,
                          borderRadius: 6,
                        ),
                      ),
                    ),
                    ShimmerBox(width: 28, height: 14, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 110, height: 12, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 148, height: 11, borderRadius: 6),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(width: 56, height: 14, borderRadius: 6),
                    Spacer(),
                    ShimmerBox(width: 68, height: 28, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBusinessCard extends StatelessWidget {
  const _SkeletonBusinessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ShimmerBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  borderRadius: 0,
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 160, height: 16, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 12, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 88, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _exploreImage(String? url, IconData icon) {
  final fallback = DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F5F7), Color(0xFFE6E9ED)],
      ),
    ),
    child: Icon(icon, size: 34, color: const Color(0xFF9AA3AB)),
  );

  if (url == null || url.isEmpty) return fallback;

  return Image.network(
    url,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return fallback;
    },
    errorBuilder: (_, _, _) => fallback,
  );
}

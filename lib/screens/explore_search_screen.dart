import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/business_categories.dart';
import 'package:tapni_app/utils/explore_actions.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';
import 'package:tapni_app/widgets/shop_product_card.dart';

enum ExploreSearchTab { items, services, catalog, business }

class ExploreSearchScreen extends StatefulWidget {
  final List<ExploreOffer> offers;
  final List<ExploreItem> items;
  final List<ExploreBusiness> businesses;
  final List<ExploreCategoryItem> categories;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? industry;
  final ExploreSearchTab initialTab;
  final bool autofocus;

  const ExploreSearchScreen({
    super.key,
    this.offers = const [],
    this.items = const [],
    this.businesses = const [],
    this.categories = const [],
    this.lat,
    this.lng,
    this.radiusKm = 15,
    this.industry,
    this.initialTab = ExploreSearchTab.items,
    this.autofocus = true,
  });

  @override
  State<ExploreSearchScreen> createState() => _ExploreSearchScreenState();
}

class _ExploreSearchScreenState extends State<ExploreSearchScreen> {
  static const _pageSize = 20;

  final _repo = ExploreRepo();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();

  late ExploreSearchTab _tab;
  Timer? _debounce;

  List<ExploreItem> _items = [];
  List<ExploreItem> _services = [];
  List<ExploreItem> _catalog = [];
  List<ExploreBusiness> _businesses = [];

  int _itemsPage = 0;
  int _servicesPage = 0;
  int _catalogPage = 0;
  int _businessPage = 0;

  bool _itemsHasMore = true;
  bool _servicesHasMore = true;
  bool _catalogHasMore = true;
  bool _businessHasMore = true;

  String _itemsQuery = '';
  String _servicesQuery = '';
  String _catalogQuery = '';
  String _businessQuery = '';

  String? _itemsIndustry;
  String? _servicesIndustry;
  String? _catalogIndustry;
  String? _businessIndustry;

  bool _loading = false;
  bool _loadingMore = false;
  String _activeQuery = '';
  late String? _industry;

  List<String> get _categoryOptions {
    final fromApi = widget.categories
        .map((c) => c.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (fromApi.isNotEmpty) return fromApi;
    return List<String>.from(kBusinessCategories);
  }

  @override
  void initState() {
    super.initState();
    _industry = widget.industry?.trim().isEmpty == true
        ? null
        : widget.industry?.trim();
    _tab = widget.initialTab;
    _seedFromInitial();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.autofocus) _searchFocus.requestFocus();
      _refreshCurrentTab(reset: true);
    });
  }

  void _seedFromInitial() {
    // Category / filtered entry should wait for API — don't flash unfiltered seed.
    if (_industry != null && _industry!.isNotEmpty) return;

    _items = widget.items
        .where((i) => !i.isService && i.catalogType == 'menu')
        .toList();
    _services = widget.items.where((i) => i.isService).toList();
    _catalog = widget.items
        .where((i) => !i.isService && i.catalogType != 'menu')
        .toList();
    _businesses = List<ExploreBusiness>.from(widget.businesses);

    // Seeded lists may already be complete for the first page.
    _itemsPage = _items.isEmpty ? 0 : 1;
    _servicesPage = _services.isEmpty ? 0 : 1;
    _catalogPage = _catalog.isEmpty ? 0 : 1;
    _businessPage = _businesses.isEmpty ? 0 : 1;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = _searchController.text.trim();
      if (next == _activeQuery) return;
      _activeQuery = next;
      _refreshCurrentTab(reset: true);
    });
    setState(() {}); // update clear button
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  String get _apiType {
    switch (_tab) {
      case ExploreSearchTab.items:
        return 'items';
      case ExploreSearchTab.services:
        return 'services';
      case ExploreSearchTab.catalog:
        return 'catalog';
      case ExploreSearchTab.business:
        return 'business';
    }
  }

  bool get _hasMore {
    switch (_tab) {
      case ExploreSearchTab.items:
        return _itemsHasMore;
      case ExploreSearchTab.services:
        return _servicesHasMore;
      case ExploreSearchTab.catalog:
        return _catalogHasMore;
      case ExploreSearchTab.business:
        return _businessHasMore;
    }
  }

  int get _page {
    switch (_tab) {
      case ExploreSearchTab.items:
        return _itemsPage;
      case ExploreSearchTab.services:
        return _servicesPage;
      case ExploreSearchTab.catalog:
        return _catalogPage;
      case ExploreSearchTab.business:
        return _businessPage;
    }
  }

  int _countFor(ExploreSearchTab tab) {
    switch (tab) {
      case ExploreSearchTab.items:
        return _items.length;
      case ExploreSearchTab.services:
        return _services.length;
      case ExploreSearchTab.catalog:
        return _catalog.length;
      case ExploreSearchTab.business:
        return _businesses.length;
    }
  }

  Future<void> _refreshCurrentTab({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        switch (_tab) {
          case ExploreSearchTab.items:
            _items = [];
            _itemsPage = 0;
            _itemsHasMore = true;
          case ExploreSearchTab.services:
            _services = [];
            _servicesPage = 0;
            _servicesHasMore = true;
          case ExploreSearchTab.catalog:
            _catalog = [];
            _catalogPage = 0;
            _catalogHasMore = true;
          case ExploreSearchTab.business:
            _businesses = [];
            _businessPage = 0;
            _businessHasMore = true;
        }
      });
    }
    await _fetchPage(page: 1, append: false);
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    await _fetchPage(page: _page + 1, append: true);
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    if (append) {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    } else if (!_loading) {
      setState(() => _loading = true);
    }

    final tabAtStart = _tab;
    final queryAtStart = _activeQuery;

    final res = await _repo.getNearby(
      lat: widget.lat,
      lng: widget.lng,
      radiusKm: widget.radiusKm,
      industry: _industry,
      q: queryAtStart.isEmpty ? null : queryAtStart,
      type: _apiType,
      page: page,
      limit: _pageSize,
    );

    if (!mounted) return;
    if (tabAtStart != _tab || queryAtStart != _activeQuery) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      return;
    }

    if (!res.success) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      return;
    }

    final parsed = _repo.parseNearby(res.data);
    final industryAtStart = _industry;

    setState(() {
      switch (tabAtStart) {
        case ExploreSearchTab.items:
          final next = append
              ? _mergeItems(_items, parsed.items)
              : parsed.items;
          _items = next;
          _itemsPage = parsed.page;
          _itemsHasMore = parsed.hasMore;
          _itemsQuery = queryAtStart;
          _itemsIndustry = industryAtStart;
        case ExploreSearchTab.services:
          final next = append
              ? _mergeItems(_services, parsed.items)
              : parsed.items;
          _services = next;
          _servicesPage = parsed.page;
          _servicesHasMore = parsed.hasMore;
          _servicesQuery = queryAtStart;
          _servicesIndustry = industryAtStart;
        case ExploreSearchTab.catalog:
          final next = append
              ? _mergeItems(_catalog, parsed.items)
              : parsed.items;
          _catalog = next;
          _catalogPage = parsed.page;
          _catalogHasMore = parsed.hasMore;
          _catalogQuery = queryAtStart;
          _catalogIndustry = industryAtStart;
        case ExploreSearchTab.business:
          final next = append
              ? _mergeBusinesses(_businesses, parsed.businesses)
              : parsed.businesses;
          _businesses = next;
          _businessPage = parsed.page;
          _businessHasMore = parsed.hasMore;
          _businessQuery = queryAtStart;
          _businessIndustry = industryAtStart;
      }
      _loading = false;
      _loadingMore = false;
    });
  }

  List<ExploreItem> _mergeItems(
    List<ExploreItem> current,
    List<ExploreItem> incoming,
  ) {
    final seen = current.map((e) => e.id).toSet();
    final merged = List<ExploreItem>.from(current);
    for (final item in incoming) {
      if (seen.add(item.id)) merged.add(item);
    }
    return merged;
  }

  List<ExploreBusiness> _mergeBusinesses(
    List<ExploreBusiness> current,
    List<ExploreBusiness> incoming,
  ) {
    final seen = current.map((e) => e.id).toSet();
    final merged = List<ExploreBusiness>.from(current);
    for (final biz in incoming) {
      if (seen.add(biz.id)) merged.add(biz);
    }
    return merged;
  }

  Future<void> _onTabSelected(ExploreSearchTab tab) async {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    final loadedQuery = switch (tab) {
      ExploreSearchTab.items => _itemsQuery,
      ExploreSearchTab.services => _servicesQuery,
      ExploreSearchTab.catalog => _catalogQuery,
      ExploreSearchTab.business => _businessQuery,
    };
    final loadedIndustry = switch (tab) {
      ExploreSearchTab.items => _itemsIndustry,
      ExploreSearchTab.services => _servicesIndustry,
      ExploreSearchTab.catalog => _catalogIndustry,
      ExploreSearchTab.business => _businessIndustry,
    };
    final page = switch (tab) {
      ExploreSearchTab.items => _itemsPage,
      ExploreSearchTab.services => _servicesPage,
      ExploreSearchTab.catalog => _catalogPage,
      ExploreSearchTab.business => _businessPage,
    };
    if (page == 0 ||
        loadedQuery != _activeQuery ||
        loadedIndustry != _industry) {
      await _refreshCurrentTab(reset: true);
    }
  }

  void _clearIndustryFilter() {
    if (_industry == null) return;
    setState(() => _industry = null);
    _resetAllTabCaches();
    _refreshCurrentTab(reset: true);
  }

  void _resetAllTabCaches() {
    _items = [];
    _services = [];
    _catalog = [];
    _businesses = [];
    _itemsPage = 0;
    _servicesPage = 0;
    _catalogPage = 0;
    _businessPage = 0;
    _itemsHasMore = true;
    _servicesHasMore = true;
    _catalogHasMore = true;
    _businessHasMore = true;
    _itemsQuery = '';
    _servicesQuery = '';
    _catalogQuery = '';
    _businessQuery = '';
    _itemsIndustry = null;
    _servicesIndustry = null;
    _catalogIndustry = null;
    _businessIndustry = null;
  }

  Future<void> _openFilterSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var draftTab = _tab;
    var draftIndustry = _industry;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
            final primary =
                isDark ? Colors.white : const Color(0xFF111827);
            final secondary =
                isDark ? const Color(0xFFB0B3B8) : WaUi.secondaryText;
            final chipBg =
                isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF0F2F5);
            final selectedBg =
                isDark ? Colors.white : const Color(0xFF18181B);
            final selectedFg = isDark ? Colors.black : Colors.white;

            Widget sectionTitle(String text) => Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                );

            Widget choiceChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : chipBg,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? selectedFg : primary,
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: secondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                draftTab = ExploreSearchTab.items;
                                draftIndustry = null;
                              });
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        children: [
                          sectionTitle('Type'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in [
                                (ExploreSearchTab.items, 'Items'),
                                (ExploreSearchTab.services, 'Services'),
                                (ExploreSearchTab.catalog, 'Catalog'),
                                (ExploreSearchTab.business, 'Business'),
                              ])
                                choiceChip(
                                  label: entry.$2,
                                  selected: draftTab == entry.$1,
                                  onTap: () => setSheetState(
                                    () => draftTab = entry.$1,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          sectionTitle('Category'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              choiceChip(
                                label: 'All',
                                selected: draftIndustry == null,
                                onTap: () =>
                                    setSheetState(() => draftIndustry = null),
                              ),
                              for (final cat in _categoryOptions)
                                choiceChip(
                                  label: businessCategoryLabel(context, cat),
                                  selected: draftIndustry == cat,
                                  onTap: () => setSheetState(
                                    () => draftIndustry = cat,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10A375),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Apply filters',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied != true || !mounted) return;

    final tabChanged = draftTab != _tab;
    final industryChanged = draftIndustry != _industry;
    if (!tabChanged && !industryChanged) return;

    setState(() {
      _tab = draftTab;
      _industry = draftIndustry;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _resetAllTabCaches();
    await _refreshCurrentTab(reset: true);
  }

  bool get _hasActiveFilters =>
      _industry != null && _industry!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffold = theme.scaffoldBackgroundColor;
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : WaUi.secondaryText;
    final searchBg = isDark ? const Color(0xFF3A3B3C) : WaUi.searchBg;
    final hintColor = isDark ? const Color(0xFF8A8D91) : const Color(0xFF667781);
    final accent = isDark ? AppTheme.secondaryWhite : AppTheme.primaryBlack;
    final chipBg = isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF0F2F5);
    final chipSelectedBg = isDark ? Colors.white : const Color(0xFF18181B);
    final chipSelectedFg = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        autofocus: widget.autofocus,
                        style: WaUi.body.copyWith(
                          fontSize: 16,
                          height: 1.2,
                          color: primaryText,
                        ),
                        cursorColor: accent,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          _debounce?.cancel();
                          final next = _searchController.text.trim();
                          _activeQuery = next;
                          _refreshCurrentTab(reset: true);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: searchBg,
                          hintText: 'Search items, services, catalog...',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: hintColor,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 6),
                            child: Icon(
                              Icons.search,
                              size: 22,
                              color: hintColor,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 42,
                            minHeight: 44,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  color: hintColor,
                                  onPressed: () {
                                    _searchController.clear();
                                    _activeQuery = '';
                                    _searchFocus.requestFocus();
                                    _refreshCurrentTab(reset: true);
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Filters',
                    onPressed: _openFilterSheet,
                    icon: Badge(
                      isLabelVisible: _hasActiveFilters,
                      smallSize: 8,
                      backgroundColor: const Color(0xFF10A375),
                      child: Icon(
                        Icons.tune_rounded,
                        color: primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_industry != null && _industry!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: Icon(
                      Icons.category_rounded,
                      size: 16,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
                    label: Text(
                      businessCategoryLabel(context, _industry!),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                    ),
                    onDeleted: _clearIndustryFilter,
                    deleteIconColor:
                        isDark ? Colors.white70 : const Color(0xFF667781),
                    backgroundColor: chipBg,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            // Quick type tabs — same filters as sheet "Type"
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in [
                    (ExploreSearchTab.items, 'Items'),
                    (ExploreSearchTab.services, 'Services'),
                    (ExploreSearchTab.catalog, 'Catalog'),
                    (ExploreSearchTab.business, 'Business'),
                  ]) ...[
                    _TabChip(
                      label: entry.$2,
                      count: _countFor(entry.$1),
                      selected: _tab == entry.$1,
                      bg: chipBg,
                      selectedBg: chipSelectedBg,
                      selectedFg: chipSelectedFg,
                      unselectedFg: primaryText,
                      onTap: () => _onTabSelected(entry.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading && _countFor(_tab) == 0
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabBody(
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody({
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    switch (_tab) {
      case ExploreSearchTab.items:
        return _ProductGrid(
          controller: _scrollController,
          items: _items,
          isDark: isDark,
          emptyTitle:
              _activeQuery.isEmpty ? 'No items nearby' : 'No items found',
          emptySubtitle: _activeQuery.isEmpty
              ? 'Menu items from nearby businesses will appear here.'
              : 'Try a different search.',
          primaryText: primaryText,
          secondaryText: secondaryText,
          badgeLabel: 'Shop Product',
          loadingMore: _loadingMore,
        );
      case ExploreSearchTab.services:
        return _ProductGrid(
          controller: _scrollController,
          items: _services,
          isDark: isDark,
          emptyTitle: _activeQuery.isEmpty
              ? 'No services nearby'
              : 'No services found',
          emptySubtitle: _activeQuery.isEmpty
              ? 'Services from nearby businesses will appear here.'
              : 'Try a different search.',
          primaryText: primaryText,
          secondaryText: secondaryText,
          badgeLabel: 'Service',
          loadingMore: _loadingMore,
        );
      case ExploreSearchTab.catalog:
        return _ProductGrid(
          controller: _scrollController,
          items: _catalog,
          isDark: isDark,
          emptyTitle: _activeQuery.isEmpty
              ? 'No catalog products'
              : 'No products found',
          emptySubtitle: _activeQuery.isEmpty
              ? 'Catalog products from nearby businesses will appear here.'
              : 'Try a different search.',
          primaryText: primaryText,
          secondaryText: secondaryText,
          badgeLabel: 'Shop Product',
          loadingMore: _loadingMore,
        );
      case ExploreSearchTab.business:
        return _BusinessList(
          controller: _scrollController,
          businesses: _businesses,
          isDark: isDark,
          emptyTitle: _activeQuery.isEmpty
              ? 'No businesses nearby'
              : 'No businesses found',
          emptySubtitle: _activeQuery.isEmpty
              ? 'Nearby businesses will appear here.'
              : 'Try a different name or category.',
          primaryText: primaryText,
          secondaryText: secondaryText,
          loadingMore: _loadingMore,
        );
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color bg;
  final Color selectedBg;
  final Color selectedFg;
  final Color unselectedFg;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.bg,
    required this.selectedBg,
    required this.selectedFg,
    required this.unselectedFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedBg : bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? selectedFg : unselectedFg,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? selectedFg.withValues(alpha: 0.7)
                      : unselectedFg.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primaryText;
  final Color secondaryText;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      children: [
        Icon(
          Icons.search_off,
          size: 40,
          color: secondaryText.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: WaUi.title.copyWith(color: primaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: WaUi.caption.copyWith(color: secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final ScrollController controller;
  final List<ExploreItem> items;
  final bool isDark;
  final String emptyTitle;
  final String emptySubtitle;
  final Color primaryText;
  final Color secondaryText;
  final String badgeLabel;
  final bool loadingMore;

  const _ProductGrid({
    required this.controller,
    required this.items,
    required this.isDark,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.primaryText,
    required this.secondaryText,
    required this.badgeLabel,
    required this.loadingMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        primaryText: primaryText,
        secondaryText: secondaryText,
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final cardW = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items.map((item) {
                return SizedBox(
                  width: cardW,
                  child: ShopProductCard(
                    title: item.name,
                    imageUrl: item.image,
                    category: item.category,
                    sellerName: item.businessName,
                    price: item.price,
                    avgRating: item.avgRating,
                    badgeLabel: badgeLabel,
                    isDark: isDark,
                    onTap: () =>
                        ExploreActions.openCatalogItem(context, item),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (loadingMore) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ],
      ],
    );
  }
}

class _BusinessList extends StatelessWidget {
  final ScrollController controller;
  final List<ExploreBusiness> businesses;
  final bool isDark;
  final String emptyTitle;
  final String emptySubtitle;
  final Color primaryText;
  final Color secondaryText;
  final bool loadingMore;

  const _BusinessList({
    required this.controller,
    required this.businesses,
    required this.isDark,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.primaryText,
    required this.secondaryText,
    required this.loadingMore,
  });

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        primaryText: primaryText,
        secondaryText: secondaryText,
      );
    }

    final surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE8E8E8);
    final imageBg = isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF4F4F5);

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: businesses.length + (loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= businesses.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        }

        final biz = businesses[index];
        final category = biz.businessCategory.isEmpty
            ? ''
            : businessCategoryLabel(context, biz.businessCategory);
        final photo = biz.coverPhoto?.isNotEmpty == true
            ? biz.coverPhoto
            : biz.profilePhoto;

        return Material(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (biz.username.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScannedProfileScreen(username: biz.username),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(19),
                    ),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: photo != null && photo.isNotEmpty
                          ? CachedAppImage(
                              url: photo,
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                              placeholder: ColoredBox(color: imageBg),
                              error: ColoredBox(
                                color: imageBg,
                                child: Icon(
                                  Icons.storefront_outlined,
                                  color: secondaryText,
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: imageBg,
                              child: Icon(
                                Icons.storefront_outlined,
                                color: secondaryText,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  biz.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: primaryText,
                                  ),
                                ),
                              ),
                              if (biz.distanceKm != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10A375)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${biz.distanceKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10A375),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (biz.reviewCount > 0) ...[
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${biz.avgRating.toStringAsFixed(1)} (${biz.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryText,
                                  ),
                                ),
                              ] else
                                Text(
                                  biz.city.isNotEmpty
                                      ? biz.city
                                      : 'Business nearby',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryText,
                                  ),
                                ),
                              const Spacer(),
                              Container(
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
      },
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/cart_line_item.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_item_options.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/service_schedule.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/catalog/catalog_item_form_screen.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/catalog_checkout.dart';
import 'package:tapni_app/utils/catalog_helper.dart'
    show CatalogHelper, catalogTypesMatch;
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';
import 'package:tapni_app/widgets/catalog_item_detail_sheet.dart';
import 'package:tapni_app/widgets/catalog_modifier_library_sheet.dart';
import 'package:tapni_app/widgets/catalog_product_card.dart';
import 'package:tapni_app/widgets/document_viewer.dart';
import 'package:tapni_app/widgets/service_detail_sheet.dart';
import 'package:tapni_app/widgets/stay_booking_sheet.dart';
import 'package:tapni_app/widgets/checkout_coupon_card.dart';
import 'package:tapni_app/widgets/checkout_points_redeem_card.dart';
import 'package:tapni_app/screens/catalog/service_booking_cart_screen.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';
import 'package:tapni_app/widgets/app_toast.dart';

/// Owner manage/add → full screen. Customer browse → bottom sheet.
Future<void> showMenuCatalogSheet({
  required BuildContext context,
  required String catalogLabel,
  required String catalogType,
  ProfileProvider? provider,
  SocialLink? existingLink,
  LinkTemplate? template,
  String? businessId,
  String? businessName,
  String? businessPhoto,
  String? businessUsername,
  String? currency,
  bool isCustomerView = false,
  bool embedded = false,
  String? initialItemName,
  VoidCallback? onSaved,
}) {
  final page = MenuCatalogSheet(
    catalogLabel: catalogLabel,
    catalogType: catalogType,
    provider: provider,
    existingLink: existingLink,
    template: template,
    businessId: businessId,
    businessName: businessName,
    businessPhoto: businessPhoto,
    businessUsername: businessUsername,
    currency: currency,
    isCustomerView: isCustomerView,
    embedded: embedded,
    initialItemName: initialItemName,
    onSaved: onSaved,
  );

  if (!isCustomerView) {
    return Navigator.of(context).push(
      AppPageRoute(builder: (_) => page),
    );
  }

  return showAppModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => page,
  );
}

class MenuCatalogSheet extends StatefulWidget {
  final String catalogLabel;
  final String catalogType;
  final ProfileProvider? provider;
  final SocialLink? existingLink;
  final LinkTemplate? template;
  final String? businessId;
  final String? businessName;
  final String? businessPhoto;
  final String? businessUsername;
  final String? currency;
  final bool isCustomerView;
  /// When true, render inside a parent scaffold (no back chrome / no Navigator.pop).
  final bool embedded;
  final String? initialItemName;
  final VoidCallback? onSaved;

  const MenuCatalogSheet({
    super.key,
    required this.catalogLabel,
    required this.catalogType,
    this.provider,
    this.existingLink,
    this.template,
    this.businessId,
    this.businessName,
    this.businessPhoto,
    this.businessUsername,
    this.currency,
    this.isCustomerView = false,
    this.embedded = false,
    this.initialItemName,
    this.onSaved,
  });

  @override
  State<MenuCatalogSheet> createState() => _MenuCatalogSheetState();
}

class _MenuCatalogSheetState extends State<MenuCatalogSheet> {
  late List<CatalogItem> _items;
  late List<String> _catalogCategories;
  late List<CatalogOptionGroup> _modifierGroups;
  late ServiceSchedule _serviceSchedule;
  final _newCategoryCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isOrdering = false;
  final List<CartLineItem> _cart = [];
  CheckoutPointsSelection _pointsSelection =
      CheckoutPointsSelection.none(0);
  CheckoutCouponSelection _couponSelection = CheckoutCouponSelection.none;
  String? _selectedCategory;
  final Set<String> _expandedCategories = {};
  /// null/empty = admin template default; otherwise custom icon (url or data-uri).
  String _customLogo = '';

  bool get _isServices => widget.catalogType == 'services';
  bool get _isProducts => widget.catalogType == 'products';
  bool get _isDocuments => widget.catalogType == 'documents';
  bool get _isMenu =>
      !_isDocuments &&
      !_isServices &&
      !_isProducts &&
      widget.catalogType != 'portfolio';
  bool _didOpenInitialItem = false;

  String get _templateLogo {
    final t = widget.template?.logo.trim() ?? '';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return '';
  }

  String get _displayLogo {
    if (_customLogo.trim().isNotEmpty) return _customLogo.trim();
    return _templateLogo;
  }

  String get _currency => resolveCurrency(
        currency: widget.currency ?? widget.provider?.profile.currency,
        country: widget.provider?.profile.country,
      );

  /// Prefer live profile link so modifiers survive provider rebuilds.
  SocialLink? _liveCatalogLink() {
    final links = widget.provider?.profile.socialLinks ?? const <SocialLink>[];
    final existingId = widget.existingLink?.id;
    if (existingId != null && existingId.isNotEmpty) {
      for (final l in links) {
        if (l.id == existingId) return l;
      }
    }
    for (final l in links) {
      if (l.isCatalogLink &&
          catalogTypesMatch(l.catalogType, widget.catalogType)) {
        return l;
      }
    }
    return widget.existingLink;
  }

  @override
  void initState() {
    super.initState();
    final link = _liveCatalogLink() ?? widget.existingLink;
    _items = link?.catalogItems?.toList() ?? [];
    _catalogCategories = List<String>.from(
      link?.catalogCategories ?? const [],
    );
    _modifierGroups = List<CatalogOptionGroup>.from(
      link?.catalogModifierGroups ?? const [],
    );
    if (_catalogCategories.isEmpty && _items.isNotEmpty) {
      _catalogCategories = CatalogHelper.orderedCategories(
        catalogCategories: [],
        items: _items,
      );
    }
    _serviceSchedule =
        widget.existingLink?.serviceSchedule ?? const ServiceSchedule();

    final existingLogo = widget.existingLink?.logoUrl?.trim() ?? '';
    final templateLogo = widget.template?.logo.trim() ?? '';
    // Treat template default as non-custom so admin icon updates still apply.
    if (existingLogo.isNotEmpty &&
        existingLogo != templateLogo &&
        !(templateLogo.isNotEmpty && existingLogo.endsWith(templateLogo))) {
      _customLogo = existingLogo;
    } else {
      _customLogo = '';
    }

    // Auto-expand the first category with items so the accordion isn't empty
    // on first open for the business owner.
    final grouped = CatalogHelper.groupByCategoryOrdered(
      items: _items,
      catalogCategories: _catalogCategories,
      activeOnly: false,
    );
    if (grouped.isNotEmpty) {
      _expandedCategories.add(grouped.keys.first);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final live = _liveCatalogLink();
      if (live?.catalogModifierGroups != null &&
          live!.catalogModifierGroups!.isNotEmpty) {
        setState(() {
          _modifierGroups =
              List<CatalogOptionGroup>.from(live.catalogModifierGroups!);
        });
      }
    });

    final initialName = widget.initialItemName?.trim();
    if (widget.isCustomerView &&
        initialName != null &&
        initialName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didOpenInitialItem) return;
        _didOpenInitialItem = true;
        final index = _items.indexWhere(
          (i) => i.isActive && i.name.trim() == initialName,
        );
        if (index >= 0) {
          _onCustomerItemTap(index, _items[index]);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MenuCatalogSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = _liveCatalogLink();
    final incoming = live?.catalogModifierGroups ??
        widget.existingLink?.catalogModifierGroups;
    if (incoming != null && incoming.isNotEmpty) {
      final same = incoming.length == _modifierGroups.length &&
          List.generate(incoming.length, (i) => incoming[i].id)
              .join() ==
          _modifierGroups.map((g) => g.id).join();
      if (!same) {
        _modifierGroups = List<CatalogOptionGroup>.from(incoming);
      }
    }
  }

  @override
  void dispose() {
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  String get _catalogLabel => widget.catalogLabel;

  List<String> get _categories => CatalogHelper.orderedCategories(
        catalogCategories: _catalogCategories,
        items: _items,
      );

  List<CatalogItem> get _filteredActiveItems {
    final active = _items.where((item) => item.isActive).toList();
    if (_selectedCategory == null) return active;
    return active.where((item) {
      return CatalogHelper.categoryOf(item) == _selectedCategory;
    }).toList();
  }

  int _cartQtyForIndex(int index) {
    return _cart
        .where((line) => line.itemIndex == index)
        .fold(0, (sum, line) => sum + line.quantity);
  }

  int get _cartItemCount =>
      _cart.fold<int>(0, (sum, line) => sum + line.quantity);

  double get _cartTotal => _cart.fold<double>(0, (sum, line) {
        final item = _items[line.itemIndex];
        return sum + item.displayPrice * line.quantity;
      });

  String get _manageTitle {
    switch (widget.catalogType) {
      case 'services':
        return 'Manage Services';
      case 'products':
        return 'Manage Products';
      case 'portfolio':
        return 'Manage Portfolio';
      case 'documents':
        return 'Manage Documents';
      default:
        return 'Manage $_catalogLabel';
    }
  }

  Widget _buildHeader({
    required String title,
    required Widget trailing,
    bool showBack = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (showBack)
              CircleBackButton(onTap: () => Navigator.pop(context))
            else
              const SizedBox(width: 40),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.toolsTitleOf(
                  size: 20,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _changeCatalogIcon() async {
    final file = await pickFile();
    if (file == null || !file.hasData) return;
    final encoded = await pickedToBase64(file);
    if (encoded.isEmpty || !mounted) return;
    setState(() => _customLogo = encoded);
    await _persistCatalog();
    if (!mounted) return;
    showAppToast(
          context,
          'Icon updated',
          kind: AppToastKind.success,
        );
  }

  Future<void> _resetCatalogIcon() async {
    setState(() => _customLogo = '');
    await _persistCatalog();
    if (!mounted) return;
    showAppToast(
          context,
          'Using default icon',
          kind: AppToastKind.info,
        );
  }

  Widget _logoPreview(String logo, {double size = 40}) {
    final placeholder = ColoredBox(
      color: const Color(0xFFF1F5F9),
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: size * 0.5,
        color: Colors.black54,
      ),
    );
    if (logo.isEmpty) return placeholder;
    if (logo.startsWith('data:image')) {
      try {
        final b64 = logo.split(',').last;
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    }
    return Image.network(
      logo,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _ownerIconTrailing() {
    return PopupMenuButton<String>(
      tooltip: 'Change icon',
      onSelected: (value) async {
        if (value == 'change') await _changeCatalogIcon();
        if (value == 'reset') await _resetCatalogIcon();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'change', child: Text('Change icon')),
        if (_customLogo.trim().isNotEmpty)
          const PopupMenuItem(value: 'reset', child: Text('Use default icon')),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: _logoPreview(_displayLogo),
        ),
      ),
    );
  }

  Widget _buildOwnerBody({bool showBack = true, bool showTitle = true}) {
    return Column(
      children: [
        if (showTitle) ...[
          const SizedBox(height: 8),
          _buildHeader(
            title: _manageTitle,
            trailing: widget.provider != null
                ? _ownerIconTrailing()
                : const SizedBox(width: 40),
            showBack: showBack,
          ),
          const SizedBox(height: 8),
        ],
        Expanded(child: _buildBusinessView(null)),
        SafeArea(top: false, child: _buildBusinessBottomBar()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Embedded inside Business Presence Menu tab.
    if (widget.embedded && !widget.isCustomerView) {
      return ColoredBox(
        color: Colors.white,
        child: _buildOwnerBody(showBack: false, showTitle: false),
      );
    }

    // Owner manage / add → full screen (menu, services, products, portfolio).
    if (!widget.isCustomerView) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _buildOwnerBody(showBack: true, showTitle: true),
        ),
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = _isServices
        ? 'Services'
        : (widget.businessName ?? _catalogLabel);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(BarqodyChrome.sheetRadius),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const SheetDragHandle(),
                const SizedBox(height: 14),
                _buildHeader(
                  title: title,
                  trailing: (!_isDocuments &&
                          widget.catalogType != 'portfolio')
                      ? _CartBagIndicator(count: _cartItemCount)
                      : const SizedBox(width: 40),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildCustomerView(scrollController)),
                if (!_isDocuments && widget.catalogType != 'portfolio')
                  SafeArea(
                    top: false,
                    child: _isServices
                        ? (_cart.isNotEmpty
                            ? _buildServiceContinueBar()
                            : const SizedBox.shrink())
                        : _buildOrderBar(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Business — Manage Menu
  // ---------------------------------------------------------------------

  String get _ownerIntroCopy {
    switch (widget.catalogType) {
      case 'services':
        return 'Organize sections and services customers can book.';
      case 'products':
        return 'Organize sections and products customers can browse.';
      case 'portfolio':
        return 'Organize sections and work you want to showcase.';
      case 'documents':
        return 'Add files customers can open from your profile.';
      default:
        return 'Organize sections and items customers see on your menu.';
    }
  }

  String get _addItemLabel {
    switch (widget.catalogType) {
      case 'services':
        return 'Add service';
      case 'products':
        return 'Add product';
      case 'portfolio':
        return 'Add portfolio item';
      case 'documents':
        return context.l10n.addDocument;
      default:
        return 'Add item';
    }
  }

  Widget _sectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: WaUi.toolsTitleOf(
                size: 16,
                weight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildModifiersSummaryCard() {
    final count = _modifierGroups.length;
    final preview = _modifierGroups.take(4).map((g) => g.name).join(' · ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openModifierLibrary,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                child: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 0
                          ? 'No modifiers yet'
                          : '$count modifier${count == 1 ? '' : 's'}',
                      style: WaUi.toolsTitleOf(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      count == 0
                          ? 'Add toppings, sizes, sauces, and more'
                          : preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.body.copyWith(
                        fontSize: 12.5,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
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

  Widget _buildBusinessView(ScrollController? scrollController) {
    final grouped = CatalogHelper.groupByCategoryOrdered(
      items: _items,
      catalogCategories: _catalogCategories,
      activeOnly: false,
    );
    final categoryKeys = grouped.keys.toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      children: [
        Text(
          _ownerIntroCopy,
          style: WaUi.body.copyWith(
            fontSize: 13.5,
            height: 1.4,
            color: BarqodyChrome.bodyText,
          ),
        ),
        if (_isMenu || _isProducts) ...[
          const SizedBox(height: 18),
          _sectionHeader(
            title: 'Modifiers',
            actionLabel: 'Edit',
            onAction: _openModifierLibrary,
          ),
          _buildModifiersSummaryCard(),
        ],
        const SizedBox(height: 20),
        if (!_isDocuments)
          _sectionHeader(
            title: 'Sections',
            actionLabel: 'Edit',
            onAction: _openCategoryManagerSheet,
          ),
        if (_items.isEmpty && categoryKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                Icon(
                  _isDocuments
                      ? Icons.folder_open_outlined
                      : Icons.inventory_2_outlined,
                  size: 48,
                  color: BarqodyChrome.secondaryText.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  _isDocuments
                      ? context.l10n.noDocumentsYet
                      : 'No items yet',
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isDocuments
                      ? 'Add your first document to get started.'
                      : 'Create a section, then add your first item.',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: 13.5,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
              ],
            ),
          )
        else if (_isDocuments)
          ...List.generate(_items.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BarqodyChrome.divider),
              ),
              child: _businessItemTile(index),
            );
          })
        else if (categoryKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'No sections yet. Tap Edit to add one.',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
            ),
          )
        else
          ...categoryKeys.map(
            (category) =>
                _categoryAccordionCard(category, grouped[category]!),
          ),
        if (_isServices) ...[
          const SizedBox(height: 12),
          _buildServiceScheduleSettings(),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _sectionCountPill(int count) {
    final label = count == 0
        ? 'No items yet'
        : '$count item${count == 1 ? '' : 's'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: WaUi.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: BarqodyChrome.secondaryText,
        ),
      ),
    );
  }

  Widget _sectionLeading(String category) {
    final letter = category.trim().isEmpty
        ? '#'
        : category.trim().characters.first.toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: WaUi.toolsTitleOf(
          size: 15,
          weight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _categoryAccordionCard(String category, List<CatalogItem> items) {
    final expanded = _expandedCategories.contains(category);

    Widget header({required bool isExpanded}) {
      return InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCategories.remove(category);
            } else {
              _expandedCategories.add(category);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              _sectionLeading(category),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.toolsTitleOf(
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sectionCountPill(items.length),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.chevron_right_rounded,
                color: BarqodyChrome.secondaryText,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BarqodyChrome.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: expanded
          ? Column(
              children: [
                header(isExpanded: true),
                Divider(height: 1, thickness: 1, color: BarqodyChrome.divider),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No items in this section yet.',
                        style: WaUi.body.copyWith(
                          fontSize: 13,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    ),
                  )
                else ...[
                  for (var i = 0; i < items.length; i++) ...[
                    _businessItemTile(_items.indexOf(items[i])),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: BarqodyChrome.divider.withValues(alpha: 0.7),
                      ),
                  ],
                  const SizedBox(height: 6),
                ],
              ],
            )
          : header(isExpanded: false),
    );
  }

  Widget _businessItemTile(int index) {
    final item = _items[index];
    final subtitle = _isDocuments
        ? (item.description.isNotEmpty
            ? item.description
            : context.l10n.viewDocument)
        : (item.hasConfiguration
            ? (item.startingPrice > 0
                ? 'From ${formatMoney(item.startingPrice, currency: _currency)}'
                : 'From Free')
            : (item.displayPrice > 0
                ? formatMoney(item.displayPrice, currency: _currency)
                : 'Free'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _itemImage(item, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.toolsTitleOf(
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: _isDocuments ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    fontWeight:
                        _isDocuments ? FontWeight.w400 : FontWeight.w600,
                    color: _isDocuments
                        ? BarqodyChrome.secondaryText
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _circleIconButton(
            icon: Image.asset(
              'assets/images/png/edit-icon-1.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.black),
            ),
            onTap: () => _editItem(index),
          ),
          const SizedBox(width: 8),
          _circleIconButton(
            icon: Image.asset(
              'assets/images/png/trash-bin-icon.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.white,
              ),
            ),
            bg: const Color(0xFFE53935),
            borderColor: const Color(0xFFE53935),
            onTap: () async {
              setState(() => _items.removeAt(index));
              await _persistCatalog();
            },
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required Widget icon,
    required VoidCallback onTap,
    Color bg = Colors.white,
    Color borderColor = const Color(0xFFE3E3E8),
  }) {
    return Material(
      color: bg,
      shape: CircleBorder(side: BorderSide(color: borderColor)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 34, height: 34, child: Center(child: icon)),
      ),
    );
  }

  Widget _buildBusinessBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8E8E8), width: 1),
        ),
      ),
      child: PillButton(
        label: _addItemLabel,
        onPressed: _addItem,
      ),
    );
  }

  Future<void> _openModifierLibrary() async {
    final updated = await showCatalogModifierLibrarySheet(
      context: context,
      groups: _modifierGroups,
    );
    if (updated == null || !mounted) return;
    // Keep local copy immediately so UI never goes blank after Done.
    setState(() => _modifierGroups = updated);
    await _saveCatalogLink(quiet: false);
    if (!mounted) return;
    final live = _liveCatalogLink();
    final remoteGroups = live?.catalogModifierGroups;
    if (remoteGroups != null && remoteGroups.isNotEmpty) {
      setState(() {
        _modifierGroups = List<CatalogOptionGroup>.from(remoteGroups);
      });
    }
    if (mounted) {
      showAppToast(
        context,
        _modifierGroups.isEmpty
            ? 'No modifier groups saved'
            : '${_modifierGroups.length} modifier group${_modifierGroups.length == 1 ? '' : 's'} ready',
        kind: _modifierGroups.isEmpty
            ? AppToastKind.warning
            : AppToastKind.success,
      );
    }
  }

  Widget _capsLabel(String text) {
    return Text(
      text,
      style: WaUi.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: BarqodyChrome.secondaryText,
      ),
    );
  }

  Future<void> _openCategoryManagerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(BarqodyChrome.modalRadius),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: 'Website Sections',
                    showHandle: true,
                    onBack: () => Navigator.pop(ctx),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  Text(
                    _isProducts
                        ? 'Sections organize products on your website. Marketplace categories are chosen per product and managed by BarQody admin.'
                        : 'Sections organize items on your website only.',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_catalogCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Add sections in display order (e.g. New Arrivals, Best Sellers).',
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(
                          fontSize: 13,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                      ),
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        buildDefaultDragHandles: false,
                        itemCount: _catalogCategories.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) newIndex -= 1;
                          await _moveCategory(oldIndex, newIndex);
                          setSheetState(() {});
                        },
                        itemBuilder: (ctx, index) {
                          final cat = _catalogCategories[index];
                          final count = _items
                              .where(
                                (i) =>
                                    CatalogHelper.categoryOf(i)
                                        .toLowerCase() ==
                                    cat.toLowerCase(),
                              )
                              .length;
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(cat),
                            index: index,
                            child: _sectionRow(
                              name: cat,
                              count: count,
                              onEdit: () async {
                                await _renameCategorySheet(index);
                                setSheetState(() {});
                              },
                              onDelete: () async {
                                await _removeCategory(index);
                                setSheetState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Add Section',
                    filled: false,
                    onPressed: () async {
                      await _openAddSectionSheet();
                      setSheetState(() {});
                    },
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _sectionRow({
    required String name,
    required int count,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.toolsTitleOf(
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count item${count == 1 ? '' : 's'}',
                  style: WaUi.body.copyWith(
                    fontSize: 12,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _circleIconButton(
            icon: Image.asset(
              'assets/images/png/edit-icon-1.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.black),
            ),
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _circleIconButton(
            icon: Image.asset(
              'assets/images/png/trash-bin-icon.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.white,
              ),
            ),
            bg: const Color(0xFFE53935),
            borderColor: const Color(0xFFE53935),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _openAddSectionSheet() async {
    _newCategoryCtrl.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BarqodyChrome.modalRadius),
            ),
          ),
          padding: const EdgeInsets.only(bottom: 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: 'Add Section',
                  onBack: () => Navigator.pop(ctx),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                _capsLabel('SECTION NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _newCategoryCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _addCategory();
                    Navigator.pop(ctx);
                  },
                  decoration: WaUi.fieldDecoration(
                    hintText: context.l10n.eGFastFood,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: context.l10n.cancel,
                        filled: false,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: context.l10n.save,
                        onPressed: () {
                          _addCategory();
                          Navigator.pop(ctx);
                        },
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
      ),
    );
  }

  Future<void> _renameCategorySheet(int index) async {
    final ctrl = TextEditingController(text: _catalogCategories[index]);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BarqodyChrome.modalRadius),
            ),
          ),
          padding: const EdgeInsets.only(bottom: 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: 'Rename Section',
                  onBack: () => Navigator.pop(ctx),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                _capsLabel('SECTION NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _renameCategory(index, ctrl.text);
                    Navigator.pop(ctx);
                  },
                  decoration: WaUi.fieldDecoration(
                    hintText: context.l10n.eGFastFood,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: context.l10n.cancel,
                        filled: false,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: context.l10n.save,
                        onPressed: () {
                          _renameCategory(index, ctrl.text);
                          Navigator.pop(ctx);
                        },
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
      ),
    );
  }

  Future<void> _addCategory() async {
    final name = _newCategoryCtrl.text.trim();
    if (name.isEmpty) return;
    final exists = _catalogCategories.any(
      (c) => c.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      showAppToast(
            context,
            context.l10n.categoryAlreadyExists,
            kind: AppToastKind.warning,
          );
      return;
    }
    setState(() {
      _catalogCategories.add(name);
      _newCategoryCtrl.clear();
    });
    await _persistCatalog();
  }

  Future<void> _removeCategory(int index) async {
    setState(() {
      final removed = _catalogCategories.removeAt(index);
      _expandedCategories.remove(removed);
    });
    await _persistCatalog();
  }

  Future<void> _moveCategory(int from, int to) async {
    setState(() {
      final item = _catalogCategories.removeAt(from);
      _catalogCategories.insert(to, item);
    });
    await _persistCatalog();
  }

  Future<void> _renameCategory(int index, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final oldName = _catalogCategories[index];
    if (trimmed.toLowerCase() == oldName.toLowerCase()) {
      setState(() => _catalogCategories[index] = trimmed);
      return;
    }
    final exists = _catalogCategories.any(
      (c) => c.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      showAppToast(
            context,
            context.l10n.categoryAlreadyExists,
            kind: AppToastKind.warning,
          );
      return;
    }
    setState(() {
      _catalogCategories[index] = trimmed;
      for (var i = 0; i < _items.length; i++) {
        if (CatalogHelper.categoryOf(_items[i]).toLowerCase() ==
            oldName.toLowerCase()) {
          _items[i] = _items[i].copyWith(category: trimmed);
        }
      }
      if (_expandedCategories.remove(oldName)) {
        _expandedCategories.add(trimmed);
      }
    });
    await _persistCatalog();
  }

  void _ensureCategoryOnList(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    final exists = _catalogCategories.any(
      (c) => c.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) {
      _catalogCategories.add(trimmed);
    }
  }

  Widget _buildServiceScheduleSettings() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.bookingSchedule,
            style: WaUi.toolsTitleOf(
              size: 15,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _scheduleField(
                  label: context.l10n.startHour,
                  value: _serviceSchedule.startHour,
                  onChanged: (v) => setState(
                    () => _serviceSchedule =
                        _serviceSchedule.copyWith(startHour: v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scheduleField(
                  label: context.l10n.endHour,
                  value: _serviceSchedule.endHour,
                  onChanged: (v) => setState(
                    () => _serviceSchedule =
                        _serviceSchedule.copyWith(endHour: v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scheduleField(
                  label: context.l10n.slotMin,
                  value: _serviceSchedule.slotMinutes,
                  onChanged: (v) => setState(
                    () => _serviceSchedule =
                        _serviceSchedule.copyWith(slotMinutes: v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Open days',
            style: WaUi.body.copyWith(
              fontSize: 12,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (day) {
              const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
              final selected = _serviceSchedule.workingDays.contains(day);
              return FilterChip(
                label: Text(labels[day]),
                selected: selected,
                onSelected: (on) {
                  setState(() {
                    final days = List<int>.from(_serviceSchedule.workingDays);
                    if (on) {
                      if (!days.contains(day)) days.add(day);
                    } else {
                      days.remove(day);
                    }
                    days.sort();
                    _serviceSchedule =
                        _serviceSchedule.copyWith(workingDays: days);
                  });
                },
                selectedColor: Colors.black,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? Colors.black : const Color(0xFFE0E0E0),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _scheduleField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: 12,
            color: BarqodyChrome.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            InkWell(
              onTap: () => onChanged(value > 1 ? value - 1 : 1),
              child: const Icon(Icons.remove_circle_outline, size: 20),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            InkWell(
              onTap: () => onChanged(value + 1),
              child: const Icon(Icons.add_circle_outline, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Customer view
  // ---------------------------------------------------------------------

  Widget _buildCustomerView(ScrollController scrollController) {
    if (_items.where((i) => i.isActive).isEmpty) {
      return Center(
        child: Text(
          _isDocuments
              ? context.l10n.noDocumentsAvailable
              : context.l10n.noCatalogItemsAvailable(_catalogLabel),
          style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
        ),
      );
    }

    if (_isDocuments) {
      final docs = _items.where((i) => i.isActive).toList();
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final item = docs[index];
          return _customerDocumentTile(item);
        },
      );
    }

    final sections = _selectedCategory == null
        ? CatalogHelper.groupByCategoryOrdered(
            items: _items,
            catalogCategories: _catalogCategories,
          )
        : {
            _selectedCategory!: _filteredActiveItems,
          };

    if (sections.isEmpty ||
        (_selectedCategory != null && _filteredActiveItems.isEmpty)) {
      return Center(
        child: Text(
          context.l10n.noItemsInThisCategory,
          style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
        ),
      );
    }

    // Flat 2-column grid so consecutive items sit side-by-side
    // (per-category grids left single items taking a full row).
    final flatItems = <CatalogItem>[
      for (final entry in sections.entries) ...entry.value,
    ];

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (_categories.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                children: [
                  _categoryChip(context.l10n.all, _selectedCategory == null, () {
                    setState(() => _selectedCategory = null);
                  }),
                  ..._categories.map(
                    (cat) => _categoryChip(cat, _selectedCategory == cat, () {
                      setState(() => _selectedCategory = cat);
                    }),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            _categories.length > 1 ? 12 : 4,
            16,
            16,
          ),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const crossAxisSpacing = 12.0;
              const mainAxisSpacing = 12.0;
              final cardW =
                  (constraints.crossAxisExtent -
                      crossAxisSpacing * (crossAxisCount - 1)) /
                  crossAxisCount;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisExtent: CatalogProductCard.heightForWidth(
                    cardW,
                    isService: _isServices,
                  ),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = flatItems[index];
                    final originalIndex = _items.indexOf(item);
                    return CatalogProductCard(
                      item: item,
                      isService: _isServices,
                      currency: _currency,
                      durationLabel:
                          _isServices ? item.durationLabel : null,
                      cartQty: _cartQtyForIndex(originalIndex),
                      onTap: () => _onCustomerItemTap(originalIndex, item),
                    );
                  },
                  childCount: flatItems.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _customerDocumentTile(CatalogItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: _itemImage(item),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: item.description.isNotEmpty
              ? Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(context.l10n.viewDocument),
          trailing: const Icon(
            Icons.chevron_right,
            color: BarqodyChrome.secondaryText,
          ),
          onTap: () => openCatalogDocument(context, item),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.black : BarqodyChrome.fieldFill,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : BarqodyChrome.secondaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCustomerItemTap(int index, CatalogItem item) async {
    if (_isDocuments) {
      await openCatalogDocument(context, item);
      return;
    }
    // Portfolio is browse-only — never enter cart / checkout.
    if (widget.catalogType == 'portfolio') {
      await showCatalogItemDetailSheet(
        context: context,
        item: item,
        currency: _currency,
        initialQty: 0,
        initialNotes: '',
        browseOnly: true,
      );
      return;
    }
    if (_isServices) {
      if (widget.businessId == null || widget.existingLink == null) return;
      final businessName = widget.businessName ?? 'business';
      final result = await showServiceDetailSheet(
        context: context,
        item: item,
        businessId: widget.businessId!,
        businessLinkId: widget.existingLink!.id,
        businessName: businessName,
        businessPhoto: widget.businessPhoto ??
            widget.provider?.profile.profilePhotoUrl,
        businessUsername: widget.businessUsername ??
            widget.provider?.profile.username,
        businessVerified: widget.provider?.profile.isPro == true,
        currency: _currency,
      );
      if (result == null || !mounted) return;
      _addServiceToCart(
        index: index,
        bookingDate: result.bookingDate,
        bookingTime: result.bookingTime,
        resourceId: result.resourceId,
        resourceName: result.resourceName,
      );
      if (result.bookNow && mounted) {
        await _openServiceCart();
      }
      return;
    }

    // Hotel rooms: products + bookable room resources → check-in / check-out sheet.
    if (_isProducts &&
        widget.businessId != null &&
        widget.existingLink != null &&
        await businessHasRoomResources(widget.businessId!)) {
      if (!mounted) return;
      final room = await findRoomResourceForItem(
        businessId: widget.businessId!,
        item: item,
      );
      final stay = await showStayBookingSheet(
        context: context,
        item: item,
        businessId: widget.businessId!,
        businessLinkId: widget.existingLink!.id,
        businessName: widget.businessName ?? 'business',
        currency: _currency,
        room: room,
      );
      if (stay == null || !mounted) return;
      if (stay.bookNow) {
        await _placeStayOrder(item: item, stay: stay);
      }
      return;
    }

    final existingIndex = _cart.indexWhere((line) => line.itemIndex == index);
    final existingLine = existingIndex != -1 ? _cart[existingIndex] : null;

    final result = await showCatalogItemDetailSheet(
      context: context,
      item: item,
      currency: _currency,
      initialQty: existingLine?.quantity ?? 0,
      initialNotes: existingLine?.notes ?? '',
    );

    if (result == null) return;

    setState(() {
      _cart.removeWhere((line) => line.itemIndex == index);
      if (result.quantity > 0) {
        _cart.add(CartLineItem(
          itemIndex: index,
          quantity: result.quantity,
          notes: result.notes,
        ));
      }
    });
  }

  void _addServiceToCart({
    required int index,
    required String bookingDate,
    required String bookingTime,
    String? resourceId,
    String? resourceName,
  }) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (line) =>
            line.itemIndex == index &&
            line.bookingDate == bookingDate &&
            line.bookingTime == bookingTime &&
            line.resourceId == resourceId,
      );
      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        _cart[existingIndex] =
            existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _cart.add(
          CartLineItem(
            itemIndex: index,
            quantity: 1,
            bookingDate: bookingDate,
            bookingTime: bookingTime,
            resourceId: resourceId,
            resourceName: resourceName,
          ),
        );
      }
    });
  }

  Future<void> _openServiceCart() async {
    if (widget.businessId == null || widget.existingLink == null) return;
    if (_cart.isEmpty) return;

    final updated = await Navigator.of(context).push<List<CartLineItem>>(
      AppPageRoute(
        builder: (_) => ServiceBookingCartScreen(
          catalogItems: _items,
          initialCart: List<CartLineItem>.from(_cart),
          businessId: widget.businessId!,
          businessLinkId: widget.existingLink!.id,
          businessName: widget.businessName ?? 'business',
          businessUsername: widget.provider?.profile.username ??
              widget.businessName,
          currency: _currency,
          customerUsername: null,
          onBookedSuccess: () {
            if (mounted) setState(() => _cart.clear());
          },
        ),
      ),
    );

    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _cart
          ..clear()
          ..addAll(updated);
      });
    }
  }

  Widget _buildServiceContinueBar() {
    final total = _cartTotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: BarqodyChrome.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Service',
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(total, currency: _currency),
                  style: WaUi.toolsTitleOf(
                    size: 20,
                    weight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 148,
            height: WaUi.primaryButtonHeight,
            child: ElevatedButton(
              onPressed: _openServiceCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Continue',
                style: WaUi.promoButton.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _checkoutItems => _cart.map((line) {
        final item = _items[line.itemIndex];
        return {
          'name': item.name,
          'price': item.displayPrice,
          'quantity': line.quantity,
          if (item.category.isNotEmpty) 'category': item.category,
          if (item.imageUrl.isNotEmpty) 'image': item.imageUrl,
          if (line.notes.isNotEmpty) 'notes': line.notes,
        };
      }).toList();

  Widget _buildOrderBar() {
    final total = _cartTotal;
    final itemCount = _cartItemCount;
    final afterCoupon = (total - _couponSelection.discountAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
    final payable = _pointsSelection.usePoints
        ? _pointsSelection.payableAmount
        : afterCoupon;
    final businessId = widget.businessId;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (businessId != null &&
              businessId.isNotEmpty &&
              itemCount > 0 &&
              widget.isCustomerView) ...[
            CheckoutCouponCard(
              businessId: businessId,
              subtotalAmount: total,
              currency: _currency,
              catalogType: widget.catalogType,
              items: _checkoutItems,
              pointsToRedeem: _pointsSelection.usePoints
                  ? _pointsSelection.pointsToRedeem
                  : 0,
              onChanged: (sel) {
                if (!mounted) return;
                setState(() => _couponSelection = sel);
              },
            ),
            CheckoutPointsRedeemCard(
              businessId: businessId,
              subtotalAmount: afterCoupon,
              currency: _currency,
              onChanged: (sel) {
                if (!mounted) return;
                setState(() => _pointsSelection = sel);
              },
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.placeOrder,
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    if (widget.isCustomerView) ...[
                      Builder(
                        builder: (ctx) {
                          String who = '';
                          try {
                            who = Provider.of<ProfileProvider>(ctx,
                                    listen: false)
                                .profile
                                .name
                                .trim();
                          } catch (_) {}
                          if (who.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Ordering as $who',
                              style: WaUi.body.copyWith(
                                fontSize: 11,
                                color: BarqodyChrome.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(payable, currency: _currency),
                      style: WaUi.toolsTitleOf(
                        size: 20,
                        weight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (_couponSelection.applied &&
                        _couponSelection.discountAmount > 0)
                      Text(
                        'Coupon −${formatMoney(_couponSelection.discountAmount, currency: _currency)}',
                        style: WaUi.body.copyWith(
                          fontSize: 11,
                          color: BarqodyChrome.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (_pointsSelection.usePoints &&
                        _pointsSelection.discountAmount > 0)
                      Text(
                        'Includes ${_pointsSelection.pointsToRedeem} pts off',
                        style: WaUi.body.copyWith(
                          fontSize: 11,
                          color: BarqodyChrome.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 156,
                height: WaUi.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: itemCount == 0 ||
                          _isOrdering ||
                          !_pointsSelection.valid ||
                          !_couponSelection.valid
                      ? null
                      : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor:
                        Colors.black.withValues(alpha: 0.35),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                  child: _isOrdering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------

  Future<void> _addItem() async {
    // Full-screen add (menu / service / product / portfolio).
    if (!widget.isCustomerView) {
      final ok = await ensureBusinessProfileComplete(context);
      if (!ok || !mounted) return;
    }
    if (!_isDocuments && _catalogCategories.isEmpty) {
      showAppToast(
            context,
            'Add at least one section before adding products.',
            kind: AppToastKind.info,
          );
      return;
    }
    final result = await Navigator.push<CatalogItem>(
      context,
      AppPageRoute(
        builder: (_) => CatalogItemFormScreen(
          catalogLabel: _catalogLabel,
          existingCategories: _catalogCategories,
          requireCategory: !_isDocuments,
          isDocument: _isDocuments,
          isService: _isServices,
          isPortfolio: widget.catalogType == 'portfolio',
          isProduct: _isProducts,
          modifierLibrary:
              (_isMenu || _isProducts) ? _modifierGroups : const [],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _ensureCategoryOnList(result.category);
        _items.add(result);
        final cat = CatalogHelper.categoryOf(result);
        _expandedCategories.add(cat);
      });
      await _persistCatalog();
    }
  }

  Future<void> _editItem(int index) async {
    final result = await Navigator.push<CatalogItem>(
      context,
      AppPageRoute(
        builder: (_) => CatalogItemFormScreen(
          catalogLabel: _catalogLabel,
          existingItem: _items[index],
          existingCategories: _catalogCategories,
          requireCategory: !_isDocuments && _catalogCategories.isNotEmpty,
          isDocument: _isDocuments,
          isService: _isServices,
          isPortfolio: widget.catalogType == 'portfolio',
          isProduct: _isProducts,
          modifierLibrary:
              (_isMenu || _isProducts) ? _modifierGroups : const [],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _ensureCategoryOnList(result.category);
        _items[index] = result;
      });
      await _persistCatalog();
    }
  }

  Widget _itemImage(CatalogItem item, {double size = 64}) {
    final image = item.imageUrl.trim();
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _isDocuments
            ? (DocumentFileHelper.isPdf(image)
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined)
            : Icons.fastfood_outlined,
        color: BarqodyChrome.secondaryText,
        size: 28,
      ),
    );

    if (image.isEmpty) return placeholder;

    final looksLikeImage = DocumentFileHelper.isImage(image) ||
        image.startsWith('data:image/') ||
        (image.length > 100 && !image.contains('/') && !image.startsWith('http'));
    if (!looksLikeImage && _isDocuments) return placeholder;

    if (image.startsWith('data:image/')) {
      final comma = image.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(image.substring(comma + 1));
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          );
        } catch (_) {
          return placeholder;
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedAppImage(
        url: image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
        error: placeholder,
      ),
    );
  }

  /// Save without leaving the screen (used after add / edit / delete).
  /// Sections-only catalogs must persist so Add Section survives reopen.
  Future<void> _persistCatalog() async {
    if (widget.provider == null || _isSaving) return;
    final hasSections = _catalogCategories.any((c) => c.trim().isNotEmpty);
    if (_items.isEmpty && widget.existingLink == null && !hasSections) {
      return;
    }
    await _saveCatalogLink(quiet: true);
  }

  Future<void> _saveCatalogLink({bool quiet = false}) async {
    if (widget.provider == null) return;
    final hasSections = _catalogCategories.any((c) => c.trim().isNotEmpty);
    if (_items.isEmpty && widget.existingLink == null && !hasSections) {
      if (!quiet && mounted) {
        showAppToast(
              context,
              'Add a section or at least one $_catalogLabel item to save.',
              kind: AppToastKind.info,
            );
      }
      return;
    }

    setState(() => _isSaving = true);

    final savedCategories = CatalogHelper.orderedCategories(
      catalogCategories: _catalogCategories,
      items: _items,
    );

    final label = widget.template?.label ?? _catalogLabel;
    final templateId = widget.template?.id ?? widget.existingLink?.templateId;
    // Empty = admin default template icon (resolved on API read).
    final logoUrl = _customLogo.trim();
    final isPublic = widget.existingLink?.isPublic ?? true;
    final link = widget.existingLink != null
        ? widget.existingLink!.copyWith(
            customLabel: label,
            fieldType: 'menu_catalog',
            actionType: 'menu_catalog',
            templateId: templateId,
            logoUrl: logoUrl,
            catalogItems: _items,
            catalogCategories: savedCategories,
            catalogModifierGroups:
                (_isMenu || _isProducts) ? _modifierGroups : const [],
            catalogType: widget.catalogType,
            serviceSchedule: _isServices ? _serviceSchedule : null,
            value: widget.existingLink!.id,
            isPublic: isPublic,
          )
        : SocialLink(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            platform: SocialPlatform.spoonFork,
            templateId: templateId,
            customLabel: label,
            fieldType: 'menu_catalog',
            actionType: 'menu_catalog',
            logoUrl: logoUrl,
            catalogItems: _items,
            catalogCategories: savedCategories,
            catalogModifierGroups:
                (_isMenu || _isProducts) ? _modifierGroups : const [],
            catalogType: widget.catalogType,
            serviceSchedule: _isServices ? _serviceSchedule : null,
            value: 'catalog',
            isActive: true,
            isPublic: isPublic,
          );

    final updatedLinks =
        List<SocialLink>.from(widget.provider!.profile.socialLinks);

    int idx = -1;
    if (widget.existingLink != null) {
      idx = updatedLinks.indexWhere((l) => l.id == widget.existingLink!.id);
    }
    // Upsert by catalog type so we never create a second Menu/Services tile.
    if (idx == -1) {
      idx = updatedLinks.indexWhere(
        (l) =>
            l.isCatalogLink &&
            catalogTypesMatch(l.catalogType, widget.catalogType),
      );
    }

    if (idx != -1) {
      final prev = updatedLinks[idx];
      updatedLinks[idx] = link.copyWith(id: prev.id);
      // Drop any extra catalog tiles of the same type.
      for (var i = updatedLinks.length - 1; i >= 0; i--) {
        if (i == idx) continue;
        final other = updatedLinks[i];
        if (other.isCatalogLink &&
            catalogTypesMatch(other.catalogType, widget.catalogType)) {
          updatedLinks.removeAt(i);
        }
      }
    } else {
      updatedLinks.add(link);
    }

    final res = await widget.provider!.updateLinks(
      links: updatedLinks,
      context: context,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not save menu. Please try again.',
            kind: AppToastKind.error,
          );
      return;
    }
    widget.onSaved?.call();
    // Re-hydrate from live profile so Mongo size ids / prices stick in UI.
    if (mounted) {
      final live = _liveCatalogLink();
      final liveItems = live?.catalogItems;
      if (liveItems != null && liveItems.isNotEmpty) {
        setState(() {
          _items = List<CatalogItem>.from(liveItems);
          if (live?.catalogModifierGroups != null) {
            _modifierGroups =
                List<CatalogOptionGroup>.from(live!.catalogModifierGroups!);
          }
        });
      }
    }
    // Stay on screen — top save button is gone; changes auto-persist.
    if (!quiet && !widget.embedded && mounted) {
      showAppToast(
            context,
            '$_catalogLabel saved',
            kind: AppToastKind.success,
          );
    }
  }

  Future<void> _placeStayOrder({
    required CatalogItem item,
    required StayBookingResult stay,
  }) async {
    if (widget.businessId == null || widget.existingLink == null) return;

    String customerName = '';
    String? customerUsername;
    try {
      final profile =
          Provider.of<ProfileProvider>(context, listen: false).profile;
      customerUsername = profile.username;
      customerName = profile.name;
    } catch (_) {}

    setState(() => _isOrdering = true);
    await CatalogCheckout.placeWithPayment(
      context: context,
      totalAmount: item.displayPrice * stay.nights,
      currency: _currency,
      customerName: customerName,
      customerUsername: customerUsername,
      businessName: widget.businessName,
      businessUsername: widget.businessUsername,
      totalItems: 1,
      bookingKind: 'stay',
      placeOrder: ({
        required String paymentMethod,
        required String idempotencyKey,
      }) {
        return CatalogRepo().placeOrder(
          businessId: widget.businessId!,
          businessLinkId: widget.existingLink!.id,
          catalogType: 'products',
          bookingKind: 'stay',
          resourceId: stay.resourceId,
          checkInDate: stay.checkInDate,
          checkOutDate: stay.checkOutDate,
          paymentMethod: paymentMethod,
          idempotencyKey: idempotencyKey,
          items: [
            {
              'name': item.name,
              'price': item.displayPrice,
              'quantity': 1,
              if (item.imageUrl.isNotEmpty) 'image': item.imageUrl,
              'notes': '${stay.nights} night(s) · ${stay.resourceName}',
            },
          ],
        );
      },
    );
    if (!mounted) return;
    setState(() => _isOrdering = false);
  }

  Future<({String orderType, String address})?> _chooseFulfillment() async {
    // Restaurant/menu: pickup (takeaway) or delivery only.
    if (widget.catalogType != 'menu' && widget.catalogType != 'catalog') {
      return (orderType: 'takeaway', address: '');
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetDragHandle(),
                const SizedBox(height: 12),
                Text(
                  'How do you want your order?',
                  style: WaUi.toolsTitleOf(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Pickup'),
                  subtitle: const Text('Collect at the restaurant'),
                  onTap: () => Navigator.pop(ctx, 'takeaway'),
                ),
                ListTile(
                  leading: const Icon(Icons.delivery_dining_outlined),
                  title: const Text('Delivery'),
                  subtitle: const Text('Deliver to an address'),
                  onTap: () => Navigator.pop(ctx, 'delivery'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return null;
    if (choice != 'delivery') {
      return (orderType: 'takeaway', address: '');
    }
    final controller = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delivery address'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Street, area, city',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    if (address == null || address.isEmpty) return null;
    return (orderType: 'delivery', address: address);
  }

  Future<void> _placeOrder() async {
    if (widget.businessId == null || widget.existingLink == null) return;
    if (widget.catalogType == 'portfolio') return;

    final fulfillment = await _chooseFulfillment();
    if (fulfillment == null || !mounted) return;

    final orderItems = _checkoutItems;

    final itemCount = _cartItemCount;
    final total = _cartTotal;

    String customerName = '';
    String? customerUsername;
    try {
      final profile =
          Provider.of<ProfileProvider>(context, listen: false).profile;
      customerUsername = profile.username;
      customerName = profile.name;
    } catch (_) {}

    setState(() => _isOrdering = true);
    final pointsToRedeem = _pointsSelection.usePoints
        ? _pointsSelection.pointsToRedeem
        : 0;
    final afterCoupon = (total - _couponSelection.discountAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
    final payable = _pointsSelection.usePoints
        ? _pointsSelection.payableAmount
        : afterCoupon;
    await CatalogCheckout.placeWithPayment(
      context: context,
      totalAmount: payable,
      currency: _currency,
      customerName: customerName,
      customerUsername: customerUsername,
      businessName: widget.businessName,
      businessUsername: widget.businessUsername ?? widget.businessName,
      totalItems: itemCount,
      bookingKind: 'order',
      placeOrder: ({
        required String paymentMethod,
        required String idempotencyKey,
      }) {
        return CatalogRepo().placeOrder(
          businessId: widget.businessId!,
          businessLinkId: widget.existingLink!.id,
          catalogType: widget.catalogType,
          items: orderItems,
          orderType: fulfillment.orderType,
          fulfillmentAddress: fulfillment.address,
          paymentMethod: paymentMethod,
          idempotencyKey: idempotencyKey,
          pointsToRedeem: pointsToRedeem > 0 ? pointsToRedeem : null,
          couponCode: _couponSelection.applied &&
                  _couponSelection.code.isNotEmpty
              ? _couponSelection.code
              : null,
          offerId: _couponSelection.applied &&
                  _couponSelection.offerId.isNotEmpty
              ? _couponSelection.offerId
              : null,
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _isOrdering = false;
      _pointsSelection = CheckoutPointsSelection.none(0);
      _couponSelection = CheckoutCouponSelection.none;
    });
  }

}

class _CartBagIndicator extends StatelessWidget {
  final int count;

  const _CartBagIndicator({required this.count});

  @override
  Widget build(BuildContext context) {
    return CircleAssetButton(
      asset: 'assets/images/png/bag-icon.png',
      iconSize: 16,
      badge: count > 0,
    );
  }
}

void openCatalogLink({
  required BuildContext context,
  required SocialLink link,
  required String? businessId,
  required String? businessName,
  String? businessCategory,
  String? businessPhoto,
  String? businessUsername,
  String? currency,
  String? initialItemName,
}) {
  final catalogType = link.catalogType ?? CatalogHelper.typeForCategory(businessCategory);
  final catalogLabel = link.platformName.isNotEmpty
      ? link.platformName
      : CatalogHelper.labelForCategory(businessCategory, context.l10n);

  showMenuCatalogSheet(
    context: context,
    catalogLabel: catalogLabel,
    catalogType: catalogType,
    existingLink: link,
    businessId: businessId,
    businessName: businessName,
    businessPhoto: businessPhoto,
    businessUsername: businessUsername,
    currency: currency,
    isCustomerView: true,
    initialItemName: initialItemName,
  );
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/cart_line_item.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/service_schedule.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/catalog/catalog_item_form_screen.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/catalog_item_detail_sheet.dart';
import 'package:tapni_app/widgets/catalog_product_card.dart';
import 'package:tapni_app/widgets/document_viewer.dart';
import 'package:tapni_app/widgets/service_detail_sheet.dart';
import 'package:tapni_app/screens/catalog/service_booking_cart_screen.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

void showMenuCatalogSheet({
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
  String? initialItemName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MenuCatalogSheet(
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
      initialItemName: initialItemName,
    ),
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
  final String? initialItemName;

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
    this.initialItemName,
  });

  @override
  State<MenuCatalogSheet> createState() => _MenuCatalogSheetState();
}

class _MenuCatalogSheetState extends State<MenuCatalogSheet> {
  late List<CatalogItem> _items;
  late List<String> _catalogCategories;
  late ServiceSchedule _serviceSchedule;
  final _newCategoryCtrl = TextEditingController();
  bool showLink = true;
  bool _isSaving = false;
  bool _isOrdering = false;
  final List<CartLineItem> _cart = [];
  String? _selectedCategory;
  final Set<String> _expandedCategories = {};

  bool get _isServices => widget.catalogType == 'services';
  bool get _isDocuments => widget.catalogType == 'documents';
  bool _didOpenInitialItem = false;

  String get _currency => resolveCurrency(
        currency: widget.currency ?? widget.provider?.profile.currency,
        country: widget.provider?.profile.country,
      );

  @override
  void initState() {
    super.initState();
    _items = widget.existingLink?.catalogItems?.toList() ?? [];
    _catalogCategories = List<String>.from(
      widget.existingLink?.catalogCategories ?? [],
    );
    if (_catalogCategories.isEmpty && _items.isNotEmpty) {
      _catalogCategories = CatalogHelper.orderedCategories(
        catalogCategories: [],
        items: _items,
      );
    }
    _serviceSchedule =
        widget.existingLink?.serviceSchedule ?? const ServiceSchedule();
    showLink = widget.existingLink?.isPublic ?? true;

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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.isCustomerView
        ? (_isServices
            ? 'Services'
            : (widget.businessName ?? _catalogLabel))
        : (_isServices ? 'Manage Service' : 'Manage $_catalogLabel');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: widget.isCustomerView ? 0.85 : 0.9,
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
                const Center(child: SheetDragHandle()),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        CircleBackButton(onTap: () => Navigator.pop(context)),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.toolsTitleOf(
                              size: 18,
                              weight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (widget.isCustomerView)
                          (!_isDocuments)
                              ? _CartBagIndicator(count: _cartItemCount)
                              : const SizedBox(width: 40)
                        else
                          _buildBusinessActions(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: widget.isCustomerView
                      ? _buildCustomerView(scrollController)
                      : _buildBusinessView(scrollController),
                ),
                if (widget.isCustomerView && !_isDocuments)
                  SafeArea(
                    top: false,
                    child: _isServices
                        ? (_cart.isNotEmpty
                            ? _buildServiceContinueBar()
                            : const SizedBox.shrink())
                        : _buildOrderBar(),
                  ),
                if (!widget.isCustomerView)
                  SafeArea(top: false, child: _buildBusinessBottomBar()),
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

  Widget _buildBusinessView(ScrollController scrollController) {
    final grouped = CatalogHelper.groupByCategoryOrdered(
      items: _items,
      catalogCategories: _catalogCategories,
      activeOnly: false,
    );
    final categoryKeys = grouped.keys.toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
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
                      : context.l10n.noItemsYetAddFirstCatalogItem(
                          _catalogLabel,
                        ),
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
                ),
              ],
            ),
          )
        else if (_isDocuments)
          ...List.generate(_items.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: BarqodyChrome.fieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _businessItemTile(index),
            );
          })
        else
          ...categoryKeys.map(
            (category) =>
                _categoryAccordionCard(category, grouped[category]!),
          ),
        const SizedBox(height: 8),
        if (_isServices) ...[
          _buildServiceScheduleSettings(),
          const SizedBox(height: 16),
        ],
        _showPublicToggle(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _categoryAccordionCard(String category, List<CatalogItem> items) {
    final expanded = _expandedCategories.contains(category);
    final countLabel = '${items.length} item${items.length == 1 ? '' : 's'}';

    if (!expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expandedCategories.add(category)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: BarqodyChrome.fieldFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
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
              Text(
                countLabel,
                style: WaUi.body.copyWith(
                  fontSize: 13,
                  color: BarqodyChrome.secondaryText,
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
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedCategories.remove(category)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
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
                  Text(
                    countLabel,
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: BarqodyChrome.divider),
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
      ),
    );
  }

  Widget _businessItemTile(int index) {
    final item = _items[index];
    final subtitle = _isDocuments
        ? (item.description.isNotEmpty
            ? item.description
            : context.l10n.viewDocument)
        : (item.displayPrice > 0
            ? formatMoney(item.displayPrice, currency: _currency)
            : 'Free');

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
              'assets/images/png/edit-icon.png',
              width: 14,
              height: 14,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.black),
            ),
            onTap: () => _editItem(index),
          ),
          const SizedBox(width: 8),
          _circleIconButton(
            icon: Image.asset(
              'assets/images/png/delete-icon.png',
              width: 14,
              height: 14,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.white,
              ),
            ),
            bg: const Color(0xFFE53935),
            borderColor: const Color(0xFFE53935),
            onTap: () => setState(() => _items.removeAt(index)),
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

  Widget _buildBusinessActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.existingLink != null) ...[
          _deleteButton(),
          const SizedBox(width: 8),
        ],
        _isSaving
            ? const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            : CircleAssetButton(
                asset: 'assets/images/png/check-icon-1.png',
                iconSize: 16,
                onTap: _saveCatalogLink,
              ),
      ],
    );
  }

  Widget _deleteButton() {
    return _circleIconButton(
      icon: const Icon(
        Icons.delete_outline,
        size: 16,
        color: Color(0xFFE53935),
      ),
      bg: const Color(0xFFFDECEC),
      borderColor: const Color(0xFFF6C9C9),
      onTap: () async {
        if (widget.provider == null || widget.existingLink == null) return;
        await widget.provider!.deleteSocialLink(widget.existingLink!.id, context);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Widget _buildBusinessBottomBar() {
    if (_isDocuments) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: PillButton(
          label: context.l10n.addDocument,
          onPressed: _addItem,
        ),
      );
    }

    final addLabel = _isServices
        ? 'Add Service'
        : (_catalogLabel.toLowerCase() == 'menu'
            ? 'Add Menu'
            : context.l10n.addCatalogItem(_catalogLabel));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: PillButton(
              label: 'Manage Section',
              filled: false,
              onPressed: _openCategoryManagerSheet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PillButton(label: addLabel, onPressed: _addItem),
          ),
        ],
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: SheetDragHandle()),
                  const SizedBox(height: 16),
                  Text(
                    'Manage Section',
                    textAlign: TextAlign.center,
                    style: WaUi.toolsTitleOf(
                      size: 18,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_catalogCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        context.l10n.addCategoriesInDisplayOrderEGFastFoodThenDesi,
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
                        itemCount: _catalogCategories.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          _moveCategory(oldIndex, newIndex);
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
                          return _sectionRow(
                            key: ValueKey(cat),
                            name: cat,
                            count: count,
                            onEdit: () async {
                              await _renameCategorySheet(index);
                              setSheetState(() {});
                            },
                            onDelete: () {
                              _removeCategory(index);
                              setSheetState(() {});
                            },
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
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _sectionRow({
    required Key key,
    required String name,
    required int count,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      key: key,
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
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.black),
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _circleIconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 16,
              color: Color(0xFFE53935),
            ),
            bg: const Color(0xFFFDECEC),
            borderColor: const Color(0xFFF6C9C9),
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SheetDragHandle()),
                const SizedBox(height: 16),
                Text(
                  'Add Section',
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SheetDragHandle()),
                const SizedBox(height: 16),
                Text(
                  'Rename Section',
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
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
        ),
      ),
    );
  }

  void _addCategory() {
    final name = _newCategoryCtrl.text.trim();
    if (name.isEmpty) return;
    final exists = _catalogCategories.any(
      (c) => c.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.categoryAlreadyExists)),
      );
      return;
    }
    setState(() {
      _catalogCategories.add(name);
      _newCategoryCtrl.clear();
    });
  }

  void _removeCategory(int index) {
    setState(() {
      final removed = _catalogCategories.removeAt(index);
      _expandedCategories.remove(removed);
    });
  }

  void _moveCategory(int from, int to) {
    setState(() {
      final item = _catalogCategories.removeAt(from);
      _catalogCategories.insert(to, item);
    });
  }

  void _renameCategory(int index, String newName) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.categoryAlreadyExists)),
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

  Widget _showPublicToggle() {
    return Container(
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.showLink,
            style: WaUi.toolsTitleOf(
              size: 15,
              weight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Switch(
            value: showLink,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.black,
            onChanged: (val) => setState(() => showLink = val),
          ),
        ],
      ),
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
      );
      if (result.bookNow && mounted) {
        await _openServiceCart();
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
  }) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (line) =>
            line.itemIndex == index &&
            line.bookingDate == bookingDate &&
            line.bookingTime == bookingTime,
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
          ),
        );
      }
    });
  }

  Future<void> _openServiceCart() async {
    if (widget.businessId == null || widget.existingLink == null) return;
    if (_cart.isEmpty) return;

    final updated = await Navigator.of(context).push<List<CartLineItem>>(
      MaterialPageRoute(
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
            height: 50,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBar() {
    final total = _cartTotal;
    final itemCount = _cartItemCount;

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
      child: Row(
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
            width: 156,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  itemCount == 0 || _isOrdering ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------

  Future<void> _addItem() async {
    if (!widget.isCustomerView) {
      final ok = await ensureBusinessProfileComplete(context);
      if (!ok || !mounted) return;
    }
    if (!_isDocuments && _catalogCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addAtLeastOneCategoryFirst)),
      );
      return;
    }
    final result = await Navigator.push<CatalogItem>(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogItemFormScreen(
          catalogLabel: _catalogLabel,
          existingCategories: _catalogCategories,
          requireCategory: !_isDocuments,
          isDocument: _isDocuments,
          isService: _isServices,
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
    }
  }

  Future<void> _editItem(int index) async {
    final result = await Navigator.push<CatalogItem>(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogItemFormScreen(
          catalogLabel: _catalogLabel,
          existingItem: _items[index],
          existingCategories: _catalogCategories,
          requireCategory: !_isDocuments && _catalogCategories.isNotEmpty,
          isDocument: _isDocuments,
          isService: _isServices,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _ensureCategoryOnList(result.category);
        _items[index] = result;
      });
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

    if (image.isEmpty || !DocumentFileHelper.isImage(image)) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Future<void> _saveCatalogLink() async {
    if (widget.provider == null) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addAtLeastOneCatalogItem(_catalogLabel))),
      );
      return;
    }

    setState(() => _isSaving = true);

    final savedCategories = CatalogHelper.orderedCategories(
      catalogCategories: _catalogCategories,
      items: _items,
    );

    final label = widget.template?.label ?? _catalogLabel;
    final templateId = widget.template?.id ?? widget.existingLink?.templateId;
    final logoUrl = widget.template?.logo ?? widget.existingLink?.logoUrl;
    final link = widget.existingLink != null
        ? widget.existingLink!.copyWith(
            customLabel: label,
            fieldType: 'menu_catalog',
            templateId: templateId,
            logoUrl: logoUrl,
            catalogItems: _items,
            catalogCategories: savedCategories,
            catalogType: widget.catalogType,
            serviceSchedule: _isServices ? _serviceSchedule : null,
            value: widget.existingLink!.id,
            isPublic: showLink,
          )
        : SocialLink(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            platform: SocialPlatform.spoonFork,
            templateId: templateId,
            customLabel: label,
            fieldType: 'menu_catalog',
            logoUrl: logoUrl,
            catalogItems: _items,
            catalogCategories: savedCategories,
            catalogType: widget.catalogType,
            serviceSchedule: _isServices ? _serviceSchedule : null,
            value: 'catalog',
            isActive: true,
            isPublic: showLink,
          );

    final updatedLinks = List<SocialLink>.from(widget.provider!.profile.socialLinks);
    if (widget.existingLink != null) {
      final idx = updatedLinks.indexWhere((l) => l.id == widget.existingLink!.id);
      if (idx != -1) updatedLinks[idx] = link;
    } else {
      updatedLinks.add(link);
    }

    await widget.provider!.updateLinks(links: updatedLinks, context: context);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  String? _orderIdFromApiData(dynamic data) {
    if (data is! Map) return null;
    final payload = data['data'] is Map ? data['data'] : data;
    if (payload is! Map) return null;
    final id = payload['id'] ?? payload['_id'];
    if (id == null) return null;
    final str = id.toString();
    return str.isEmpty ? null : str;
  }

  Future<void> _placeOrder() async {
    if (widget.businessId == null || widget.existingLink == null) return;

    setState(() => _isOrdering = true);

    final orderItems = _cart.map((line) {
      final item = _items[line.itemIndex];
      return {
        'name': item.name,
        'price': item.displayPrice,
        'quantity': line.quantity,
        if (item.imageUrl.isNotEmpty) 'image': item.imageUrl,
        if (line.notes.isNotEmpty) 'notes': line.notes,
      };
    }).toList();

    final itemCount = _cartItemCount;
    final total = _cartTotal;

    final res = await CatalogRepo().placeOrder(
      businessId: widget.businessId!,
      businessLinkId: widget.existingLink!.id,
      catalogType: widget.catalogType,
      items: orderItems,
    );

    if (!mounted) return;
    setState(() => _isOrdering = false);

    if (res.success) {
      final token = CatalogOrder.tokenFromApi(res.data);
      final orderId = _orderIdFromApiData(res.data);
      await _showOrderPlacedDialog(
        token: token,
        itemCount: itemCount,
        total: total,
        orderId: orderId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToPlaceOrder)),
      );
    }
  }

  Future<void> _showOrderPlacedDialog({
    required int token,
    required int itemCount,
    required double total,
    String? orderId,
  }) async {
    final navigator = Navigator.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BarqodyChrome.sheetRadius),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/png/check-icon-1.png',
                    width: 32,
                    height: 32,
                    color: Colors.white,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Your Order Was Placed!',
                textAlign: TextAlign.center,
                style: WaUi.toolsTitleOf(
                  size: 20,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.businessName != null
                    ? 'Your order has been sent to ${widget.businessName}.'
                    : context.l10n.orderPlacedWith(context.l10n.businessLabel),
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  color: BarqodyChrome.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: BarqodyChrome.fieldFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (token > 0) _orderSummaryRow('Token', '#$token'),
                    if (widget.businessName != null)
                      _orderSummaryRow('Business', widget.businessName!),
                    _orderSummaryRow('Total Items', '$itemCount'),
                    _orderSummaryRow(
                      'Total',
                      formatMoney(total, currency: _currency),
                      bold: true,
                      last: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PillButton(
                label: 'Go Home',
                onPressed: () {
                  Navigator.pop(ctx);
                  navigator.pop();
                },
              ),
              if (orderId != null) ...[
                const SizedBox(height: 12),
                PillButton(
                  label: 'Track Order',
                  filled: false,
                  onPressed: () {
                    Navigator.pop(ctx);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(
                          orderId: orderId,
                          isBusinessView: false,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderSummaryRow(String label, String value,
      {bool bold = false, bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: BarqodyChrome.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          Text(
            value,
            style: WaUi.body.copyWith(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
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

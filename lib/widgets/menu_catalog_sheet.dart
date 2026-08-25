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
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/catalog_item_detail_sheet.dart';
import 'package:tapni_app/widgets/catalog_product_card.dart';
import 'package:tapni_app/widgets/document_viewer.dart';
import 'package:tapni_app/widgets/service_booking_sheet.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/shop_product_card.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: widget.isCustomerView ? 0.85 : 0.9,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.isCustomerView
                                ? widget.businessName ?? _catalogLabel
                                : _catalogLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: widget.isCustomerView
                        ? _buildCustomerView(scrollController, isDark)
                        : _buildBusinessView(scrollController, isDark),
                  ),
                  if (widget.isCustomerView && !_isServices && !_isDocuments)
                    _buildOrderBar(isDark),
                  if (!widget.isCustomerView) _buildBusinessActions(isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessView(ScrollController scrollController, bool isDark) {
    final grouped = CatalogHelper.groupByCategoryOrdered(
      items: _items,
      catalogCategories: _catalogCategories,
      activeOnly: false,
    );
    final categoryKeys = grouped.keys.toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (!_isDocuments) ...[
          _buildCategoryManager(isDark),
          const SizedBox(height: 16),
        ],
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
                    color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _isDocuments
                      ? context.l10n.noDocumentsYet
                      : context.l10n.noItemsYetAddFirstCatalogItem(_catalogLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else if (_isDocuments)
          ...List.generate(_items.length, (index) {
            return _businessItemTile(index, isDark);
          })
        else
          ...categoryKeys.expand((category) {
            final categoryItems = grouped[category]!;
            return [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...categoryItems.map((item) {
                final index = _items.indexOf(item);
                return _businessItemTile(index, isDark);
              }),
            ];
          }),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: Icon(Icons.add),
          label: Text(
            _isDocuments
                ? context.l10n.addDocument
                : context.l10n.addCatalogItem(_catalogLabel),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_isServices) ...[
          SizedBox(height: 20),
          _buildServiceScheduleSettings(isDark),
        ],
        SizedBox(height: 16),
        _showPublicToggle(isDark),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCategoryManager(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.yourCategories,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            context.l10n.addCategoriesInDisplayOrderEGFastFoodThenDesi,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCategoryCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCategory(),
                  decoration: WaUi.fieldDecoration(
                    hintText: context.l10n.eGFastFood,
                    radius: 10,
                  ).copyWith(isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_catalogCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_catalogCategories.length, (index) {
              final cat = _catalogCategories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111111) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_upward, size: 18),
                      onPressed: index > 0
                          ? () => _moveCategory(index, index - 1)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward, size: 18),
                      onPressed: index < _catalogCategories.length - 1
                          ? () => _moveCategory(index, index + 1)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: Colors.red.shade400),
                      onPressed: () => _removeCategory(index),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
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
    setState(() => _catalogCategories.removeAt(index));
  }

  void _moveCategory(int from, int to) {
    setState(() {
      final item = _catalogCategories.removeAt(from);
      _catalogCategories.insert(to, item);
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

  Widget _buildServiceScheduleSettings(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.bookingSchedule,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          SizedBox(height: 12),
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
              SizedBox(width: 10),
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
              SizedBox(width: 10),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _businessItemTile(int index, bool isDark) {
    final item = _items[index];
    final category = item.category.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _itemImage(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontWeight: FontWeight.w600)),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!_isDocuments) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.price > 0
                        ? formatMoney(item.price, currency: _currency)
                        : 'Free',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editItem(index),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerView(ScrollController scrollController, bool isDark) {
    if (_items.where((i) => i.isActive).isEmpty) {
      return Center(
        child: Text(
          _isDocuments
              ? context.l10n.noDocumentsAvailable
              : context.l10n.noCatalogItemsAvailable(_catalogLabel),
          style: TextStyle(color: Colors.grey.shade600),
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
          return _customerDocumentTile(item, isDark);
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
          style: TextStyle(color: Colors.grey.shade600),
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
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  mainAxisExtent: ShopProductCard.heightForWidth(cardW),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = flatItems[index];
                    final originalIndex = _items.indexOf(item);
                    return CatalogProductCard(
                      item: item,
                      isService: _isServices,
                      currency: _currency,
                      cartQty: _isServices
                          ? null
                          : _cartQtyForIndex(originalIndex),
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

  Widget _customerDocumentTile(CatalogItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
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
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => openCatalogDocument(context, item),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryBlack,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        checkmarkColor: Colors.white,
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
      final booked = await showServiceBookingSheet(
        context: context,
        item: item,
        businessId: widget.businessId!,
        businessLinkId: widget.existingLink!.id,
        businessName: widget.businessName ?? 'business',
        currency: _currency,
      );
      if (booked == true && mounted) {
        Navigator.pop(context);
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

  Widget _buildOrderBar(bool isDark) {
    final total = _cart.fold<double>(0, (sum, line) {
      final item = _items[line.itemIndex];
      return sum + item.price * line.quantity;
    });
    final itemCount = _cart.fold<int>(0, (sum, line) => sum + line.quantity);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF111111) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: WaPrimaryButton(
        label: itemCount == 0
            ? context.l10n.placeOrder
            : '${context.l10n.placeOrder} (${formatMoney(total, currency: _currency)})',
        loading: _isOrdering,
        onPressed: itemCount == 0 || _isOrdering ? null : _placeOrder,
      ),
    );
  }

  Widget _buildBusinessActions(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          if (widget.existingLink != null) ...[
            _deleteButton(),
            SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCatalogLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.l10n.save, style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF5F5F5),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        icon: Icon(Icons.delete_forever_outlined),
        onPressed: () async {
          if (widget.provider == null || widget.existingLink == null) return;
          await widget.provider!.deleteSocialLink(widget.existingLink!.id, context);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _showPublicToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.showLink, style: TextStyle(fontWeight: FontWeight.w500)),
          Switch(
            value: showLink,
            activeColor: Colors.white,
            activeTrackColor: Color(0xFF1E2022),
            onChanged: (val) => setState(() => showLink = val),
          ),
        ],
      ),
    );
  }

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
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _ensureCategoryOnList(result.category);
        _items.add(result);
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _isDocuments
            ? (DocumentFileHelper.isPdf(image)
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined)
            : Icons.fastfood_outlined,
        color: Colors.grey.shade500,
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

  Future<void> _placeOrder() async {
    if (widget.businessId == null || widget.existingLink == null) return;

    setState(() => _isOrdering = true);

    final orderItems = _cart.map((line) {
      final item = _items[line.itemIndex];
      return {
        'name': item.name,
        'price': item.price,
        'quantity': line.quantity,
        if (line.notes.isNotEmpty) 'notes': line.notes,
      };
    }).toList();

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
      final message = token > 0
          ? 'Token #$token — ${context.l10n.orderPlacedWith(
              widget.businessName ?? context.l10n.businessLabel,
            )}'
          : context.l10n.orderPlacedWith(
              widget.businessName ?? context.l10n.businessLabel,
            );
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToPlaceOrder)),
      );
    }
  }
}

void openCatalogLink({
  required BuildContext context,
  required SocialLink link,
  required String? businessId,
  required String? businessName,
  String? businessCategory,
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
    currency: currency,
    isCustomerView: true,
    initialItemName: initialItemName,
  );
}

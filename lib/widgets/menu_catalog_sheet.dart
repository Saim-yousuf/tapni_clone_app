import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/theme.dart';

void showMenuCatalogSheet({
  required BuildContext context,
  required String catalogLabel,
  required String catalogType,
  ProfileProvider? provider,
  SocialLink? existingLink,
  String? businessId,
  String? businessName,
  bool isCustomerView = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MenuCatalogSheet(
      catalogLabel: catalogLabel,
      catalogType: catalogType,
      provider: provider,
      existingLink: existingLink,
      businessId: businessId,
      businessName: businessName,
      isCustomerView: isCustomerView,
    ),
  );
}

class MenuCatalogSheet extends StatefulWidget {
  final String catalogLabel;
  final String catalogType;
  final ProfileProvider? provider;
  final SocialLink? existingLink;
  final String? businessId;
  final String? businessName;
  final bool isCustomerView;

  const MenuCatalogSheet({
    super.key,
    required this.catalogLabel,
    required this.catalogType,
    this.provider,
    this.existingLink,
    this.businessId,
    this.businessName,
    this.isCustomerView = false,
  });

  @override
  State<MenuCatalogSheet> createState() => _MenuCatalogSheetState();
}

class _MenuCatalogSheetState extends State<MenuCatalogSheet> {
  late List<CatalogItem> _items;
  bool showLink = true;
  bool _isSaving = false;
  bool _isOrdering = false;
  final Map<int, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _items = widget.existingLink?.catalogItems?.toList() ?? [];
    showLink = widget.existingLink?.isPublic ?? true;
  }

  String get _catalogLabel => widget.catalogLabel;

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
                          style: const TextStyle(
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
                      ? _buildCustomerView(scrollController)
                      : _buildBusinessView(scrollController, isDark),
                ),
                if (widget.isCustomerView) _buildOrderBar(isDark),
                if (!widget.isCustomerView) _buildBusinessActions(isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessView(ScrollController scrollController, bool isDark) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No items yet. Add your first $_catalogLabel item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ...List.generate(_items.length, (index) => _businessItemTile(index, isDark)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: Text('Add $_catalogLabel item'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        _showPublicToggle(isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _businessItemTile(int index, bool isDark) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  item.price > 0 ? 'Rs ${item.price.toStringAsFixed(0)}' : 'Free',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editItem(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerView(ScrollController scrollController) {
    final activeItems = _items.where((item) => item.isActive).toList();

    if (activeItems.isEmpty) {
      return Center(
        child: Text(
          'No $_catalogLabel items available.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: activeItems.length,
      itemBuilder: (context, index) {
        final item = activeItems[index];
        final originalIndex = _items.indexOf(item);
        final qty = _cart[originalIndex] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      item.price > 0 ? 'Rs ${item.price.toStringAsFixed(0)}' : 'Free',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: qty > 0
                        ? () => setState(() {
                              if (qty == 1) {
                                _cart.remove(originalIndex);
                              } else {
                                _cart[originalIndex] = qty - 1;
                              }
                            })
                        : null,
                  ),
                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _cart[originalIndex] = qty + 1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderBar(bool isDark) {
    final total = _cart.entries.fold<double>(0, (sum, entry) {
      final item = _items[entry.key];
      return sum + item.price * entry.value;
    });
    final itemCount = _cart.values.fold<int>(0, (sum, qty) => sum + qty);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$itemCount items'),
                Text(
                  'Total: Rs ${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: itemCount == 0 || _isOrdering ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isOrdering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Place Order', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          if (widget.existingLink != null) ...[
            _deleteButton(),
            const SizedBox(width: 12),
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
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
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        icon: const Icon(Icons.delete_forever_outlined),
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
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Show link', style: TextStyle(fontWeight: FontWeight.w500)),
          Switch(
            value: showLink,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1E2022),
            onChanged: (val) => setState(() => showLink = val),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final result = await _showItemDialog();
    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  Future<void> _editItem(int index) async {
    final result = await _showItemDialog(existing: _items[index]);
    if (result != null) {
      setState(() => _items[index] = result);
    }
  }

  Future<CatalogItem?> _showItemDialog({CatalogItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null && existing.price > 0 ? existing.price.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    return showDialog<CatalogItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add item' : 'Edit item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (Rs)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                ctx,
                CatalogItem(
                  name: name,
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                  description: descCtrl.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCatalogLink() async {
    if (widget.provider == null) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add at least one $_catalogLabel item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final label = _catalogLabel;
    final link = widget.existingLink != null
        ? widget.existingLink!.copyWith(
            customLabel: label,
            fieldType: 'menu_catalog',
            catalogItems: _items,
            catalogType: widget.catalogType,
            value: widget.existingLink!.id,
            isPublic: showLink,
          )
        : SocialLink(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            platform: SocialPlatform.spoonFork,
            customLabel: label,
            fieldType: 'menu_catalog',
            catalogItems: _items,
            catalogType: widget.catalogType,
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

    final orderItems = _cart.entries.map((entry) {
      final item = _items[entry.key];
      return {
        'name': item.name,
        'price': item.price,
        'quantity': entry.value,
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed with ${widget.businessName ?? "business"}!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to place order')),
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
}) {
  final catalogType = link.catalogType ?? CatalogHelper.typeForCategory(businessCategory);
  final catalogLabel = link.platformName.isNotEmpty
      ? link.platformName
      : CatalogHelper.labelForCategory(businessCategory);

  showMenuCatalogSheet(
    context: context,
    catalogLabel: catalogLabel,
    catalogType: catalogType,
    existingLink: link,
    businessId: businessId,
    businessName: businessName,
    isCustomerView: true,
  );
}

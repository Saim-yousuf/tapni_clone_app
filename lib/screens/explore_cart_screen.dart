import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/catalog_item_detail_sheet.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class ExploreCartScreen extends StatefulWidget {
  const ExploreCartScreen({super.key});

  @override
  State<ExploreCartScreen> createState() => _ExploreCartScreenState();
}

class _ExploreCartScreenState extends State<ExploreCartScreen> {
  bool _placing = false;

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
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WaUi.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'Add more from ${vendor.businessName}',
                    style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
                  ),
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
                              ? 'Rs ${item.price.toStringAsFixed(0)}'
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
    );
    if (detail == null || !mounted || detail.quantity <= 0) return;

    cart.addItem(
      businessId: vendor.businessId,
      businessLinkId: vendor.businessLinkId,
      businessName: vendor.businessName,
      catalogType: vendor.catalogType,
      catalogItems: vendor.catalogItems,
      line: ExploreCartLine(
        item: selected,
        quantity: detail.quantity,
        notes: detail.notes,
      ),
    );
  }

  Future<void> _placeOrders() async {
    final cart = context.read<ExploreCartProvider>();
    if (cart.isEmpty) return;

    setState(() => _placing = true);
    final repo = CatalogRepo();
    final vendors = List<ExploreCartVendor>.from(cart.vendors);
    final placed = <String>[];
    String? lastError;

    for (final vendor in vendors) {
      if (vendor.lines.isEmpty) continue;
      final orderItems = vendor.lines
          .map(
            (line) => {
              'name': line.item.name,
              'price': line.item.price,
              'quantity': line.quantity,
              if (line.notes.isNotEmpty) 'notes': line.notes,
            },
          )
          .toList();

      final res = await repo.placeOrder(
        businessId: vendor.businessId,
        businessLinkId: vendor.businessLinkId,
        catalogType: vendor.catalogType,
        items: orderItems,
      );

      if (res.success) {
        final token = CatalogOrder.tokenFromApi(res.data);
        placed.add(
          token > 0
              ? '${vendor.businessName} · Token #$token'
              : vendor.businessName,
        );
        cart.removeVendor(vendor.businessLinkId);
      } else {
        lastError = res.message ?? context.l10n.failedToPlaceOrder;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _placing = false);

    final messenger = ScaffoldMessenger.of(context);
    if (placed.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            placed.length == 1
                ? context.l10n.orderPlacedWith(placed.first)
                : 'Orders placed: ${placed.join(', ')}',
          ),
        ),
      );
    }
    if (lastError != null) {
      messenger.showSnackBar(SnackBar(content: Text(lastError)));
    }
    if (cart.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<ExploreCartProvider>();
    final vendors = cart.vendors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: cart.isEmpty
          ? Center(
              child: Text(
                'Your cart is empty',
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                Text(
                  '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}'
                  '${cart.vendorCount > 1 ? ' · ${cart.vendorCount} stores' : ''}',
                  style: WaUi.label.copyWith(color: WaUi.secondaryText),
                ),
                const SizedBox(height: 12),
                ...vendors.map((vendor) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.businessName,
                              style: WaUi.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'Rs ${vendor.total.toStringAsFixed(0)}',
                            style: WaUi.label.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...vendor.lines.asMap().entries.map((entry) {
                        final index = entry.key;
                        final line = entry.value;
                        return _CartTile(
                          line: line,
                          onRemove: () => cart.removeLine(
                            businessLinkId: vendor.businessLinkId,
                            lineIndex: index,
                          ),
                          onQtyChanged: (qty) => cart.updateQuantity(
                            businessLinkId: vendor.businessLinkId,
                            lineIndex: index,
                            quantity: qty,
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => _addMore(vendor),
                        icon: const Icon(Icons.add_rounded),
                        label: Text('Add more from ${vendor.businessName}'),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 24),
                    ],
                  );
                }),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.total,
                            style: WaUi.label.copyWith(
                              color: WaUi.secondaryText,
                            ),
                          ),
                          Text(
                            'Rs ${cart.total.toStringAsFixed(0)}',
                            style: WaUi.title.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: WaPrimaryButton(
                        label: cart.vendorCount > 1
                            ? 'Place all orders'
                            : context.l10n.placeOrder,
                        loading: _placing,
                        onPressed: _placing ? null : _placeOrders,
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
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _CartTile({
    required this.line,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = line.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaUi.divider),
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs ${line.lineTotal.toStringAsFixed(0)}',
                  style: WaUi.label.copyWith(fontWeight: FontWeight.w700),
                ),
                if (line.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.label.copyWith(color: WaUi.secondaryText),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove,
                      onTap: () => onQtyChanged(line.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${line.quantity}',
                        style: WaUi.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add,
                      onTap: () => onQtyChanged(line.quantity + 1),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: WaUi.chipBorder),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/theme.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
Future<({int quantity, String notes})?> showCatalogItemDetailSheet({
  required BuildContext context,
  required CatalogItem item,
  int initialQty = 0,
  String initialNotes = '',
}) {
  return showModalBottomSheet<({int quantity, String notes})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CatalogItemDetailSheet(
      item: item,
      initialQty: initialQty,
      initialNotes: initialNotes,
    ),
  );
}

class _CatalogItemDetailSheet extends StatefulWidget {
  final CatalogItem item;
  final int initialQty;
  final String initialNotes;

  const _CatalogItemDetailSheet({
    required this.item,
    required this.initialQty,
    required this.initialNotes,
  });

  @override
  State<_CatalogItemDetailSheet> createState() =>
      _CatalogItemDetailSheetState();
}

class _CatalogItemDetailSheetState extends State<_CatalogItemDetailSheet> {
  late int _qty;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty > 0 ? widget.initialQty : 1;
    _notesCtrl = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF111111) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImage(),
                      const SizedBox(height: 16),
                      Text(
                        widget.item.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        widget.item.price > 0
                            ? 'Rs ${widget.item.price.toStringAsFixed(0)}'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.item.description.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Text(
                          widget.item.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                      Text(
                        context.l10n.specialInstructions,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: context.l10n.eGNoSugarExtraHot,
                          filled: true,
                          fillColor: isDark
                              ? Color(0xFF1E1E1E)
                              : Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Text(context.l10n.quantity,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _qty > 1
                                ? () => setState(() => _qty--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_qty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _qty++),
                            icon: Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (quantity: _qty, notes: _notesCtrl.text.trim()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      widget.initialQty > 0 ? context.l10n.updateCart : context.l10n.addToCart,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
  }

  Widget _buildImage() {
    final image = widget.item.imageUrl.trim();
    if (image.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.fastfood_outlined, size: 48, color: Colors.grey.shade400),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        image,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 180,
          color: Colors.grey.shade100,
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}

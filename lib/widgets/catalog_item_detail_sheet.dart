import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

Future<({int quantity, String notes})?> showCatalogItemDetailSheet({
  required BuildContext context,
  required CatalogItem item,
  String? currency,
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
      currency: currency,
      initialQty: initialQty,
      initialNotes: initialNotes,
    ),
  );
}

class _CatalogItemDetailSheet extends StatefulWidget {
  final CatalogItem item;
  final String? currency;
  final int initialQty;
  final String initialNotes;

  const _CatalogItemDetailSheet({
    required this.item,
    this.currency,
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

  void _popWithResult() {
    Navigator.pop(
      context,
      (quantity: _qty, notes: _notesCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BarqodyChrome.sheetRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Center(child: SheetDragHandle()),
              const SizedBox(height: 8),
              BarqodyTitleBar(
                title: l10n.menu,
                onBack: () => Navigator.pop(context),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    BarqodyChrome.sidePad,
                    12,
                    BarqodyChrome.sidePad,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroImage(),
                      const SizedBox(height: 20),
                      Text(
                        widget.item.name,
                        style: WaUi.toolsTitleOf(
                          size: 22,
                          weight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.price > 0
                            ? formatMoney(
                                widget.item.price,
                                currency: widget.currency,
                              )
                            : formatMoney(
                                0,
                                currency: widget.currency,
                                freeLabel: 'Free',
                              ),
                        style: WaUi.toolsTitleOf(
                          size: 20,
                          weight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      if (widget.item.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n.description,
                          style: WaUi.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: BarqodyChrome.divider,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.description.trim(),
                          style: WaUi.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: BarqodyChrome.bodyText,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        l10n.specialInstructions,
                        style: WaUi.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: WaUi.body.copyWith(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.eGNoSugarExtraHot,
                          hintStyle: WaUi.body.copyWith(
                            fontSize: 15,
                            color: BarqodyChrome.secondaryText,
                          ),
                          filled: true,
                          fillColor: BarqodyChrome.fieldFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final lineTotal = widget.item.price * _qty;
    final base = widget.initialQty > 0
        ? context.l10n.updateCart
        : context.l10n.addToCart;
    final label = widget.item.price > 0
        ? '$base (${formatMoney(lineTotal, currency: widget.currency)})'
        : base;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        BarqodyChrome.sidePad,
        12,
        BarqodyChrome.sidePad,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: BarqodyChrome.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          _QtyStepper(
            qty: _qty,
            onDecrement: _qty > 1
                ? () => setState(() => _qty--)
                : null,
            onIncrement: () => setState(() => _qty++),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _popWithResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.promoButton.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    const radius = BorderRadius.all(Radius.circular(20));
    final image = widget.item.imageUrl.trim();
    if (image.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          height: 220,
          width: double.infinity,
          color: BarqodyChrome.fieldFill,
          child: Icon(
            Icons.fastfood_outlined,
            size: 56,
            color: BarqodyChrome.secondaryText,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedAppImage(
        url: image,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        borderRadius: radius,
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _QtyStepper({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OutlinedQtyCircle(
          icon: Icons.remove,
          onTap: onDecrement,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '$qty',
            style: WaUi.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        _FilledQtyCircle(
          icon: Icons.add,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _OutlinedQtyCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OutlinedQtyCircle({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? Colors.black : BarqodyChrome.divider,
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.black : BarqodyChrome.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _FilledQtyCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FilledQtyCircle({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

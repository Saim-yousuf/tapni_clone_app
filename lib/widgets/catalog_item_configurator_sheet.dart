import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_item_options.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/catalog_size_chips.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class CatalogItemConfigurationResult {
  final String variantId;
  final List<String> optionIds;
  final String configurationLabel;
  final double unitPrice;
  final int quantity;
  final String notes;

  const CatalogItemConfigurationResult({
    required this.variantId,
    required this.optionIds,
    required this.configurationLabel,
    required this.unitPrice,
    this.quantity = 1,
    this.notes = '',
  });

  ExploreCartLine toCartLine(CatalogItem item) {
    return ExploreCartLine(
      item: item,
      quantity: quantity,
      notes: notes,
      variantId: variantId,
      optionIds: optionIds,
      configurationLabel: configurationLabel,
    );
  }
}

/// Quiet white/stone bottom sheet for sizes + option groups.
Future<CatalogItemConfigurationResult?> showCatalogItemConfiguratorSheet({
  required BuildContext context,
  required CatalogItem item,
  String currency = 'PKR',
  int initialQuantity = 1,
  String initialNotes = '',
  String? initialVariantId,
  List<String> initialOptionIds = const [],
  String addLabel = 'Add to cart',
}) {
  if (!item.hasConfiguration) return Future.value(null);
  return showAppModalBottomSheet<CatalogItemConfigurationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(BarqodyChrome.sheetRadius),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) => _CatalogItemConfiguratorSheet(
      item: item,
      currency: currency,
      initialQuantity: initialQuantity,
      initialNotes: initialNotes,
      initialVariantId: initialVariantId,
      initialOptionIds: initialOptionIds,
      addLabel: addLabel,
    ),
  );
}

class _CatalogItemConfiguratorSheet extends StatefulWidget {
  final CatalogItem item;
  final String currency;
  final int initialQuantity;
  final String initialNotes;
  final String? initialVariantId;
  final List<String> initialOptionIds;
  final String addLabel;

  const _CatalogItemConfiguratorSheet({
    required this.item,
    required this.currency,
    required this.initialQuantity,
    required this.initialNotes,
    required this.initialVariantId,
    required this.initialOptionIds,
    required this.addLabel,
  });

  @override
  State<_CatalogItemConfiguratorSheet> createState() =>
      _CatalogItemConfiguratorSheetState();
}

class _CatalogItemConfiguratorSheetState
    extends State<_CatalogItemConfiguratorSheet> {
  late String? _variantId;
  late final Set<String> _selectedOptions;
  late int _qty;
  late final TextEditingController _notesCtrl;

  List<CatalogVariant> get _variants => widget.item.activeVariants;
  List<CatalogOptionGroup> get _groups => widget.item.activeOptionGroups;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQuantity.clamp(1, 99);
    _notesCtrl = TextEditingController(text: widget.initialNotes);
    final vs = _variants;
    final initial = (widget.initialVariantId ?? '').trim();
    if (initial.isNotEmpty && vs.any((v) => v.id == initial)) {
      _variantId = initial;
    } else if (vs.length == 1) {
      _variantId = vs.first.id;
    } else if (vs.isNotEmpty) {
      var best = vs.first;
      for (final v in vs) {
        if (v.price < best.price) best = v;
      }
      _variantId = best.id;
    } else {
      _variantId = null;
    }
    _selectedOptions = {
      for (final id in widget.initialOptionIds)
        if (id.trim().isNotEmpty) id.trim(),
    };
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  List<String> get _optionIds => _selectedOptions.toList();

  double get _unit => widget.item.configuredUnitPrice(
        variantId: _variantId,
        optionIds: _optionIds,
      );

  String? get _validation => widget.item.validateConfiguration(
        variantId: _variantId,
        optionIds: _optionIds,
      );

  bool get _canAdd => _validation == null;

  void _toggleOption(CatalogOptionGroup group, CatalogOption option) {
    setState(() {
      if (group.isSingle) {
        for (final o in group.activeOptions) {
          _selectedOptions.remove(o.id);
        }
        _selectedOptions.add(option.id);
        return;
      }
      if (_selectedOptions.contains(option.id)) {
        _selectedOptions.remove(option.id);
        return;
      }
      final selectedInGroup =
          group.activeOptions.where((o) => _selectedOptions.contains(o.id)).length;
      if (selectedInGroup >= group.maxSelections) {
        for (final o in group.activeOptions) {
          if (_selectedOptions.contains(o.id)) {
            _selectedOptions.remove(o.id);
            break;
          }
        }
      }
      _selectedOptions.add(option.id);
    });
  }

  void _submit() {
    if (!_canAdd) return;
    final label = widget.item.configurationLabel(
      variantId: _variantId,
      optionIds: _optionIds,
    );
    Navigator.pop(
      context,
      CatalogItemConfigurationResult(
        variantId: (_variantId ?? '').trim(),
        optionIds: _optionIds,
        configurationLabel: label,
        unitPrice: _unit,
        quantity: _qty,
        notes: _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final money = formatMoney(_unit * _qty, currency: widget.currency);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHandleThen(
                afterHandleGap: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BarqodyChrome.sidePad,
                    0,
                    BarqodyChrome.sidePad,
                    4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.item.imageUrl.trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.item.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 44,
                              height: 44,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          widget.item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleCloseButton(
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    BarqodyChrome.sidePad,
                    8,
                    BarqodyChrome.sidePad,
                    16,
                  ),
                  shrinkWrap: true,
                  children: [
                    if (_variants.isNotEmpty) ...[
                      const _SectionLabel('Size'),
                      const SizedBox(height: 10),
                      CatalogSizeChips(
                        variants: _variants,
                        selectedId: _variantId,
                        currency: widget.currency,
                        onSelected: (id) => setState(() => _variantId = id),
                      ),
                      const SizedBox(height: 18),
                    ],
                    for (final g in _groups) ...[
                      _SectionLabel(
                        g.name,
                        hint: g.isRequired
                            ? (g.isSingle
                                ? 'Required'
                                : 'Required · up to ${g.maxSelections}')
                            : (g.isSingle
                                ? 'Optional'
                                : 'Up to ${g.maxSelections}'),
                        hintAsPill: true,
                      ),
                      const SizedBox(height: 2),
                      for (var i = 0; i < g.activeOptions.length; i++) ...[
                        _OptionTile(
                          name: g.activeOptions[i].name,
                          priceLabel: g.activeOptions[i].price > 0
                              ? '+${formatMoney(g.activeOptions[i].price, currency: widget.currency)}'
                              : '',
                          selected: _selectedOptions
                              .contains(g.activeOptions[i].id),
                          single: g.isSingle,
                          showDivider: i < g.activeOptions.length - 1,
                          onTap: () =>
                              _toggleOption(g, g.activeOptions[i]),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF0F0F2),
                    ),
                    const _SectionLabel('Notes'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        filled: true,
                        fillColor: const Color(0xFFF6F6F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  12,
                  BarqodyChrome.sidePad,
                  12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF0F0F2)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Quantity',
                          style: WaUi.toolsTitleOf(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        _QtyBtn(
                          icon: Icons.remove,
                          onTap: _qty > 1
                              ? () => setState(() => _qty -= 1)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: AnimatedSwitcher(
                            duration: AppMotion.content,
                            switchInCurve: AppMotion.easeOut,
                            switchOutCurve: AppMotion.easeIn,
                            child: Text(
                              '$_qty',
                              key: ValueKey(_qty),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        _QtyBtn(
                          icon: Icons.add,
                          onTap: _qty < 99
                              ? () => setState(() => _qty += 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_canAdd && _validation != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _validation!,
                          style: WaUi.caption.copyWith(
                            color: BarqodyChrome.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    WaPrimaryButton(
                      label: '${widget.addLabel} · $money',
                      onPressed: _canAdd ? _submit : null,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  final String? hint;
  final bool hintAsPill;

  const _SectionLabel(
    this.text, {
    this.hint,
    this.hintAsPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final hintText = hint;
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: WaUi.toolsTitleOf(
              size: 15,
              weight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        if (hintText != null)
          hintAsPill
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    hintText,
                    style: WaUi.caption.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                )
              : Text(
                  hintText,
                  style: WaUi.caption.copyWith(
                    color: BarqodyChrome.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String name;
  final String priceLabel;
  final bool selected;
  final bool single;
  final bool showDivider;
  final VoidCallback onTap;

  const _OptionTile({
    required this.name,
    required this.priceLabel,
    required this.selected,
    required this.single,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F2)),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.content,
                curve: AppMotion.easeOut,
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: single ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: single ? null : BorderRadius.circular(5),
                  color: selected ? Colors.black : Colors.transparent,
                  border: Border.all(
                    color: selected ? Colors.black : const Color(0xFFC8C8CE),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        single ? Icons.circle : Icons.check,
                        size: single ? 8 : 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 15,
                    height: 1.25,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: priceLabel.isEmpty
                    ? null
                    : Text(
                        priceLabel,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? Colors.black : Colors.black54,
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

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.fieldFill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? Colors.black26 : Colors.black,
          ),
        ),
      ),
    );
  }
}

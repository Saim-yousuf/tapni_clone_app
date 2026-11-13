import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/catalog_item_options.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';

/// Manage shared modifier groups once — attach the same group to many items.
Future<List<CatalogOptionGroup>?> showCatalogModifierLibrarySheet({
  required BuildContext context,
  required List<CatalogOptionGroup> groups,
}) {
  return showAppModalBottomSheet<List<CatalogOptionGroup>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(BarqodyChrome.sheetRadius),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) => _CatalogModifierLibrarySheet(initial: groups),
  );
}

class _GroupEditors {
  final String id;
  final TextEditingController name;
  String selectionType;
  int minSelections;
  int maxSelections;
  final List<_OptionEditors> options;

  _GroupEditors({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  void dispose() {
    name.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class _OptionEditors {
  final String id;
  final TextEditingController name;
  final TextEditingController price;

  _OptionEditors({
    required this.id,
    required this.name,
    required this.price,
  });

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _CatalogModifierLibrarySheet extends StatefulWidget {
  final List<CatalogOptionGroup> initial;

  const _CatalogModifierLibrarySheet({required this.initial});

  @override
  State<_CatalogModifierLibrarySheet> createState() =>
      _CatalogModifierLibrarySheetState();
}

class _CatalogModifierLibrarySheetState
    extends State<_CatalogModifierLibrarySheet> {
  late List<_GroupEditors> _groups;

  @override
  void initState() {
    super.initState();
    _groups = widget.initial.map(_fromModel).toList();
  }

  _GroupEditors _fromModel(CatalogOptionGroup g) {
    return _GroupEditors(
      id: g.id.isNotEmpty ? g.id : newCatalogOptionId(),
      name: TextEditingController(text: g.name),
      selectionType: g.selectionType,
      minSelections: g.minSelections,
      maxSelections: g.maxSelections,
      options: g.options.isEmpty
          ? [_newOption()]
          : g.options
              .map(
                (o) => _OptionEditors(
                  id: o.id.isNotEmpty ? o.id : newCatalogOptionId(),
                  name: TextEditingController(text: o.name),
                  price: TextEditingController(
                    text: o.price > 0 ? o.price.toStringAsFixed(0) : '',
                  ),
                ),
              )
              .toList(),
    );
  }

  _GroupEditors _newGroup() => _GroupEditors(
        id: newCatalogOptionId(),
        name: TextEditingController(),
        selectionType: 'single',
        minSelections: 0,
        maxSelections: 1,
        options: [_newOption()],
      );

  _OptionEditors _newOption() => _OptionEditors(
        id: newCatalogOptionId(),
        name: TextEditingController(),
        price: TextEditingController(),
      );

  @override
  void dispose() {
    for (final g in _groups) {
      g.dispose();
    }
    super.dispose();
  }

  void _done() {
    FocusScope.of(context).unfocus();
    final out = <CatalogOptionGroup>[];
    for (var gi = 0; gi < _groups.length; gi++) {
      final g = _groups[gi];
      final name = g.name.text.trim();
      if (name.isEmpty) continue;
      final opts = <CatalogOption>[];
      for (var oi = 0; oi < g.options.length; oi++) {
        final o = g.options[oi];
        final on = o.name.text.trim();
        if (on.isEmpty) continue;
        opts.add(
          CatalogOption(
            id: o.id,
            name: on,
            price: double.tryParse(o.price.text.trim()) ?? 0,
            sortOrder: oi,
          ),
        );
      }
      if (opts.isEmpty) continue;
      final isMultiple = g.selectionType == 'multiple';
      var min = g.minSelections;
      var max = g.maxSelections;
      if (!isMultiple) {
        max = 1;
        if (min > 1) min = 1;
      } else {
        if (max < 1) max = opts.length;
        if (min > max) min = max;
        if (max > opts.length) max = opts.length;
      }
      out.add(
        CatalogOptionGroup(
          id: g.id,
          name: name,
          selectionType: isMultiple ? 'multiple' : 'single',
          minSelections: min < 0 ? 0 : min,
          maxSelections: max < 1 ? 1 : max,
          sortOrder: gi,
          options: opts,
        ),
      );
    }
    Navigator.pop(context, out);
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: AuthUi.fieldFill,
      hintStyle: WaUi.body.copyWith(
        fontSize: 14,
        color: BarqodyChrome.secondaryText,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Column(
            children: [
              SheetHandleThen(
                afterHandleGap: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Modifiers',
                          style: WaUi.toolsTitleOf(
                            size: 20,
                            weight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      CircleCloseButton(onTap: () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create toppings, sizes, or sauces once — then reuse them on any item.',
                    style: WaUi.body.copyWith(
                      fontSize: 13.5,
                      color: BarqodyChrome.bodyText,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _groups.isEmpty
                    ? _emptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        children: [
                          for (var gi = 0; gi < _groups.length; gi++) ...[
                            if (gi > 0) const SizedBox(height: 12),
                            _groupCard(gi),
                          ],
                          const SizedBox(height: 14),
                          _addGroupButton(),
                        ],
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                ),
                child: PillButton(
                  label: 'Save modifiers',
                  onPressed: _done,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: BarqodyChrome.fieldFill,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.tune_rounded, size: 28, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Text(
            'No modifiers yet',
            style: WaUi.toolsTitleOf(
              size: 17,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a group like Extra Toppings or Drink Size, then list the choices.',
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 13.5,
              color: BarqodyChrome.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _addGroupButton(),
        ],
      ),
    );
  }

  Widget _addGroupButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _groups.add(_newGroup())),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 1.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 20, color: Colors.black),
              SizedBox(width: 6),
              Text(
                'Add group',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupCard(int gi) {
    final g = _groups[gi];
    final isMultiple = g.selectionType == 'multiple';
    final isRequired = g.minSelections > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BarqodyChrome.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Group ${gi + 1}',
                  style: WaUi.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
              ),
              Material(
                color: BarqodyChrome.fieldFill,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() {
                      final removed = _groups.removeAt(gi);
                      removed.dispose();
                    });
                  },
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Image.asset(
                        'assets/images/png/trash-bin-icon.png',
                        width: 15,
                        height: 15,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.delete_outline,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: g.name,
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration(
              hint: 'Name (e.g. Extra Toppings)',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Customer can pick',
            style: WaUi.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'One',
                  selected: !isMultiple,
                  onTap: () {
                    setState(() {
                      g.selectionType = 'single';
                      g.maxSelections = 1;
                      if (g.minSelections > 1) g.minSelections = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  label: 'Several',
                  selected: isMultiple,
                  onTap: () {
                    setState(() {
                      g.selectionType = 'multiple';
                      g.maxSelections =
                          g.options.isNotEmpty ? g.options.length : 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  label: 'Required',
                  selected: isRequired,
                  onTap: () {
                    setState(
                      () => g.minSelections = isRequired ? 0 : 1,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Options',
            style: WaUi.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          for (var oi = 0; oi < g.options.length; oi++) ...[
            if (oi > 0) const SizedBox(height: 8),
            _optionRow(g, oi),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => g.options.add(_newOption()));
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add option',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(_GroupEditors g, int oi) {
    final o = g.options[oi];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: o.name,
            textCapitalization: TextCapitalization.sentences,
            decoration: _fieldDecoration(hint: 'Option name'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: TextField(
            controller: o.price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: _fieldDecoration(hint: '0', prefixText: '+ '),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() {
                  final removed = g.options.removeAt(oi);
                  removed.dispose();
                  if (g.options.isEmpty) {
                    g.options.add(_newOption());
                  }
                });
              },
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Image.asset(
                    'assets/images/png/trash-bin-icon.png',
                    width: 14,
                    height: 14,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.delete_outline,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
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

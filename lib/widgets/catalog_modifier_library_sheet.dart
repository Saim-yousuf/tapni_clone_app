import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item_options.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
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
    if (_groups.isEmpty) {
      _groups.add(_newGroup());
    }
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
                          'Modifier Groups',
                          style: WaUi.toolsTitleOf(
                            size: 18,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  'Create once (e.g. Toppings, Sauce). Then attach the same group on many menu items.',
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    color: BarqodyChrome.secondaryText,
                    height: 1.35,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    for (var gi = 0; gi < _groups.length; gi++) ...[
                      if (gi > 0) const SizedBox(height: 12),
                      _groupCard(gi),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _groups.add(_newGroup()));
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          'Add group',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAF9),
                  border: Border(top: BorderSide(color: Color(0xFFEEF0F2))),
                ),
                child: PillButton(
                  label: 'Done',
                  onPressed: _done,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: g.name,
                  decoration: const InputDecoration(
                    hintText: 'Group name (e.g. Toppings)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Remove group',
                onPressed: () {
                  setState(() {
                    final removed = _groups.removeAt(gi);
                    removed.dispose();
                  });
                },
                icon: Image.asset(
                  'assets/images/png/trash-bin-icon.png',
                  width: 16,
                  height: 16,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.delete_outline, size: 18),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                label: 'Single',
                selected: g.selectionType != 'multiple',
                onTap: () {
                  setState(() {
                    g.selectionType = 'single';
                    g.maxSelections = 1;
                    if (g.minSelections > 1) g.minSelections = 1;
                  });
                },
              ),
              _MiniChip(
                label: 'Multiple',
                selected: g.selectionType == 'multiple',
                onTap: () {
                  setState(() {
                    g.selectionType = 'multiple';
                    g.maxSelections =
                        g.options.isNotEmpty ? g.options.length : 1;
                  });
                },
              ),
              _MiniChip(
                label: 'Required',
                selected: g.minSelections > 0,
                onTap: () {
                  setState(
                    () => g.minSelections = g.minSelections > 0 ? 0 : 1,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var oi = 0; oi < g.options.length; oi++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: g.options[oi].name,
                      decoration: const InputDecoration(
                        hintText: 'Option',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: TextField(
                      controller: g.options[oi].price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: '+Price',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove option',
                    onPressed: () {
                      setState(() {
                        final removed = g.options.removeAt(oi);
                        removed.dispose();
                      });
                    },
                    icon: Image.asset(
                      'assets/images/png/trash-bin-icon.png',
                      width: 14,
                      height: 14,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.delete_outline, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() => g.options.add(_newOption()));
              },
              child: const Text(
                'Add option',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

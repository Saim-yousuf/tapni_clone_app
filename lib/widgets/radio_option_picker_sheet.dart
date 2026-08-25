import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class RadioPickerOption {
  final String id;
  final String label;
  final String? searchText;

  const RadioPickerOption({
    required this.id,
    required this.label,
    this.searchText,
  });
}

Future<String?> showRadioOptionPickerSheet({
  required BuildContext context,
  required List<RadioPickerOption> options,
  String? selectedId,
  required String searchHint,
  String? helperText,
  String? emptyText,
  bool closeOnSelect = false,
  Color? sheetColor,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (context) => RadioOptionPickerSheet(
      options: options,
      selectedId: selectedId,
      searchHint: searchHint,
      helperText: helperText,
      emptyText: emptyText,
      closeOnSelect: closeOnSelect,
      sheetColor: sheetColor,
    ),
  );
}

class RadioPickerField extends StatelessWidget {
  const RadioPickerField({
    super.key,
    required this.labelText,
    this.valueText,
    required this.onTap,
  });

  final String labelText;
  final String? valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = valueText != null && valueText!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
      child: InputDecorator(
        decoration: WaUi.fieldDecoration(
          labelText: labelText,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          hasValue ? valueText! : '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WaUi.body.copyWith(
            fontSize: 16,
            color: hasValue
                ? (isDark ? Colors.white : WaUi.primaryText)
                : WaUi.secondaryText,
          ),
        ),
      ),
    );
  }
}

class RadioOptionPickerSheet extends StatefulWidget {
  const RadioOptionPickerSheet({
    super.key,
    required this.options,
    this.selectedId,
    required this.searchHint,
    this.helperText,
    this.emptyText,
    this.closeOnSelect = false,
    this.sheetColor,
  });

  final List<RadioPickerOption> options;
  final String? selectedId;
  final String searchHint;
  final String? helperText;
  final String? emptyText;
  final bool closeOnSelect;
  final Color? sheetColor;

  @override
  State<RadioOptionPickerSheet> createState() => _RadioOptionPickerSheetState();
}

class _RadioOptionPickerSheetState extends State<RadioOptionPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedId;
  bool _gridView = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RadioPickerOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((option) {
      final haystack =
          '${option.label} ${option.searchText ?? ''}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = widget.sheetColor ??
        (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2));
    final searchFill = isDark && widget.sheetColor == null
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF1F5F9);
    final options = _filtered;
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final sheetHeight = media.size.height * 0.8;

    void selectOption(String id) {
      if (widget.closeOnSelect) {
        Navigator.pop(context, id);
        return;
      }
      setState(() => _selectedId = id);
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: sheetHeight,
        width: double.infinity,
        child: DecoratedBox(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark && widget.sheetColor == null
                    ? Colors.white24
                    : const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                style: WaUi.body.copyWith(fontSize: 16),
                cursorColor: AppTheme.primaryBlack,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: WaUi.body.copyWith(
                    color: WaUi.secondaryText,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: WaUi.secondaryText,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: searchFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (widget.helperText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.helperText!,
                        style: WaUi.caption.copyWith(
                          color: isDark && widget.sheetColor == null
                              ? Colors.white70
                              : const Color(0xFF3A3A3A),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _gridView = !_gridView),
                      icon: Icon(
                        _gridView ? Icons.view_list_outlined : Icons.grid_view,
                        size: 22,
                        color: isDark && widget.sheetColor == null
                            ? Colors.white70
                            : const Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => setState(() => _gridView = !_gridView),
                  icon: Icon(
                    _gridView ? Icons.view_list_outlined : Icons.grid_view,
                    size: 22,
                    color: isDark && widget.sheetColor == null
                        ? Colors.white70
                        : const Color(0xFF222222),
                  ),
                ),
              ),
            Expanded(
              child: options.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyText ?? context.l10n.noCountriesFound,
                        style: WaUi.caption,
                      ),
                    )
                  : _gridView
                      ? _buildGrid(options, isDark, selectOption)
                      : _buildList(options, isDark, selectOption),
            ),
            if (!widget.closeOnSelect)
              Container(
                color: sheetColor,
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: WaPrimaryButton(
                          label: context.l10n.cancel,
                          outlined: true,
                          foregroundColor: const Color(0xFF1B5E3B),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WaPrimaryButton(
                        label: context.l10n.save,
                        backgroundColor: Colors.black,
                        onPressed: _selectedId == null
                            ? null
                            : () => Navigator.pop(context, _selectedId),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(height: 8 + bottomInset),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<RadioPickerOption> options,
    bool isDark,
    ValueChanged<String> onSelect,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _OptionRadioRow(
          label: option.label,
          selected: option.id == _selectedId,
          isDark: isDark && widget.sheetColor == null,
          onTap: () => onSelect(option.id),
        );
      },
    );
  }

  Widget _buildGrid(
    List<RadioPickerOption> options,
    bool isDark,
    ValueChanged<String> onSelect,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 48,
        crossAxisSpacing: 8,
        mainAxisSpacing: 4,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _OptionRadioRow(
          label: option.label,
          selected: option.id == _selectedId,
          isDark: isDark && widget.sheetColor == null,
          compact: true,
          onTap: () => onSelect(option.id),
        );
      },
    );
  }
}

class _OptionRadioRow extends StatelessWidget {
  const _OptionRadioRow({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 12,
          vertical: compact ? 6 : 10,
        ),
        child: Row(
          children: [
            _RadioMark(selected: selected, isDark: isDark),
            SizedBox(width: compact ? 8 : 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.body.copyWith(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected, required this.isDark});

  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white54 : const Color(0xFF6B6B6B);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? (isDark ? Colors.white : Colors.black) : border,
          width: selected ? 6 : 1.6,
        ),
        color: selected ? Colors.white : Colors.transparent,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';

Future<CountryDialCode?> showCountryPickerSheet(
  BuildContext context, {
  String? selectedIso,
}) {
  return showAppModalBottomSheet<CountryDialCode>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CountryPickerSheet(selectedIso: selectedIso),
  );
}

class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, this.selectedIso});

  final String? selectedIso;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<CountryDialCode> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kCountryDialCodes;
    return kCountryDialCodes.where((country) {
      final haystack =
          '${country.name} ${country.code} ${country.iso}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  String? get _selectedIso => widget.selectedIso?.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final keyboard = media.viewInsets.bottom;
    final sheetHeight = media.size.height * 0.88;
    final countries = _filtered;
    final hasQuery = _query.trim().isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: Material(
            color: AuthUi.bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BarqodyChrome.sheetRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHandleThen(
                  afterHandleGap: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.chooseACountry,
                              style: WaUi.toolsTitleOf(
                                size: 20,
                                weight: FontWeight.w700,
                                color: AuthUi.textPrimary,
                                height: 1.1,
                              ),
                            ),
                          ),
                          CircleCloseButton(
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.l10n.selectCountryHelper,
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AuthUi.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      height: 1.2,
                      color: AuthUi.textPrimary,
                    ),
                    cursorColor: AuthUi.textPrimary,
                    cursorWidth: 1.5,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: BarqodyChrome.searchBg,
                      hintText: context.l10n.searchCountry,
                      hintStyle: WaUi.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: BarqodyChrome.secondaryText,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Image.asset(
                          'assets/images/png/search-icon.png',
                          width: 18,
                          height: 18,
                          color: BarqodyChrome.secondaryText,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.search,
                            size: 20,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 46,
                        minHeight: 48,
                      ),
                      suffixIcon: hasQuery
                          ? IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: BarqodyChrome.secondaryText,
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: countries.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.noCountriesFound,
                            style: WaUi.body.copyWith(
                              fontSize: 14,
                              color: AuthUi.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            4,
                            12,
                            16 + bottomInset,
                          ),
                          itemCount: countries.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 68,
                            endIndent: 12,
                            color: BarqodyChrome.divider,
                          ),
                          itemBuilder: (context, index) {
                            final country = countries[index];
                            final selected =
                                country.iso.toUpperCase() == _selectedIso;
                            return _CountryRow(
                              country: country,
                              selected: selected,
                              onTap: () => Navigator.pop(context, country),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final CountryDialCode country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AuthUi.textPrimary.withValues(alpha: 0.04)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(
                country.flagEmoji,
                style: const TextStyle(fontSize: 24, height: 1),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: AuthUi.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      country.code,
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AuthUi.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: AuthUi.textPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

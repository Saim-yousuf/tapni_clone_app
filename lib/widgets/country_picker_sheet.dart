import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/widgets/radio_option_picker_sheet.dart';

Future<CountryDialCode?> showCountryPickerSheet(
  BuildContext context, {
  String? selectedIso,
}) async {
  final selectedId = await showRadioOptionPickerSheet(
    context: context,
    options: [
      for (final country in kCountryDialCodes)
        RadioPickerOption(
          id: country.iso,
          label: country.name,
          searchText: '${country.code} ${country.iso}',
        ),
    ],
    selectedId: selectedIso,
    searchHint: context.l10n.searchCountry,
    helperText: context.l10n.selectCountryHelper,
    emptyText: context.l10n.noCountriesFound,
  );
  if (selectedId == null) return null;
  for (final country in kCountryDialCodes) {
    if (country.iso == selectedId) return country;
  }
  return null;
}

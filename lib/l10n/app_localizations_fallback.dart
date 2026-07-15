import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tapni_app/l10n/app_languages.dart';
import 'package:tapni_app/l10n/app_localizations.dart';

/// Loads generated [AppLocalizations] when an ARB exists; otherwise English.
///
/// Regional WhatsApp locales (e.g. `es_MX`, `ar_EG`, `en_US`) map to the
/// nearest translated base pack (`es`, `ar`, `en`, …).
class FallbackAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const FallbackAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    final candidates = <Locale>[
      locale,
      Locale(locale.languageCode),
      _mapToTranslatedLocale(locale),
      const Locale('en'),
    ];

    for (final candidate in candidates) {
      if (AppLocalizations.delegate.isSupported(candidate)) {
        return AppLocalizations.delegate.load(candidate);
      }
    }
    return AppLocalizations.delegate.load(const Locale('en'));
  }

  Locale _mapToTranslatedLocale(Locale locale) {
    final tag =
        '${locale.languageCode}${locale.countryCode != null && locale.countryCode!.isNotEmpty ? '_${locale.countryCode}' : ''}';

    // Explicit packs / closest equivalents
    const exact = <String, String>{
      'zh_CN': 'zh_CN',
      'zh_HK': 'zh_HK',
      'zh_TW': 'zh_TW',
      'pt_BR': 'pt_BR',
      'pt_PT': 'pt_PT',
      'be_BY': 'be_BY',
      'si_LK': 'si_LK',
      'ps_AF': 'ps_AF',
      'prs_AF': 'fa', // Dari uses Persian pack
      'rw_RW': 'rw_RW',
      'ky_KG': 'ky_KG',
      'nb': 'nb',
      'fil': 'fil',
    };
    if (exact.containsKey(tag)) {
      return _localeFromTag(exact[tag]!);
    }

    switch (locale.languageCode) {
      case 'en':
        return const Locale('en');
      case 'ar':
        return const Locale('ar');
      case 'es':
        return const Locale('es');
      case 'fr':
        return const Locale('fr');
      case 'de':
        return const Locale('de');
      case 'nl':
        return const Locale('nl');
      case 'bn':
        return const Locale('bn');
      case 'pt':
        return const Locale('pt', 'BR');
      case 'zh':
        return const Locale('zh', 'CN');
      case 'ur':
        return const Locale('ur');
      case 'hi':
        return const Locale('hi');
      case 'fa':
        return const Locale('fa');
      case 'id':
        return const Locale('id');
      case 'tr':
        return const Locale('tr');
      case 'ru':
        return const Locale('ru');
      case 'it':
        return const Locale('it');
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      default:
        return Locale(locale.languageCode);
    }
  }

  Locale _localeFromTag(String tag) {
    final parts = tag.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class AppLocalizationSetup {
  AppLocalizationSetup._();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    FallbackAppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static List<Locale> get supportedLocales => AppLanguages.supportedLocales;

  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) return const Locale('en');
    final match = AppLanguages.resolveClosest(locale);
    return match?.locale ?? const Locale('en');
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

import 'package:flutter/material.dart';

/// WhatsApp Business Platform template languages (Meta supported list).
/// https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/supported-languages/
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  /// Locale tag used as SharedPreferences value (e.g. `en`, `pt_BR`, `zh_CN`).
  final String code;
  final String englishName;
  final String nativeName;

  Locale get locale {
    final parts = code.split('_');
    if (parts.length == 1) {
      return Locale(parts[0]);
    }
    return Locale(parts[0], parts[1]);
  }

  String get displayName =>
      nativeName == englishName ? englishName : '$nativeName ($englishName)';
}

class AppLanguages {
  AppLanguages._();

  /// Sentinel for "follow phone language".
  static const String systemCode = 'system';

  /// Locales with real translation packs under `lib/l10n` (see tool/translate_all_arbs.py).
  /// Regional WhatsApp variants (es_MX, ar_EG, …) resolve via [isImplemented].
  static const Set<String> implementedCodes = {
    'en',
    'af',
    'sq',
    'ar',
    'az',
    'be_BY',
    'bn',
    'bg',
    'ca',
    'zh_CN',
    'zh_HK',
    'zh_TW',
    'hr',
    'cs',
    'da',
    'prs_AF', // uses Persian (fa) pack via FallbackAppLocalizationsDelegate
    'nl',
    'et',
    'fil',
    'fi',
    'fr',
    'ka',
    'de',
    'el',
    'gu',
    'ha',
    'he',
    'hi',
    'hu',
    'id',
    'ga',
    'it',
    'ja',
    'kn',
    'kk',
    'rw_RW',
    'ko',
    'ky_KG',
    'lo',
    'lv',
    'lt',
    'mk',
    'ms',
    'ml',
    'mr',
    'nb',
    'ps_AF',
    'fa',
    'pl',
    'pt_BR',
    'pt_PT',
    'pa',
    'ro',
    'ru',
    'sr',
    'si_LK',
    'sk',
    'sl',
    'es',
    'sw',
    'sv',
    'ta',
    'te',
    'th',
    'tr',
    'uk',
    'ur',
    'uz',
    'vi',
    'zu',
  };

  /// Languages shown in the App Language picker (full WhatsApp list).
  static List<AppLanguage> get selectable => all;

  static bool isImplemented(String? code) {
    if (code == null || code.isEmpty || code == systemCode) return true;
    final language = findByCode(code);
    if (language == null) return false;
    if (implementedCodes.contains(language.code)) return true;
    // Regional variants of an implemented base language (e.g. es_MX → es).
    return implementedCodes.contains(language.locale.languageCode);
  }

  static const List<AppLanguage> all = [
    AppLanguage(code: 'af', englishName: 'Afrikaans', nativeName: 'Afrikaans'),
    AppLanguage(code: 'sq', englishName: 'Albanian', nativeName: 'Shqip'),
    AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
    AppLanguage(code: 'ar_EG', englishName: 'Arabic (Egypt)', nativeName: 'العربية (مصر)'),
    AppLanguage(code: 'ar_AE', englishName: 'Arabic (UAE)', nativeName: 'العربية (الإمارات)'),
    AppLanguage(code: 'ar_LB', englishName: 'Arabic (Lebanon)', nativeName: 'العربية (لبنان)'),
    AppLanguage(code: 'ar_MA', englishName: 'Arabic (Morocco)', nativeName: 'العربية (المغرب)'),
    AppLanguage(code: 'ar_QA', englishName: 'Arabic (Qatar)', nativeName: 'العربية (قطر)'),
    AppLanguage(code: 'az', englishName: 'Azerbaijani', nativeName: 'Azərbaycan'),
    AppLanguage(code: 'be_BY', englishName: 'Belarusian', nativeName: 'Беларуская'),
    AppLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা'),
    AppLanguage(code: 'bn_IN', englishName: 'Bengali (India)', nativeName: 'বাংলা (ভারত)'),
    AppLanguage(code: 'bg', englishName: 'Bulgarian', nativeName: 'Български'),
    AppLanguage(code: 'ca', englishName: 'Catalan', nativeName: 'Català'),
    AppLanguage(code: 'zh_CN', englishName: 'Chinese (China)', nativeName: '中文 (简体)'),
    AppLanguage(code: 'zh_HK', englishName: 'Chinese (Hong Kong)', nativeName: '中文 (香港)'),
    AppLanguage(code: 'zh_TW', englishName: 'Chinese (Taiwan)', nativeName: '中文 (繁體)'),
    AppLanguage(code: 'hr', englishName: 'Croatian', nativeName: 'Hrvatski'),
    AppLanguage(code: 'cs', englishName: 'Czech', nativeName: 'Čeština'),
    AppLanguage(code: 'da', englishName: 'Danish', nativeName: 'Dansk'),
    AppLanguage(code: 'prs_AF', englishName: 'Dari', nativeName: 'دری'),
    AppLanguage(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands'),
    AppLanguage(code: 'nl_BE', englishName: 'Dutch (Belgium)', nativeName: 'Nederlands (België)'),
    AppLanguage(code: 'en', englishName: 'English', nativeName: 'English'),
    AppLanguage(code: 'en_GB', englishName: 'English (UK)', nativeName: 'English (UK)'),
    AppLanguage(code: 'en_US', englishName: 'English (US)', nativeName: 'English (US)'),
    AppLanguage(code: 'en_AE', englishName: 'English (UAE)', nativeName: 'English (UAE)'),
    AppLanguage(code: 'en_AU', englishName: 'English (Australia)', nativeName: 'English (Australia)'),
    AppLanguage(code: 'en_CA', englishName: 'English (Canada)', nativeName: 'English (Canada)'),
    AppLanguage(code: 'en_GH', englishName: 'English (Ghana)', nativeName: 'English (Ghana)'),
    AppLanguage(code: 'en_IE', englishName: 'English (Ireland)', nativeName: 'English (Ireland)'),
    AppLanguage(code: 'en_IN', englishName: 'English (India)', nativeName: 'English (India)'),
    AppLanguage(code: 'en_JM', englishName: 'English (Jamaica)', nativeName: 'English (Jamaica)'),
    AppLanguage(code: 'en_MY', englishName: 'English (Malaysia)', nativeName: 'English (Malaysia)'),
    AppLanguage(code: 'en_NZ', englishName: 'English (New Zealand)', nativeName: 'English (New Zealand)'),
    AppLanguage(code: 'en_QA', englishName: 'English (Qatar)', nativeName: 'English (Qatar)'),
    AppLanguage(code: 'en_SG', englishName: 'English (Singapore)', nativeName: 'English (Singapore)'),
    AppLanguage(code: 'en_UG', englishName: 'English (Uganda)', nativeName: 'English (Uganda)'),
    AppLanguage(code: 'en_ZA', englishName: 'English (South Africa)', nativeName: 'English (South Africa)'),
    AppLanguage(code: 'et', englishName: 'Estonian', nativeName: 'Eesti'),
    AppLanguage(code: 'fil', englishName: 'Filipino', nativeName: 'Filipino'),
    AppLanguage(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi'),
    AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français'),
    AppLanguage(code: 'fr_BE', englishName: 'French (Belgium)', nativeName: 'Français (Belgique)'),
    AppLanguage(code: 'fr_CA', englishName: 'French (Canada)', nativeName: 'Français (Canada)'),
    AppLanguage(code: 'fr_CH', englishName: 'French (Switzerland)', nativeName: 'Français (Suisse)'),
    AppLanguage(code: 'fr_CI', englishName: 'French (Ivory Coast)', nativeName: 'Français (Côte d’Ivoire)'),
    AppLanguage(code: 'fr_MA', englishName: 'French (Morocco)', nativeName: 'Français (Maroc)'),
    AppLanguage(code: 'ka', englishName: 'Georgian', nativeName: 'ქართული'),
    AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
    AppLanguage(code: 'de_AT', englishName: 'German (Austria)', nativeName: 'Deutsch (Österreich)'),
    AppLanguage(code: 'de_CH', englishName: 'German (Switzerland)', nativeName: 'Deutsch (Schweiz)'),
    AppLanguage(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά'),
    AppLanguage(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી'),
    AppLanguage(code: 'ha', englishName: 'Hausa', nativeName: 'Hausa'),
    AppLanguage(code: 'he', englishName: 'Hebrew', nativeName: 'עברית'),
    AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
    AppLanguage(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar'),
    AppLanguage(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia'),
    AppLanguage(code: 'ga', englishName: 'Irish', nativeName: 'Gaeilge'),
    AppLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano'),
    AppLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
    AppLanguage(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    AppLanguage(code: 'kk', englishName: 'Kazakh', nativeName: 'Қазақ'),
    AppLanguage(code: 'rw_RW', englishName: 'Kinyarwanda', nativeName: 'Ikinyarwanda'),
    AppLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
    AppLanguage(code: 'ky_KG', englishName: 'Kyrgyz', nativeName: 'Кыргызча'),
    AppLanguage(code: 'lo', englishName: 'Lao', nativeName: 'ລາວ'),
    AppLanguage(code: 'lv', englishName: 'Latvian', nativeName: 'Latviešu'),
    AppLanguage(code: 'lt', englishName: 'Lithuanian', nativeName: 'Lietuvių'),
    AppLanguage(code: 'mk', englishName: 'Macedonian', nativeName: 'Македонски'),
    AppLanguage(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu'),
    AppLanguage(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം'),
    AppLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
    AppLanguage(code: 'nb', englishName: 'Norwegian', nativeName: 'Norsk bokmål'),
    AppLanguage(code: 'ps_AF', englishName: 'Pashto', nativeName: 'پښتو'),
    AppLanguage(code: 'fa', englishName: 'Persian', nativeName: 'فارسی'),
    AppLanguage(code: 'pl', englishName: 'Polish', nativeName: 'Polski'),
    AppLanguage(code: 'pt_BR', englishName: 'Portuguese (Brazil)', nativeName: 'Português (Brasil)'),
    AppLanguage(code: 'pt_PT', englishName: 'Portuguese (Portugal)', nativeName: 'Português (Portugal)'),
    AppLanguage(code: 'pa', englishName: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    AppLanguage(code: 'ro', englishName: 'Romanian', nativeName: 'Română'),
    AppLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский'),
    AppLanguage(code: 'sr', englishName: 'Serbian', nativeName: 'Српски'),
    AppLanguage(code: 'si_LK', englishName: 'Sinhala', nativeName: 'සිංහල'),
    AppLanguage(code: 'sk', englishName: 'Slovak', nativeName: 'Slovenčina'),
    AppLanguage(code: 'sl', englishName: 'Slovenian', nativeName: 'Slovenščina'),
    AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
    AppLanguage(code: 'es_AR', englishName: 'Spanish (Argentina)', nativeName: 'Español (Argentina)'),
    AppLanguage(code: 'es_CL', englishName: 'Spanish (Chile)', nativeName: 'Español (Chile)'),
    AppLanguage(code: 'es_CO', englishName: 'Spanish (Colombia)', nativeName: 'Español (Colombia)'),
    AppLanguage(code: 'es_CR', englishName: 'Spanish (Costa Rica)', nativeName: 'Español (Costa Rica)'),
    AppLanguage(code: 'es_DO', englishName: 'Spanish (Dominican Republic)', nativeName: 'Español (República Dominicana)'),
    AppLanguage(code: 'es_EC', englishName: 'Spanish (Ecuador)', nativeName: 'Español (Ecuador)'),
    AppLanguage(code: 'es_HN', englishName: 'Spanish (Honduras)', nativeName: 'Español (Honduras)'),
    AppLanguage(code: 'es_MX', englishName: 'Spanish (Mexico)', nativeName: 'Español (México)'),
    AppLanguage(code: 'es_PA', englishName: 'Spanish (Panama)', nativeName: 'Español (Panamá)'),
    AppLanguage(code: 'es_PE', englishName: 'Spanish (Peru)', nativeName: 'Español (Perú)'),
    AppLanguage(code: 'es_ES', englishName: 'Spanish (Spain)', nativeName: 'Español (España)'),
    AppLanguage(code: 'es_UY', englishName: 'Spanish (Uruguay)', nativeName: 'Español (Uruguay)'),
    AppLanguage(code: 'sw', englishName: 'Swahili', nativeName: 'Kiswahili'),
    AppLanguage(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska'),
    AppLanguage(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்'),
    AppLanguage(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు'),
    AppLanguage(code: 'th', englishName: 'Thai', nativeName: 'ไทย'),
    AppLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe'),
    AppLanguage(code: 'uk', englishName: 'Ukrainian', nativeName: 'Українська'),
    AppLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو'),
    AppLanguage(code: 'uz', englishName: 'Uzbek', nativeName: 'Oʻzbek'),
    AppLanguage(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt'),
    AppLanguage(code: 'zu', englishName: 'Zulu', nativeName: 'isiZulu'),
  ];

  static List<Locale> get supportedLocales =>
      all.map((language) => language.locale).toList(growable: false);

  static AppLanguage? findByCode(String? code) {
    if (code == null || code.isEmpty || code == systemCode) return null;
    for (final language in all) {
      if (language.code == code) return language;
    }
    return null;
  }

  static AppLanguage? resolveClosest(Locale locale) {
    final exact = '${locale.languageCode}${locale.countryCode != null && locale.countryCode!.isNotEmpty ? '_${locale.countryCode}' : ''}';
    final byExact = findByCode(exact);
    if (byExact != null) return byExact;

    for (final language in all) {
      if (language.locale.languageCode == locale.languageCode &&
          language.locale.countryCode == null) {
        return language;
      }
    }
    for (final language in all) {
      if (language.locale.languageCode == locale.languageCode) {
        return language;
      }
    }
    return findByCode('en');
  }
}

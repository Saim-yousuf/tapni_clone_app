import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_languages.dart';
import 'package:tapni_app/utils/preference_helper.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _loadSavedLanguage();
  }

  static const String _prefsKey = 'app_language';

  /// `system` or a WhatsApp language code like `ur`, `pt_BR`.
  String _languageCode = AppLanguages.systemCode;

  String get languageCode => _languageCode;

  bool get isSystemLanguage => _languageCode == AppLanguages.systemCode;

  AppLanguage? get selectedLanguage => AppLanguages.findByCode(_languageCode);

  /// `null` means follow the device locale (WhatsApp "Phone's language").
  Locale? get locale {
    if (isSystemLanguage) return null;
    return selectedLanguage?.locale ?? const Locale('en');
  }

  String get displayLabel {
    if (isSystemLanguage) return AppLanguages.systemCode;
    return selectedLanguage?.nativeName ?? 'English';
  }

  Future<void> _loadSavedLanguage() async {
    final saved = SharedPrefHelper.getString(_prefsKey);
    if (saved.isEmpty || saved == AppLanguages.systemCode) {
      _languageCode = AppLanguages.systemCode;
    } else if (AppLanguages.isImplemented(saved)) {
      _languageCode = saved;
    } else {
      // Previously selected stub locale (English-only ARB) — reset so UI is honest.
      _languageCode = AppLanguages.systemCode;
      await SharedPrefHelper.putString(_prefsKey, AppLanguages.systemCode);
    }
    notifyListeners();
  }

  Future<void> useSystemLanguage() async {
    _languageCode = AppLanguages.systemCode;
    await SharedPrefHelper.putString(_prefsKey, AppLanguages.systemCode);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (!AppLanguages.isImplemented(language.code)) return;
    _languageCode = language.code;
    await SharedPrefHelper.putString(_prefsKey, language.code);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (code == AppLanguages.systemCode) {
      await useSystemLanguage();
      return;
    }
    final language = AppLanguages.findByCode(code);
    if (language == null || !AppLanguages.isImplemented(language.code)) return;
    await setLanguage(language);
  }
}

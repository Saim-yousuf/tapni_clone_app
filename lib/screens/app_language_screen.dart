import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_languages.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class AppLanguageScreen extends StatefulWidget {
  const AppLanguageScreen({super.key});

  @override
  State<AppLanguageScreen> createState() => _AppLanguageScreenState();
}

class _AppLanguageScreenState extends State<AppLanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguage> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return AppLanguages.selectable;
    return AppLanguages.selectable.where((lang) {
      return lang.englishName.toLowerCase().contains(q) ||
          lang.nativeName.toLowerCase().contains(q) ||
          lang.code.toLowerCase().contains(q);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _selectSystem(LocaleProvider provider) async {
    await provider.useSystemLanguage();
    if (!mounted) return;
    _showUpdatedSnack();
  }

  Future<void> _selectLanguage(
    LocaleProvider provider,
    AppLanguage language,
  ) async {
    await provider.setLanguage(language);
    if (!mounted) return;
    _showUpdatedSnack();
  }

  void _showUpdatedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.languageUpdated,
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WaUi.primaryText,
      ),
    );
  }

  String _selectedLabel(LocaleProvider provider) {
    if (provider.isSystemLanguage) return context.l10n.phoneLanguage;
    return provider.selectedLanguage?.englishName ??
        provider.selectedLanguage?.displayName ??
        context.l10n.phoneLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final languages = _filtered;
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Text(
                      context.l10n.appLanguage,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _LanguageSearchField(
                controller: _searchController,
                hintText: context.l10n.searchLanguage,
                onChanged: (value) => setState(() => _query = value),
                onClear: _clearSearch,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  if (!searching) ...[
                    Text(
                      'Choose the language',
                      style: WaUi.toolsTitleOf(
                        size: 26,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select you preferred language below. This help us serve your better.',
                      style: WaUi.body.copyWith(
                        fontSize: 14,
                        color: BarqodyChrome.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'You Selected',
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LanguageOption(
                      title: _selectedLabel(provider),
                      selected: true,
                      bordered: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'App Languages',
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LanguageOption(
                      title: context.l10n.phoneLanguage,
                      selected: provider.isSystemLanguage,
                      bordered: provider.isSystemLanguage,
                      onTap: () => _selectSystem(provider),
                    ),
                  ],
                  ...languages.map((lang) {
                    final selected = !provider.isSystemLanguage &&
                        provider.languageCode == lang.code;
                    return _LanguageOption(
                      title: lang.englishName,
                      selected: selected,
                      bordered: selected,
                      onTap: () => _selectLanguage(provider, lang),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _LanguageSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: WaUi.body.copyWith(fontSize: 15, color: Colors.black),
        cursorColor: Colors.black,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: BarqodyChrome.searchBg,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: BarqodyChrome.secondaryText,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 6),
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
            minWidth: 42,
            minHeight: 44,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: BarqodyChrome.secondaryText,
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool selected;
  final bool bordered;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.selected,
    required this.bordered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: bordered ? 16 : 4,
        vertical: bordered ? 14 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: WaUi.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          if (selected)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/png/check-icon.png',
                width: 11,
                height: 11,
                color: Colors.white,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: bordered
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}

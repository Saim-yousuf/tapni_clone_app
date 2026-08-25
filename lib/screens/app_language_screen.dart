import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_languages.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final languages = _filtered;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        title: Text(context.l10n.appLanguage),
      ),
      body: Column(
        children: [
          WaChatSearchBar(
            controller: _searchController,
            hintText: context.l10n.searchLanguage,
            onChanged: (value) => setState(() => _query = value),
            onClear: _clearSearch,
          ),
          Expanded(
            child: ListView(
              children: [
                if (_query.trim().isEmpty) ...[
                  _LanguageTile(
                    title: context.l10n.phoneLanguage,
                    subtitle: null,
                    selected: provider.isSystemLanguage,
                    onTap: () => _selectSystem(provider),
                  ),
                  Divider(height: 1, color: WaUi.divider),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      context.l10n.appLanguage,
                      style: WaUi.sectionHeader,
                    ),
                  ),
                ],
                ...languages.map(
                  (lang) => _LanguageTile(
                    title: lang.nativeName,
                    subtitle: lang.englishName == lang.nativeName
                        ? null
                        : lang.englishName,
                    selected: !provider.isSystemLanguage &&
                        provider.languageCode == lang.code,
                    onTap: () => _selectLanguage(provider, lang),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(title, style: WaUi.listTitle),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: WaUi.caption.copyWith(color: WaUi.secondaryText),
            ),
      trailing: selected
          ? const Icon(Icons.check, color: WaUi.accent)
          : null,
    );
  }
}

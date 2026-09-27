import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_topic_screen.dart';
import 'package:tapni_app/screens/help/help_ui.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  bool _searchUi = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (!_searchFocus.hasFocus && _query.trim().isEmpty && _searchUi) {
      setState(() => _searchUi = false);
    }
  }

  Future<void> _contactUs() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@barqody.com',
      query: 'subject=${Uri.encodeComponent('Barqody Help')}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !mounted) return;
    } catch (_) {
      // Fall through to snackbar.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Email: support@barqody.com',
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        backgroundColor: WaUi.buttonDark,
      ),
    );
  }

  void _openSearchUi() {
    setState(() => _searchUi = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _searchUi = false;
    });
    _searchFocus.unfocus();
  }

  void _onBack() {
    if (_searchUi || _query.trim().isNotEmpty) {
      _clearSearch();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _homeContent({required List<HelpTopic> topics}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How We Can Help You?',
          style: WaUi.toolsTitleOf(
            size: 26,
            weight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Let us know what category or artist you were searching for. Your suggestion help us bring in more relevant talent.',
          style: WaUi.body.copyWith(
            fontSize: 14,
            color: HelpUi.secondaryText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        const HelpSectionTitle('Help Topics', fontSize: 18),
        const SizedBox(height: 12),
        HelpTopicListCard(
          topics: topics,
          onTap: (topic) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HelpTopicScreen(topic: topic),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const HelpSectionTitle('Popular articles', fontSize: 18),
        const SizedBox(height: 12),
        HelpArticleAccordion(
          articles: HelpCenterCatalog.popularArticles,
          expandFirst: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = HelpCenterCatalog.search(_query);
    final articleHits = HelpCenterCatalog.searchArticles(_query);
    final searching = _query.trim().isNotEmpty;
    final noResults = searching && articleHits.isEmpty && topics.isEmpty;
    final showSearchHeader = _searchUi || searching;

    return Scaffold(
      backgroundColor: HelpUi.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: showSearchHeader
                  ? Row(
                      children: [
                        HelpCircleBackButton(onTap: _onBack),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HelpSearchField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            autofocus: true,
                            onChanged: (v) => setState(() => _query = v),
                            onClear: _clearSearch,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        HelpCircleBackButton(onTap: _onBack),
                        Expanded(
                          child: Text(
                            'Help Center',
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
            Expanded(
              child: noResults
                  ? const HelpEmptySearch()
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        HelpUi.sidePad,
                        showSearchHeader ? 20 : 16,
                        HelpUi.sidePad,
                        showSearchHeader ? 28 : 12,
                      ),
                      children: [
                        if (!showSearchHeader) ...[
                          _SearchBarTapTarget(onTap: _openSearchUi),
                          const SizedBox(height: 28),
                          _homeContent(topics: topics),
                        ] else if (!searching) ...[
                          _homeContent(topics: topics),
                        ] else if (articleHits.isNotEmpty) ...[
                          HelpArticleAccordion(
                            articles: articleHits,
                            expandFirst: true,
                          ),
                        ] else ...[
                          const HelpSectionTitle('Help Topics', fontSize: 18),
                          const SizedBox(height: 12),
                          HelpTopicListCard(
                            topics: topics,
                            onTap: (topic) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HelpTopicScreen(topic: topic),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            if (!showSearchHeader) HelpContactUsBar(onPressed: _contactUs),
          ],
        ),
      ),
    );
  }
}

/// Decorative search bar on the home layout; opens the real search field.
class _SearchBarTapTarget extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBarTapTarget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: HelpUi.searchBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, size: 20, color: HelpUi.secondaryText),
            SizedBox(width: 8),
            Text(
              'Search Help Center',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: HelpUi.secondaryText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

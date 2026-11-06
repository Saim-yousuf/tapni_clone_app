import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_topic_screen.dart';
import 'package:tapni_app/screens/help/help_ui.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tapni_app/widgets/app_toast.dart';

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
    showAppToast(
          context,
          'Email: support@barqody.com',
          kind: AppToastKind.info,
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

  void _openTopic(HelpTopic topic) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => HelpTopicScreen(topic: topic),
      ),
    );
  }

  Widget _homeContent({
    required AuthScale m,
    required List<HelpTopic> topics,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How We Can Help You?',
          style: WaUi.toolsTitleOf(
            size: HelpUi.font(m, HelpUi.heroSize, min: 20),
            weight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: m.v(12)),
        Text(
          'Let us know what category or artist you were searching for. Your suggestion help us bring in more relevant talent.',
          style: WaUi.body.copyWith(
            fontSize: HelpUi.font(m, HelpUi.subtitleSize, min: 12),
            fontWeight: FontWeight.w600,
            color: HelpUi.mutedText,
            height: 1.4,
          ),
        ),
        SizedBox(height: m.v(28)),
        const HelpSectionTitle('Help Topics'),
        SizedBox(height: m.v(12)),
        HelpTopicListCard(
          topics: topics,
          onTap: _openTopic,
        ),
        SizedBox(height: m.v(24)),
        const HelpSectionTitle('Popular articles'),
        SizedBox(height: m.v(12)),
        HelpArticleAccordion(
          articles: HelpCenterCatalog.popularArticles,
          expandFirst: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
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
            if (showSearchHeader)
              Padding(
                padding: HelpUi.headerPad(m),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      CircleBackButton(onTap: _onBack),
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
                  ),
                ),
              )
            else
              BarqodyTitleBar(
                title: 'Help Center',
                onBack: _onBack,
              ),
            Expanded(
              child: noResults
                  ? const HelpEmptySearch()
                  : ListView(
                      padding: HelpUi.pagePad(
                        m,
                        top: showSearchHeader ? 20 : 0,
                        bottom: showSearchHeader ? 28 : 12,
                      ),
                      children: [
                        if (!showSearchHeader) ...[
                          HelpSearchBarTapTarget(onTap: _openSearchUi),
                          SizedBox(height: m.v(24)),
                          _homeContent(m: m, topics: topics),
                        ] else if (!searching) ...[
                          _homeContent(m: m, topics: topics),
                        ] else if (articleHits.isNotEmpty) ...[
                          HelpArticleAccordion(
                            articles: articleHits,
                            expandFirst: true,
                          ),
                        ] else ...[
                          const HelpSectionTitle('Help Topics'),
                          SizedBox(height: m.v(12)),
                          HelpTopicListCard(
                            topics: topics,
                            onTap: _openTopic,
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

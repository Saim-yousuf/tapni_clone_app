import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_article_screen.dart';
import 'package:tapni_app/screens/help/help_topic_screen.dart';
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
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final topics = HelpCenterCatalog.search(_query);
    final articleHits = HelpCenterCatalog.searchArticles(_query);
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Help Center'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactUs,
        backgroundColor: WaUi.buttonDark,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
        label: Text('Contact us', style: WaUi.promoButton),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF0F2F5),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: WaUi.buttonDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'How can we help?',
                  style: WaUi.toolsTitleOf(
                    size: 24,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: WaUi.body.copyWith(fontSize: 16, height: 1.2),
                    cursorColor: WaUi.accent,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search Help Center',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF667781),
                        height: 1.2,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 8),
                        child: Icon(
                          Icons.search,
                          size: 22,
                          color: Color(0xFF667781),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 48,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: const Color(0xFF667781),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
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
                        vertical: 14,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (searching && articleHits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                'Search results',
                style: WaUi.label.copyWith(
                  color: WaUi.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...articleHits.map(
              (a) => _ArticleTile(
                title: a.title,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelpArticleScreen(article: a),
                  ),
                ),
              ),
            ),
          ] else if (searching && topics.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
              child: Text(
                'No results found',
                textAlign: TextAlign.center,
                style: WaUi.bodyMedium,
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'Help topics',
                style: WaUi.label.copyWith(
                  color: WaUi.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...topics.map(
              (topic) => _TopicTile(
                icon: topic.icon,
                title: topic.title,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelpTopicScreen(topic: topic),
                  ),
                ),
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: 8),
              Container(height: 8, color: const Color(0xFFF0F2F5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Popular articles',
                  style: WaUi.label.copyWith(
                    color: WaUi.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...HelpCenterCatalog.popularArticles.map(
                (a) => _ArticleTile(
                  title: a.title,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpArticleScreen(article: a),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _TopicTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24, color: WaUi.buttonDark),
            const SizedBox(width: 18),
            Expanded(
              child: Text(title, style: WaUi.listTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ArticleTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(
              Icons.article_outlined,
              size: 22,
              color: WaUi.secondaryText.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(title, style: WaUi.body),
            ),
          ],
        ),
      ),
    );
  }
}

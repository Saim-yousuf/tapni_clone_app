import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_article_screen.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class HelpTopicScreen extends StatelessWidget {
  final HelpTopic topic;

  const HelpTopicScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: WaUi.buttonDark,
        titleSpacing: 0,
        title: Text(
          'Help Center',
          style: WaUi.toolsTitle.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Icon(topic.icon, size: 26, color: WaUi.buttonDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topic.title,
                    style: WaUi.headline.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ...topic.articles.map(
            (article) => InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelpArticleScreen(article: article),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                child: Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 22,
                      color: WaUi.secondaryText.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(article.title, style: WaUi.body),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          ...HelpCenterCatalog.popularArticles.take(4).map(
                (a) => InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpArticleScreen(article: a),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 22,
                          color: WaUi.secondaryText.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(a.title, style: WaUi.body),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

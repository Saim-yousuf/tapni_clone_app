import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_ui.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class HelpTopicScreen extends StatelessWidget {
  final HelpTopic topic;

  const HelpTopicScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final popular = HelpCenterCatalog.popularArticles.take(4).toList();

    return Scaffold(
      backgroundColor: HelpUi.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Help Center'),
            Expanded(
              child: ListView(
                padding: HelpUi.pagePad(m, top: 0, bottom: 32),
                children: [
                  HelpSectionTitle(
                    topic.title,
                    fontSize: HelpUi.heroSize,
                    weight: FontWeight.w600,
                  ),
                  SizedBox(height: m.v(16)),
                  HelpArticleAccordion(
                    articles: topic.articles,
                    expandFirst: true,
                  ),
                  SizedBox(height: m.v(24)),
                  const HelpSectionTitle('Popular articles'),
                  SizedBox(height: m.v(12)),
                  HelpArticleAccordion(
                    articles: popular,
                    expandFirst: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

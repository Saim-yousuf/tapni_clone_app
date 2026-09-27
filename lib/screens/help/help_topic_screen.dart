import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_ui.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class HelpTopicScreen extends StatelessWidget {
  final HelpTopic topic;

  const HelpTopicScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final popular = HelpCenterCatalog.popularArticles.take(4).toList();

    return Scaffold(
      backgroundColor: HelpUi.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const HelpCircleBackButton(),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  HelpUi.sidePad,
                  24,
                  HelpUi.sidePad,
                  32,
                ),
                children: [
                  HelpSectionTitle(topic.title, fontSize: 26),
                  const SizedBox(height: 16),
                  HelpArticleAccordion(
                    articles: topic.articles,
                    expandFirst: true,
                  ),
                  const SizedBox(height: 28),
                  const HelpSectionTitle('Popular articles', fontSize: 18),
                  const SizedBox(height: 12),
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

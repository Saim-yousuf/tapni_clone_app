import 'package:flutter/material.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class HelpArticleScreen extends StatelessWidget {
  final HelpArticle article;

  const HelpArticleScreen({super.key, required this.article});

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
          style: WaUi.toolsTitleOf(weight: FontWeight.w500, size: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            article.title,
            style: WaUi.headline.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.body,
            style: WaUi.body.copyWith(
              height: 1.5,
              fontSize: 15,
              color: WaUi.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

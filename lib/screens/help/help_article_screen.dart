import 'package:flutter/material.dart';
import 'package:tapni_app/screens/help/help_ui.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

class HelpArticleScreen extends StatelessWidget {
  final HelpArticle article;

  const HelpArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Scaffold(
      backgroundColor: HelpUi.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: HelpUi.headerPad(m),
              child: Row(
                children: [
                  const HelpCircleBackButton(),
                  Expanded(
                    child: Text(
                      'Help Center',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: HelpUi.font(m, 18, min: 16),
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
                padding: HelpUi.pagePad(m, top: 24, bottom: 32),
                children: [
                  Text(
                    article.title,
                    style: WaUi.toolsTitleOf(
                      size: HelpUi.font(m, 22, min: 18),
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: m.v(16)),
                  Text(
                    article.body,
                    style: WaUi.body.copyWith(
                      height: 1.5,
                      fontSize: HelpUi.font(m, 15, min: 13),
                      color: HelpUi.secondaryText,
                    ),
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

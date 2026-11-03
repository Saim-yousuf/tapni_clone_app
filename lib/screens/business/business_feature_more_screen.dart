import 'package:flutter/material.dart';
import 'package:tapni_app/utils/business_feature_hub.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Less-frequent Feature Hub modules (open for every business type).
class BusinessFeatureMoreScreen extends StatelessWidget {
  const BusinessFeatureMoreScreen({
    super.key,
    required this.businessType,
    required this.onOpenItem,
  });

  final String businessType;
  final Future<void> Function(FeatureHubItem item) onOpenItem;

  @override
  Widget build(BuildContext context) {
    final items = moreHubItems(businessType);
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'More Features'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text(
                      'All tools are available for your business. '
                      'Turn optional ones on in Feature Settings when needed.',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const WaSectionHeader('Modules'),
                  ...items.map(
                    (item) => WaToolsListTile(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.recommended
                          ? '${item.subtitle}\nRecommended for your type'
                          : item.subtitle,
                      onTap: () => onOpenItem(item),
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

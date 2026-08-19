import 'package:tapni_app/helper/log_helper.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/widgets/bank_widgets.dart';
import 'package:tapni_app/widgets/document_viewer.dart';
import 'package:tapni_app/widgets/loading_widget.dart';
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class Launcher {
  static Future<void> openLink(
    SocialLink model,
    context, {
    String? businessId,
    String? businessName,
    String? businessCategory,
  }) async {
    PrintLog.logMessage("model.fieldType: ${model.fieldType}");
    if (model.isDocumentLink) {
      await openCatalogDocument(
        context,
        CatalogItem(
          name: model.platformName,
          imageUrl: model.fullUrl,
        ),
        fileExt: model.fileExt,
      );
      return;
    }
    if (model.isCatalogLink) {
      openCatalogLink(
        context: context,
        link: model,
        businessId: businessId,
        businessName: businessName,
        businessCategory: businessCategory,
      );
      return;
    }
    if (model.fieldType == "bank") {
      CustomDialog.showDailog(
        child: BlurredDialog(
          child: BankDetailDialog(
            bankDetails: {
              "accountHolderName": "Saim Yousuf",
              "iban": "PK43747374783747",
              "accountNumber": "473747374737434",
            },
          ),
        ),
        context: context,
      );
    } else {
      await launchUrl(
        Uri.parse(model.url ?? ""),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

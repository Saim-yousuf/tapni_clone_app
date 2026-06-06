import 'package:tapni_app/helper/log_helper.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/widgets/bank_widgets.dart';
import 'package:tapni_app/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class Launcher {
  static Future<void> openLink(SocialLink model, context) async {
    PrintLog.logMessage("model.fieldType: ${model.fieldType}");
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

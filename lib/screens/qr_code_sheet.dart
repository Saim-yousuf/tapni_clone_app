import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/business_card_share_sheet.dart';

/// Opens the business card share sheet with selected profile template,
/// PNG/JPG download, and Google Wallet.
class SharingProfileSheet {
  static void show(BuildContext context) {
    BusinessCardShareSheet.showMyCard(context);
  }
}

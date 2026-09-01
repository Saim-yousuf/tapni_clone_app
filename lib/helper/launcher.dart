import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/link_entries_cache.dart';
import 'package:tapni_app/helper/log_helper.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/gallery_link_screen.dart';
import 'package:tapni_app/widgets/bank_widgets.dart';
import 'package:tapni_app/widgets/document_viewer.dart';
import 'package:tapni_app/widgets/link_entries_sheet.dart';
import 'package:tapni_app/widgets/loading_widget.dart';
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class Launcher {
  static SocialLink _freshFromProvider(BuildContext context, SocialLink model) {
    try {
      final links =
          Provider.of<ProfileProvider>(context, listen: false).profile.socialLinks;
      for (final link in links) {
        if (link.id == model.id) return link;
      }
      for (final link in links) {
        if (model.templateId != null &&
            model.templateId!.isNotEmpty &&
            link.templateId == model.templateId) {
          return link;
        }
      }
      for (final link in links) {
        if (link.platformName.toLowerCase() == model.platformName.toLowerCase()) {
          return link;
        }
      }
    } catch (_) {}
    return model;
  }

  static Future<void> openLink(
    SocialLink model,
    context, {
    String? businessId,
    String? businessName,
    String? businessCategory,
    String? currency,
    List<GalleryItem>? galleryItems,
    bool isGalleryOwner = false,
    /// When set (e.g. custom card scan), only these multi-entry values appear.
    Set<String>? allowedEntryIds,
  }) async {
    PrintLog.logMessage("model.fieldType: ${model.fieldType}");
    if (model.isGalleryLink) {
      final items = galleryItems ??
          (isGalleryOwner
              ? Provider.of<ProfileProvider>(context, listen: false)
                    .profile
                    .gallery
              : const <GalleryItem>[]);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GalleryLinkScreen(
            items: items,
            isOwner: isGalleryOwner,
          ),
        ),
      );
      return;
    }
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
        currency: currency,
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
      return;
    }

    // Always re-resolve entries from provider + local cache before deciding.
    var link = _freshFromProvider(context, model);
    try {
      final userId =
          Provider.of<ProfileProvider>(context, listen: false).profile.id ?? '';
      link = await LinkEntriesCache.resolve(link, userId: userId);
    } catch (_) {}

    if (allowedEntryIds != null &&
        allowedEntryIds.isNotEmpty &&
        link.effectiveEntries.isNotEmpty) {
      final filtered = link.effectiveEntries
          .where((e) => allowedEntryIds.contains(e.id))
          .toList();
      if (filtered.isEmpty) return;
      link = link.copyWith(
        entries: filtered,
        value: filtered.first.value,
      );
    }

    PrintLog.logMessage(
      "link.entries=${link.entries?.length ?? 0} multi=${link.hasMultipleEntries}",
    );

    if (link.hasMultipleEntries) {
      await showLinkEntriesSheet(context: context, link: link);
      return;
    }

    final launchTarget = link.fullUrl;
    if (launchTarget.isEmpty) return;
    await launchUrl(
      Uri.parse(launchTarget),
      mode: LaunchMode.externalApplication,
    );
  }
}

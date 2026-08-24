import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/screens/explore_item_detail_loader_screen.dart';
import 'package:tapni_app/screens/explore_offer_loader_screen.dart';

/// Opens real Explore flows: loyalty enroll → customer detail; item → detail page.
class ExploreActions {
  static Future<void> openOffer(
    BuildContext context,
    ExploreOffer offer,
  ) async {
    if (offer.id.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreOfferLoaderScreen(offer: offer),
      ),
    );
  }

  static Future<void> openCatalogItem(
    BuildContext context,
    ExploreItem item,
  ) async {
    if (item.businessUsername.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreItemDetailLoaderScreen(item: item),
      ),
    );
  }
}

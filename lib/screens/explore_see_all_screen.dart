import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/business_categories.dart';
import 'package:tapni_app/utils/explore_actions.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

enum ExploreSeeAllKind { offers, items, services, businesses }

class ExploreSeeAllScreen extends StatelessWidget {
  final ExploreSeeAllKind kind;
  final List<ExploreOffer> offers;
  final List<ExploreItem> items;
  final List<ExploreBusiness> businesses;

  const ExploreSeeAllScreen({
    super.key,
    required this.kind,
    this.offers = const [],
    this.items = const [],
    this.businesses = const [],
  });

  String get _title {
    switch (kind) {
      case ExploreSeeAllKind.offers:
        return 'Reward offers';
      case ExploreSeeAllKind.items:
        return 'Items';
      case ExploreSeeAllKind.services:
        return 'Services';
      case ExploreSeeAllKind.businesses:
        return 'Businesses';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: WaUi.primaryText,
        title: Text(
          _title,
          style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: kind == ExploreSeeAllKind.offers
          ? _offersGrid(context)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _count,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _tile(context, index),
            ),
    );
  }

  Widget _offersGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final program = offer.toRewardProgram();
        return InkWell(
          onTap: () => ExploreActions.openOffer(context, offer),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: offer.hasDesign
                      ? LoyaltyCardDesignRenderer(
                          design: offer.design!,
                          borderRadius: 16,
                          shadows: const [],
                        )
                      : ColoredBox(
                          color: program.theme.cardBackgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  program.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: program.theme.cardTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: List.generate(
                                    program.stamps.clamp(1, 8),
                                    (_) => RewardStampSlot(
                                      filled: false,
                                      theme: program.theme,
                                      stampIconUrl: program.stampIcon,
                                      unstampIconUrl: program.unstampIcon,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                offer.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.label.copyWith(color: WaUi.secondaryText),
              ),
            ],
          ),
        );
      },
    );
  }

  int get _count {
    switch (kind) {
      case ExploreSeeAllKind.offers:
        return offers.length;
      case ExploreSeeAllKind.items:
      case ExploreSeeAllKind.services:
        return items.length;
      case ExploreSeeAllKind.businesses:
        return businesses.length;
    }
  }

  Widget _tile(BuildContext context, int index) {
    switch (kind) {
      case ExploreSeeAllKind.offers:
        return const SizedBox.shrink();
      case ExploreSeeAllKind.items:
      case ExploreSeeAllKind.services:
        final item = items[index];
        return _card(
          onTap: () => ExploreActions.openCatalogItem(context, item),
          leading: _image(
            item.image,
            item.isService ? Icons.handyman_outlined : Icons.fastfood_outlined,
          ),
          title: item.name,
          subtitle: item.businessName,
          trailing: item.price > 0
              ? 'Rs ${item.price.toStringAsFixed(0)}'
              : null,
        );
      case ExploreSeeAllKind.businesses:
        final biz = businesses[index];
        final category = biz.businessCategory.isEmpty
            ? ''
            : businessCategoryLabel(context, biz.businessCategory);
        return _card(
          onTap: () {
            if (biz.username.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScannedProfileScreen(username: biz.username),
              ),
            );
          },
          leading: _image(biz.profilePhoto, Icons.storefront_outlined),
          title: biz.displayName,
          subtitle: [
            if (category.isNotEmpty) category,
            if (biz.locationLabel.isNotEmpty) biz.locationLabel,
          ].join(' · '),
          trailing: biz.avgRating > 0
              ? biz.avgRating.toStringAsFixed(1)
              : null,
        );
    }
  }

  Widget _card({
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    String? subtitle,
    String? trailing,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WaUi.divider),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.label.copyWith(color: WaUi.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: WaUi.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(String? url, IconData fallback) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: WaUi.searchBg,
                  child: Icon(fallback, color: WaUi.secondaryText),
                ),
              )
            : ColoredBox(
                color: WaUi.searchBg,
                child: Icon(fallback, color: WaUi.secondaryText),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/utils/business_features.dart';

/// Modular Feature Hub entry (Business Suite home + More Features).
/// IDs align with existing feature keys / navigation modules — not new engines.
enum FeatureHubPlacement { frequent, more }

class FeatureHubItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final FeatureHubPlacement placement;

  /// Optional feature key used for enable / Pro checks (`loyalty`, `team`, …).
  final String? featureKey;

  /// Recommended for this business type (ordering / subtle hint only).
  final bool recommended;

  const FeatureHubItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.placement,
    this.featureKey,
    this.recommended = false,
  });
}

/// Catalog of hub modules. Access is open for every business type;
/// [businessType] only changes order and which items sit in Frequent vs More.
List<FeatureHubItem> featureHubItemsFor(String? businessType) {
  final type = normalizeBusinessType(businessType);
  final t = type.isEmpty ? 'products' : type;

  final all = <FeatureHubItem>[
    FeatureHubItem(
      id: 'orders',
      title: t == 'restaurant'
          ? 'Pickup & Delivery Orders'
          : t == 'portfolio'
              ? 'Enquiries & Orders'
              : 'Orders & Bookings',
      subtitle: t == 'restaurant'
          ? 'Pickup and delivery orders from customers'
          : 'Orders, appointments, and stays',
      icon: Icons.receipt_long_outlined,
      placement: FeatureHubPlacement.frequent,
      featureKey: 'orders',
      recommended: true,
    ),
    FeatureHubItem(
      id: 'website',
      title: 'Website & Catalog',
      subtitle: 'Create, edit, publish, and manage sections & items',
      icon: Icons.language_outlined,
      placement: FeatureHubPlacement.frequent,
      featureKey: 'website',
      recommended: true,
    ),
    FeatureHubItem(
      id: 'earnings',
      title: 'Earnings',
      subtitle: 'Balance, payouts, and payment history',
      icon: Icons.account_balance_wallet_outlined,
      placement: FeatureHubPlacement.frequent,
      featureKey: 'earnings',
      recommended: t != 'portfolio',
    ),
    FeatureHubItem(
      id: 'calendar',
      title: 'Booking Calendar',
      subtitle: 'Busy times for appointments and stays',
      icon: Icons.event_available_outlined,
      placement: t == 'services' || t == 'stay'
          ? FeatureHubPlacement.frequent
          : FeatureHubPlacement.more,
      featureKey: 'calendar',
      recommended: t == 'services' || t == 'stay',
    ),
    FeatureHubItem(
      id: 'rooms',
      title: 'Rooms',
      subtitle: 'Stay room inventory and availability',
      icon: Icons.meeting_room_outlined,
      placement: t == 'stay'
          ? FeatureHubPlacement.frequent
          : FeatureHubPlacement.more,
      featureKey: 'rooms',
      recommended: t == 'stay',
    ),
    FeatureHubItem(
      id: 'staff',
      title: 'Staff Management',
      subtitle: 'Team attendance, specialists, and bookable staff',
      icon: Icons.groups_outlined,
      placement: t == 'services' || t == 'restaurant'
          ? FeatureHubPlacement.frequent
          : FeatureHubPlacement.more,
      featureKey: 'team',
      recommended: t == 'services' || t == 'restaurant',
    ),
    FeatureHubItem(
      id: 'loyalty',
      title: 'Loyalty Program',
      subtitle: 'Stamps, points, rewards, and redemptions',
      icon: Icons.stars_outlined,
      placement: FeatureHubPlacement.more,
      featureKey: 'loyalty',
      recommended: t == 'restaurant' || t == 'products',
    ),
    FeatureHubItem(
      id: 'offers',
      title: 'Offers & Coupons',
      subtitle: 'Discounts, rules, validity, and checkout offers',
      icon: Icons.local_offer_outlined,
      placement: FeatureHubPlacement.more,
      featureKey: 'offers',
      recommended: t == 'products' || t == 'restaurant',
    ),
    FeatureHubItem(
      id: 'ads',
      title: 'Banner Ads',
      subtitle: 'Promote your business on Explore',
      icon: Icons.campaign_outlined,
      placement: FeatureHubPlacement.more,
      featureKey: 'ads',
    ),
    FeatureHubItem(
      id: 'pos',
      title: 'POS Connect',
      subtitle: 'Push orders to kitchen POS (e.g. Foodics)',
      icon: Icons.point_of_sale_outlined,
      placement: FeatureHubPlacement.more,
      featureKey: 'pos',
      recommended: t == 'restaurant',
    ),
    const FeatureHubItem(
      id: 'features',
      title: 'Feature Settings',
      subtitle: 'Turn optional tools on or off',
      icon: Icons.tune_outlined,
      placement: FeatureHubPlacement.more,
    ),
  ];

  int rank(FeatureHubItem a) {
    // Recommended + frequent first within each placement.
    final base = a.placement == FeatureHubPlacement.frequent ? 0 : 100;
    return base + (a.recommended ? 0 : 10);
  }

  final sorted = [...all]..sort((a, b) {
      final c = rank(a).compareTo(rank(b));
      if (c != 0) return c;
      return a.title.compareTo(b.title);
    });
  return sorted;
}

List<FeatureHubItem> frequentHubItems(String? businessType) =>
    featureHubItemsFor(businessType)
        .where((e) => e.placement == FeatureHubPlacement.frequent)
        .toList();

List<FeatureHubItem> moreHubItems(String? businessType) =>
    featureHubItemsFor(businessType)
        .where((e) => e.placement == FeatureHubPlacement.more)
        .toList();

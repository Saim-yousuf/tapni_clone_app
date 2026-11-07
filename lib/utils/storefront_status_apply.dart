import 'package:tapni_app/providers/explore_cart_provider.dart';

/// Parses public storefront status JSON into [ExploreCartProvider].
void applyStorefrontStatusMap(
  ExploreCartProvider cart,
  Map<String, dynamic> map, {
  required String websiteSlug,
}) {
  if (map.isEmpty) return;
  final paused = map['ordersPaused'] == true;
  final closed = map['isClosedNow'] == true || map['isOpenNow'] == false;
  final feeRaw = map['deliveryFee'];
  final freeRaw = map['freeDeliveryAbove'];
  final minRaw = map['minOrderAmount'];
  final prepRaw = map['prepTimeMinutes'];
  final areasRaw = map['deliveryAreas'];
  final areas = <String>[];
  if (areasRaw is List) {
    for (final a in areasRaw) {
      final t = a?.toString().trim() ?? '';
      if (t.isNotEmpty) areas.add(t);
    }
  }

  cart.updateVendorOrderingStatus(
    businessId: (map['businessId'] ?? '').toString(),
    websiteSlug: websiteSlug,
    ordersPaused: paused,
    isClosedNow: !paused && closed,
    deliveryFee:
        feeRaw is num ? feeRaw.toDouble() : double.tryParse('$feeRaw'),
    freeDeliveryAbove:
        freeRaw is num ? freeRaw.toDouble() : double.tryParse('$freeRaw'),
    minOrderAmount:
        minRaw is num ? minRaw.toDouble() : double.tryParse('$minRaw'),
    acceptPickup: map['acceptPickup'] != false,
    acceptDelivery: map['acceptDelivery'] != false,
    tipsEnabled: map['tipsEnabled'] == true,
    scheduleOrdersEnabled: map['scheduleOrdersEnabled'] == true,
    deliveryAreas: areas,
    prepTimeMinutes: prepRaw is num
        ? prepRaw.round()
        : int.tryParse('$prepRaw'),
  );
}

import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/reward.dart';

class ExploreBusiness {
  final String id;
  final String name;
  final String username;
  final String? profilePhoto;
  final String? coverPhoto;
  final String businessName;
  final String businessCategory;
  final String bio;
  final double? latitude;
  final double? longitude;
  final String businessAddress;
  final String city;
  final String area;
  final double avgRating;
  final int reviewCount;
  final double? distanceKm;

  const ExploreBusiness({
    required this.id,
    required this.name,
    required this.username,
    this.profilePhoto,
    this.coverPhoto,
    required this.businessName,
    required this.businessCategory,
    this.bio = '',
    this.latitude,
    this.longitude,
    this.businessAddress = '',
    this.city = '',
    this.area = '',
    this.avgRating = 0,
    this.reviewCount = 0,
    this.distanceKm,
  });

  factory ExploreBusiness.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ExploreBusiness(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString(),
      coverPhoto: json['coverPhoto']?.toString(),
      businessName: json['businessName']?.toString() ?? '',
      businessCategory: json['businessCategory']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      businessAddress: json['businessAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      avgRating: toDouble(json['avgRating']) ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: toDouble(json['distanceKm']),
    );
  }

  String get displayName =>
      businessName.trim().isNotEmpty ? businessName.trim() : name;

  String get locationLabel {
    if (businessAddress.trim().isNotEmpty) return businessAddress.trim();
    if (area.trim().isNotEmpty && city.trim().isNotEmpty) {
      return '${area.trim()}, ${city.trim()}';
    }
    if (city.trim().isNotEmpty) return city.trim();
    if (area.trim().isNotEmpty) return area.trim();
    return '';
  }
}

class ExploreOffer {
  final String id;
  final String title;
  final String label;
  final String description;
  final String? logo;
  final String? stampIcon;
  final String? unstampIcon;
  final int stamps;
  final RewardTheme theme;
  final LoyaltyCardDesign? design;
  final String businessId;
  final String businessName;
  final String businessUsername;
  final String? businessPhoto;
  final double? distanceKm;

  const ExploreOffer({
    required this.id,
    required this.title,
    this.label = '',
    this.description = '',
    this.logo,
    this.stampIcon,
    this.unstampIcon,
    this.stamps = 0,
    required this.theme,
    this.design,
    required this.businessId,
    required this.businessName,
    required this.businessUsername,
    this.businessPhoto,
    this.distanceKm,
  });

  bool get hasDesign => design != null && design!.hasLayers;

  RewardProgram toRewardProgram() {
    return RewardProgram(
      id: id,
      logo: logo ?? '',
      stampIcon: stampIcon ?? '',
      unstampIcon: unstampIcon ?? '',
      label: label,
      title: title,
      description: description,
      stamps: stamps,
      theme: theme,
      isActive: true,
      businessId: businessId,
      businessName: businessName,
      businessUsername: businessUsername,
      businessPhoto: businessPhoto,
      design: design,
    );
  }

  factory ExploreOffer.fromJson(Map<String, dynamic> json) {
    LoyaltyCardDesign? design;
    final rawDesign = json['design'];
    if (rawDesign is Map) {
      try {
        design = LoyaltyCardDesign.fromJson(
          Map<String, dynamic>.from(rawDesign),
        );
      } catch (_) {
        design = null;
      }
    }

    return ExploreOffer(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Reward offer',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      logo: json['logo']?.toString(),
      stampIcon: json['stampIcon']?.toString(),
      unstampIcon: json['unstampIcon']?.toString(),
      stamps: (json['stamps'] as num?)?.toInt() ?? 0,
      theme: json['theme'] is Map
          ? RewardTheme.fromJson(Map<String, dynamic>.from(json['theme'] as Map))
          : RewardTheme(),
      design: design,
      businessId: json['businessId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      businessUsername: json['businessUsername']?.toString() ?? '',
      businessPhoto: json['businessPhoto']?.toString(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class ExploreItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String? image;
  final String category;
  final String catalogType;
  final String businessId;
  final String businessName;
  final String businessUsername;
  final String businessAddress;
  final double avgRating;
  final int reviewCount;
  final double? distanceKm;

  const ExploreItem({
    required this.id,
    required this.name,
    this.price = 0,
    this.description = '',
    this.image,
    this.category = '',
    this.catalogType = 'catalog',
    required this.businessId,
    required this.businessName,
    required this.businessUsername,
    this.businessAddress = '',
    this.avgRating = 0,
    this.reviewCount = 0,
    this.distanceKm,
  });

  factory ExploreItem.fromJson(Map<String, dynamic> json) {
    return ExploreItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      category: json['category']?.toString() ?? '',
      catalogType: json['catalogType']?.toString() ?? 'catalog',
      businessId: json['businessId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      businessUsername: json['businessUsername']?.toString() ?? '',
      businessAddress: json['businessAddress']?.toString() ?? '',
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  bool get isService => catalogType == 'services';
}

class ExploreNearbyResult {
  final List<ExploreBusiness> businesses;
  final List<ExploreOffer> offers;
  final List<ExploreItem> items;
  final int page;
  final int total;
  final bool hasMore;

  const ExploreNearbyResult({
    required this.businesses,
    this.offers = const [],
    this.items = const [],
    required this.page,
    required this.total,
    required this.hasMore,
  });
}

class ExploreBanner {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final String buttonText;
  final String image;
  final String gradientStart;
  final String gradientEnd;
  final String actionType;
  final String actionUrl;
  final int sortOrder;

  const ExploreBanner({
    required this.id,
    this.tag = '',
    this.title = '',
    this.subtitle = '',
    this.buttonText = '',
    this.image = '',
    this.gradientStart = '#0F766E',
    this.gradientEnd = '#EA580C',
    this.actionType = 'none',
    this.actionUrl = '',
    this.sortOrder = 0,
  });

  factory ExploreBanner.fromJson(Map<String, dynamic> json) {
    return ExploreBanner(
      id: json['id']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      gradientStart: json['gradientStart']?.toString() ?? '#0F766E',
      gradientEnd: json['gradientEnd']?.toString() ?? '#EA580C',
      actionType: json['actionType']?.toString() ?? 'none',
      actionUrl: json['actionUrl']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExploreCategoryItem {
  final String id;
  final String name;
  final String label;
  final String icon;
  final String iconUrl;
  final int sortOrder;

  const ExploreCategoryItem({
    required this.id,
    required this.name,
    required this.label,
    this.icon = 'category_rounded',
    this.iconUrl = '',
    this.sortOrder = 0,
  });

  factory ExploreCategoryItem.fromJson(Map<String, dynamic> json) {
    return ExploreCategoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'category_rounded',
      iconUrl: json['iconUrl']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

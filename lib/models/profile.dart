import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/models/user_custom_card.dart';

class UserProfile {
  final String? id;
  final String? username;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final bool isPro;
  final bool isPublic;

  final String name;
  final String email;
  final String bio;
  String? country;
  /// ISO 4217 business currency (e.g. PKR, AED). Source of truth for catalog prices.
  String? currency;
  String? businessName;
  String? businessCategory;
  double? latitude;
  double? longitude;
  String? businessAddress;
  String? city;
  String? area;
  double avgRating;
  int reviewCount;
  final List<SocialLink> socialLinks;

  final String designation;
  final String company;
  final String phone;
  final String website;
  final int viewsCount;
  final int scansCount;
  final int leadsCount;
  final String cardTemplateId;
  final List<UserCustomCard> customCards;
  /// Print design for the primary digital card.
  final BusinessCardDesign? cardPrintDesign;
  final bool canView;
  final String followStatus;
  final List<GalleryItem> gallery;

  UserProfile({
    this.id,
    this.username,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.isPro = false,
    this.isPublic = true,
    required this.name,
    required this.email,
    required this.bio,
    this.country,
    this.currency,
    this.businessName,
    this.businessCategory,
    this.latitude,
    this.longitude,
    this.businessAddress,
    this.city,
    this.area,
    this.avgRating = 0,
    this.reviewCount = 0,
    required this.socialLinks,
    this.designation = '',
    this.company = '',
    this.phone = '',
    this.website = '',
    this.viewsCount = 0,
    this.scansCount = 0,
    this.leadsCount = 0,
    this.cardTemplateId = 't2',
    this.customCards = const [],
    this.cardPrintDesign,
    this.canView = true,
    this.followStatus = 'none',
    this.gallery = const [],
  });

  factory UserProfile.fromApiJson(Map<String, dynamic> json) {
    final links = (json['links'] as List<dynamic>? ?? [])
        .map((e) => SocialLink.fromApiJson(e as Map<String, dynamic>))
        .toList();
    final printDesignJson = json['cardPrintDesign'];

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return UserProfile(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      username: json['username']?.toString(),
      profilePhotoUrl: json['profilePhoto']?.toString(),
      coverPhotoUrl: json['coverPhoto']?.toString(),
      isPro: json['isPro'] as bool? ?? json['IsPro'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      canView: json['canView'] as bool? ?? true,
      followStatus: json['followStatus']?.toString() ?? 'none',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      country: json['country'],
      currency: json['currency']?.toString(),
      businessName: json['businessName']?.toString(),
      businessCategory: json['businessCategory']?.toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      businessAddress: json['businessAddress']?.toString(),
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      avgRating: toDouble(json['avgRating']) ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      socialLinks: links,
      cardTemplateId: json['cardTemplateId'] as String? ?? 't2',
      customCards: (json['customCards'] as List<dynamic>? ?? [])
          .map((e) => UserCustomCard.fromJson(e as Map<String, dynamic>))
          .where((card) => card.id.isNotEmpty && !card.isPrimary)
          .toList(),
      cardPrintDesign: printDesignJson is Map
          ? BusinessCardDesign.fromJson(
              Map<String, dynamic>.from(printDesignJson),
            )
          : null,
      gallery: GalleryItem.listFrom(json['gallery']),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      if (email.trim().isNotEmpty) 'email': email,
      'bio': bio,
      'country': country,
      if (currency != null && currency!.trim().isNotEmpty) 'currency': currency,
      'isPublic': isPublic,
      if (businessName != null) 'businessName': businessName,
      if (businessCategory != null) 'businessCategory': businessCategory,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (city != null) 'city': city,
      if (area != null) 'area': area,
      'links': socialLinks
          .where((l) => l.isActive)
          .map((l) => l.toApiJson())
          .toList(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    String? name,
    String? email,
    String? bio,
    String? country,
    String? currency,
    String? businessName,
    String? businessCategory,
    double? latitude,
    double? longitude,
    String? businessAddress,
    String? city,
    String? area,
    double? avgRating,
    int? reviewCount,
    List<SocialLink>? socialLinks,
    String? designation,
    String? company,
    String? phone,
    String? website,
    int? viewsCount,
    int? scansCount,
    int? leadsCount,
    bool? isPro,
    bool? isPublic,
    String? cardTemplateId,
    List<UserCustomCard>? customCards,
    BusinessCardDesign? cardPrintDesign,
    bool clearCardPrintDesign = false,
    bool? canView,
    String? followStatus,
    List<GalleryItem>? gallery,
    bool clearLatitude = false,
    bool clearLongitude = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      isPro: isPro ?? this.isPro,
      isPublic: isPublic ?? this.isPublic,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      businessAddress: businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      area: area ?? this.area,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      socialLinks: socialLinks ?? this.socialLinks,
      designation: designation ?? this.designation,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      viewsCount: viewsCount ?? this.viewsCount,
      scansCount: scansCount ?? this.scansCount,
      leadsCount: leadsCount ?? this.leadsCount,
      cardTemplateId: cardTemplateId ?? this.cardTemplateId,
      customCards: customCards ?? this.customCards,
      cardPrintDesign: clearCardPrintDesign
          ? null
          : (cardPrintDesign ?? this.cardPrintDesign),
      canView: canView ?? this.canView,
      followStatus: followStatus ?? this.followStatus,
      gallery: gallery ?? this.gallery,
    );
  }
}

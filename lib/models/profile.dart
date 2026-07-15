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
  String? businessName;
  String? businessCategory;
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
    this.businessName,
    this.businessCategory,
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
  });

  factory UserProfile.fromApiJson(Map<String, dynamic> json) {
    final links = (json['links'] as List<dynamic>? ?? [])
        .map((e) => SocialLink.fromApiJson(e as Map<String, dynamic>))
        .toList();

    return UserProfile(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      profilePhotoUrl: json['profilePhoto']?.toString(),
      coverPhotoUrl: json['coverPhoto']?.toString(),
      isPro: json['isPro'] as bool? ?? json['IsPro'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      country: json['country'],
      businessName: json['businessName']?.toString(),
      businessCategory: json['businessCategory']?.toString(),
      socialLinks: links,
      cardTemplateId: json['cardTemplateId'] as String? ?? 't2',
      customCards: (json['customCards'] as List<dynamic>? ?? [])
          .map((e) => UserCustomCard.fromJson(e as Map<String, dynamic>))
          .where((card) => card.id.isNotEmpty && !card.isPrimary)
          .toList(),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'bio': bio,
      'country': country,
      'isPublic': isPublic,
      if (businessName != null) 'businessName': businessName,
      if (businessCategory != null) 'businessCategory': businessCategory,
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
    String? businessName,
    String? businessCategory,
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
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
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
    );
  }
}

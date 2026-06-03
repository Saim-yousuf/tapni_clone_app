import 'package:tapni_app/models/social_link.dart';

class UserProfile {
  // API fields
  final String? id;
  final String? username;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;

  // Local + API fields
  final String name;
  final String email;
  final String bio;
  final List<SocialLink> socialLinks;

  // Local-only fields (not synced with API)
  final String designation;
  final String company;
  final String phone;
  final String website;
  final int viewsCount;
  final int scansCount;
  final int leadsCount;

  UserProfile({
    this.id,
    this.username,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    required this.name,
    required this.email,
    required this.bio,
    required this.socialLinks,
    this.designation = '',
    this.company = '',
    this.phone = '',
    this.website = '',
    this.viewsCount = 0,
    this.scansCount = 0,
    this.leadsCount = 0,
  });

  /// Map API /profile response to UserProfile.
  factory UserProfile.fromApiJson(Map<String, dynamic> json) {
    final links = (json['links'] as List<dynamic>? ?? [])
        .map((e) => SocialLink.fromApiJson(e as Map<String, dynamic>))
        .toList();

    return UserProfile(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      profilePhotoUrl: json['profilePhoto']?.toString(),
      coverPhotoUrl: json['coverPhoto']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      socialLinks: links,
    );
  }

  /// Build update payload for PUT /api/user/auth/profile.
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'bio': bio,
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
    List<SocialLink>? socialLinks,
    String? designation,
    String? company,
    String? phone,
    String? website,
    int? viewsCount,
    int? scansCount,
    int? leadsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
      designation: designation ?? this.designation,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      viewsCount: viewsCount ?? this.viewsCount,
      scansCount: scansCount ?? this.scansCount,
      leadsCount: leadsCount ?? this.leadsCount,
    );
  }
}

import 'package:tapni_app/models/social_link.dart';

class UserProfile {
  final String name;
  final String designation;
  final String company;
  final String bio;
  final String phone;
  final String email;
  final String website;
  final String? avatarUrl; // we'll use a local mock or colored circles
  final List<SocialLink> socialLinks;
  final int viewsCount;
  final int scansCount;
  final int leadsCount;

  UserProfile({
    required this.name,
    required this.designation,
    required this.company,
    required this.bio,
    required this.phone,
    required this.email,
    required this.website,
    this.avatarUrl,
    required this.socialLinks,
    this.viewsCount = 0,
    this.scansCount = 0,
    this.leadsCount = 0,
  });

  UserProfile copyWith({
    String? name,
    String? designation,
    String? company,
    String? bio,
    String? phone,
    String? email,
    String? website,
    String? avatarUrl,
    List<SocialLink>? socialLinks,
    int? viewsCount,
    int? scansCount,
    int? leadsCount,
  }) {
    return UserProfile(
      name: name ?? this.name,
      designation: designation ?? this.designation,
      company: company ?? this.company,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      viewsCount: viewsCount ?? this.viewsCount,
      scansCount: scansCount ?? this.scansCount,
      leadsCount: leadsCount ?? this.leadsCount,
    );
  }
}

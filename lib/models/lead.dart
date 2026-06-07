import 'package:tapni_app/models/contact_category.dart';

class ContactUserData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String jobTitle;
  final String? profilePhoto;
  final String? username;

  ContactUserData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.jobTitle,
    this.profilePhoto,
    this.username,
  });

  factory ContactUserData.fromJson(Map<String, dynamic> json) {
    return ContactUserData(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      profilePhoto: json['profilePhoto'],
      username: json['username'],
    );
  }
}

class Lead {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String jobTitle;
  final String website;
  final String note;
  final String address;
  final DateTime timestamp;
  final ContactCategory? category;
  final String? contactUser; // scanned user's ID
  final ContactUserData? contactUserData; // scanned user's live data

  Lead({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    this.jobTitle = '',
    this.website = '',
    this.note = '',
    this.address = '',
    required this.timestamp,
    this.category,
    this.contactUser,
    this.contactUserData,
  });

  /// For display: if this is a scanned contact, show data from User collection
  String get displayName =>
      contactUserData != null ? contactUserData!.name : name;

  String get displayEmail =>
      contactUserData != null ? contactUserData!.email : email;

  String get displayPhone =>
      contactUserData != null ? contactUserData!.phone : phone;

  String get displayCompany =>
      contactUserData != null ? contactUserData!.company : company;

  String get displayJobTitle =>
      contactUserData != null ? contactUserData!.jobTitle : jobTitle;

  String? get displayProfilePhoto =>
      contactUserData != null ? contactUserData!.profilePhoto : null;

  bool get isScannedContact => contactUser != null;

  factory Lead.fromJson(Map<String, dynamic> json) {
    ContactUserData? userData;
    if (json['contactUserData'] != null &&
        json['contactUserData'] is Map<String, dynamic>) {
      userData =
          ContactUserData.fromJson(json['contactUserData'] as Map<String, dynamic>);
    }

    return Lead(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      website: json['website'] ?? '',
      note: json['note'] ?? '',
      address: json['address'] ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] != null
          ? ContactCategory.fromJson(json['category'])
          : null,
      contactUser: json['contactUser']?.toString(),
      contactUserData: userData,
    );
  }

  Lead copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? website,
    String? note,
    String? address,
    DateTime? timestamp,
    ContactCategory? category,
    String? contactUser,
    ContactUserData? contactUserData,
  }) {
    return Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      website: website ?? this.website,
      note: note ?? this.note,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      contactUser: contactUser ?? this.contactUser,
      contactUserData: contactUserData ?? this.contactUserData,
    );
  }
}

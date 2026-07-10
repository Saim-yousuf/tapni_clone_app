import 'package:tapni_app/utils/card_template_catalog.dart';

class CompanyBusinessCard {
  final String employeeRefId;
  final String businessId;
  final String name;
  final String businessName;
  final String username;
  final String profilePhoto;
  final String bio;
  final String businessCategory;
  final String profileUrl;
  final String shiftStart;
  final String shiftEnd;
  final String cardTemplateId;
  final String businessCardTemplateId;
  final String employeeCardTemplateId;
  final String employeeName;
  final String employeePhoto;
  final String employeeUsername;
  final String employeeProfileUrl;

  CompanyBusinessCard({
    required this.employeeRefId,
    required this.businessId,
    this.name = '',
    this.businessName = '',
    this.username = '',
    this.profilePhoto = '',
    this.bio = '',
    this.businessCategory = '',
    this.profileUrl = '',
    this.shiftStart = '09:00',
    this.shiftEnd = '18:00',
    this.cardTemplateId = CardTemplateCatalog.defaultTemplateId,
    this.businessCardTemplateId = CardTemplateCatalog.defaultTemplateId,
    this.employeeCardTemplateId = '',
    this.employeeName = '',
    this.employeePhoto = '',
    this.employeeUsername = '',
    this.employeeProfileUrl = '',
  });

  factory CompanyBusinessCard.fromJson(Map<String, dynamic> json) {
    return CompanyBusinessCard(
      employeeRefId: (json['employeeRefId'] ?? '').toString(),
      businessId: (json['businessId'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      businessCategory: json['businessCategory'] as String? ?? '',
      profileUrl: json['profileUrl'] as String? ?? '',
      shiftStart: json['shiftStart'] as String? ?? '09:00',
      shiftEnd: json['shiftEnd'] as String? ?? '18:00',
      cardTemplateId: json['cardTemplateId'] as String? ??
          CardTemplateCatalog.defaultTemplateId,
      businessCardTemplateId: json['businessCardTemplateId'] as String? ??
          json['cardTemplateId'] as String? ??
          CardTemplateCatalog.defaultTemplateId,
      employeeCardTemplateId: json['employeeCardTemplateId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      employeePhoto: json['employeePhoto'] as String? ?? '',
      employeeUsername: json['employeeUsername'] as String? ?? '',
      employeeProfileUrl: json['employeeProfileUrl'] as String? ?? '',
    );
  }

  String get displayName =>
      businessName.isNotEmpty ? businessName : (name.isNotEmpty ? name : username);

  String get employeeDisplayId {
    if (employeeUsername.isNotEmpty) return '@$employeeUsername';
    if (employeeRefId.isNotEmpty) return 'ID: $employeeRefId';
    return '';
  }

  CompanyBusinessCard copyWith({
    String? cardTemplateId,
    String? employeeCardTemplateId,
  }) {
    return CompanyBusinessCard(
      employeeRefId: employeeRefId,
      businessId: businessId,
      name: name,
      businessName: businessName,
      username: username,
      profilePhoto: profilePhoto,
      bio: bio,
      businessCategory: businessCategory,
      profileUrl: profileUrl,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      cardTemplateId: cardTemplateId ?? this.cardTemplateId,
      businessCardTemplateId:
          businessCardTemplateId ?? this.businessCardTemplateId,
      employeeCardTemplateId:
          employeeCardTemplateId ?? this.employeeCardTemplateId,
      employeeName: employeeName,
      employeePhoto: employeePhoto,
      employeeUsername: employeeUsername,
      employeeProfileUrl: employeeProfileUrl,
    );
  }
}

List<CompanyBusinessCard> parseCompanyCardList(dynamic data) {
  if (data is List) {
    return data
        .map((e) => CompanyBusinessCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is List) {
      return inner
          .map((e) => CompanyBusinessCard.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
  return [];
}

Map<String, dynamic> unwrapWalletPayload(dynamic data) {
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }
  return {};
}

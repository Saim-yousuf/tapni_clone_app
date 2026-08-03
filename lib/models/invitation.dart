import 'package:tapni_app/models/invitation_design.dart';

class InvitationUserSummary {
  final String id;
  final String name;
  final String username;
  final String profilePhoto;
  final String businessName;

  InvitationUserSummary({
    required this.id,
    this.name = '',
    this.username = '',
    this.profilePhoto = '',
    this.businessName = '',
  });

  factory InvitationUserSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return InvitationUserSummary(id: '');
    final rawId = json['_id'] ?? json['id'] ?? json['userId'] ?? '';
    return InvitationUserSummary(
      id: rawId.toString(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
    );
  }

  String get displayName =>
      name.isNotEmpty ? name : (username.isNotEmpty ? username : 'User');
}

class InvitationRecipient {
  final InvitationUserSummary user;
  final String phone;
  final String name;
  final DateTime? deliveredAt;

  InvitationRecipient({
    required this.user,
    this.phone = '',
    this.name = '',
    this.deliveredAt,
  });

  factory InvitationRecipient.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return InvitationRecipient(
      user: userJson is Map<String, dynamic>
          ? InvitationUserSummary.fromJson(userJson)
          : InvitationUserSummary(id: (userJson ?? '').toString()),
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
    );
  }
}

class EventInvitation {
  final String id;
  final InvitationUserSummary sender;
  final String type;
  final String title;
  final String message;
  final String venue;
  final String address;
  final DateTime? eventAt;
  final String themeColor;
  final String coverImage;
  final String status;
  final List<InvitationRecipient> recipients;
  final DateTime? createdAt;
  final InvitationDesign? design;

  EventInvitation({
    required this.id,
    required this.sender,
    required this.type,
    required this.title,
    this.message = '',
    this.venue = '',
    this.address = '',
    this.eventAt,
    this.themeColor = '#E85D2A',
    this.coverImage = '',
    this.status = 'sent',
    this.recipients = const [],
    this.createdAt,
    this.design,
  });

  bool get hasDesign => design != null && design!.layers.isNotEmpty;

  factory EventInvitation.fromJson(Map<String, dynamic> json) {
    final recipientsJson = json['recipients'];
    InvitationDesign? design;
    final designJson = json['design'];
    if (designJson is Map<String, dynamic>) {
      design = InvitationDesign.fromJson(designJson);
    } else if (designJson is String && designJson.isNotEmpty) {
      design = InvitationDesign.fromJsonString(designJson);
    }
    return EventInvitation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      sender: InvitationUserSummary.fromJson(
        json['sender'] is Map<String, dynamic>
            ? json['sender'] as Map<String, dynamic>
            : null,
      ),
      type: json['type'] as String? ?? 'other',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      address: json['address'] as String? ?? '',
      eventAt: json['eventAt'] != null
          ? DateTime.tryParse(json['eventAt'].toString())
          : null,
      themeColor: json['themeColor'] as String? ?? '#E85D2A',
      coverImage: json['coverImage'] as String? ?? '',
      status: json['status'] as String? ?? 'sent',
      recipients: recipientsJson is List
          ? recipientsJson
                .whereType<Map<String, dynamic>>()
                .map(InvitationRecipient.fromJson)
                .toList()
          : const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      design: design,
    );
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'wedding':
        return 'Wedding';
      case 'anniversary':
        return 'Anniversary';
      case 'birthday':
        return 'Birthday';
      case 'business_meeting':
        return 'Business Meeting';
      default:
        return 'Other';
    }
  }

  String get typeDisplay => typeLabel(type);
}

class MatchedPhoneUser {
  final String phone;
  final String userId;
  final String name;
  final String username;
  final String profilePhoto;
  final String businessName;

  MatchedPhoneUser({
    required this.phone,
    required this.userId,
    this.name = '',
    this.username = '',
    this.profilePhoto = '',
    this.businessName = '',
  });

  factory MatchedPhoneUser.fromJson(Map<String, dynamic> json) {
    return MatchedPhoneUser(
      phone: json['phone'] as String? ?? '',
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
    );
  }

  String get displayName =>
      name.isNotEmpty ? name : (username.isNotEmpty ? username : phone);
}

class PhoneMatchResult {
  final List<MatchedPhoneUser> matched;
  final List<String> unmatched;

  PhoneMatchResult({this.matched = const [], this.unmatched = const []});

  factory PhoneMatchResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PhoneMatchResult();
    final matchedJson = json['matched'];
    final unmatchedJson = json['unmatched'];
    return PhoneMatchResult(
      matched: matchedJson is List
          ? matchedJson
                .whereType<Map<String, dynamic>>()
                .map(MatchedPhoneUser.fromJson)
                .toList()
          : const [],
      unmatched: unmatchedJson is List
          ? unmatchedJson.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

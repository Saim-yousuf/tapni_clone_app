import 'package:flutter/material.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';

class RewardTheme {
  final Color cardBackgroundColor;
  final Color cardTextColor;
  final Color stampColor;
  final Color stampBorderColor;
  final Color screenBackgroundColor;
  final Color screenTextColor;

  RewardTheme({
    this.cardBackgroundColor = const Color(0xFF000000),
    this.cardTextColor = const Color(0xFFFFFFFF),
    this.stampColor = const Color(0xFF000000),
    this.stampBorderColor = const Color(0xFFCCCCCC),
    this.screenBackgroundColor = const Color(0xFFFFFFFF),
    this.screenTextColor = const Color(0xFF000000),
  });

  factory RewardTheme.fromJson(Map<String, dynamic> json) {
    return RewardTheme(
      cardBackgroundColor: _parseColor(json['cardBackgroundColor'], const Color(0xFF000000)),
      cardTextColor: _parseColor(json['cardTextColor'], const Color(0xFFFFFFFF)),
      stampColor: _parseColor(json['stampColor'], const Color(0xFF000000)),
      stampBorderColor: _parseColor(json['stampBorderColor'], const Color(0xFFCCCCCC)),
      screenBackgroundColor: _parseColor(json['screenBackgroundColor'], const Color(0xFFFFFFFF)),
      screenTextColor: _parseColor(json['screenTextColor'], const Color(0xFF000000)),
    );
  }

  Map<String, dynamic> toJson() => {
    'cardBackgroundColor': _colorToHex(cardBackgroundColor),
    'cardTextColor': _colorToHex(cardTextColor),
    'stampColor': _colorToHex(stampColor),
    'stampBorderColor': _colorToHex(stampBorderColor),
    'screenBackgroundColor': _colorToHex(screenBackgroundColor),
    'screenTextColor': _colorToHex(screenTextColor),
  };

  RewardTheme copyWith({
    Color? cardBackgroundColor,
    Color? cardTextColor,
    Color? stampColor,
    Color? stampBorderColor,
    Color? screenBackgroundColor,
    Color? screenTextColor,
  }) => RewardTheme(
    cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
    cardTextColor: cardTextColor ?? this.cardTextColor,
    stampColor: stampColor ?? this.stampColor,
    stampBorderColor: stampBorderColor ?? this.stampBorderColor,
    screenBackgroundColor: screenBackgroundColor ?? this.screenBackgroundColor,
    screenTextColor: screenTextColor ?? this.screenTextColor,
  );

  static Color _parseColor(dynamic val, Color fallback) {
    if (val == null) return fallback;
    try {
      final hex = val.toString().replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

class RewardProgram {
  final String id;
  final String logo;
  final String stampIcon;
  final String unstampIcon;
  final String label;
  final String title;
  final String description;
  final int stamps;
  final RewardTheme theme;
  final bool isActive;
  final DateTime? createdAt;
  final RewardStats? stats;
  final String? businessId;
  final String? businessName;
  final String? businessUsername;
  final String? businessPhoto;
  final LoyaltyCardDesign? design;

  RewardProgram({
    required this.id,
    this.logo = '',
    this.stampIcon = '',
    this.unstampIcon = '',
    this.label = '',
    required this.title,
    this.description = '',
    required this.stamps,
    required this.theme,
    this.isActive = true,
    this.createdAt,
    this.stats,
    this.businessId,
    this.businessName,
    this.businessUsername,
    this.businessPhoto,
    this.design,
  });

  bool get hasDesign => design != null && design!.hasLayers;

  String get displayBusinessName =>
      (businessName?.trim().isNotEmpty == true) ? businessName! : 'Business';

  factory RewardProgram.fromJson(Map<String, dynamic> json) {
    String? businessId;
    String? businessName;
    String? businessUsername;
    String? businessPhoto;

    if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      businessId = user['_id']?.toString() ?? user['id']?.toString();
      businessName = user['businessName']?.toString().trim().isNotEmpty == true
          ? user['businessName']?.toString()
          : user['name']?.toString();
      businessUsername = user['username']?.toString();
      businessPhoto = user['profilePhoto']?.toString();
    }

    LoyaltyCardDesign? design;
    final designJson = json['design'];
    if (designJson is Map<String, dynamic>) {
      design = LoyaltyCardDesign.fromJson(designJson);
    } else if (designJson is Map) {
      design = LoyaltyCardDesign.fromJson(Map<String, dynamic>.from(designJson));
    }

    final logo = json['logo']?.toString() ?? '';
    final stampIcon = json['stampIcon']?.toString() ?? '';
    final unstampIcon = json['unstampIcon']?.toString() ?? '';
    final stamps = (json['stamps'] as num?)?.toInt() ?? 10;

    if (design != null) {
      if (design.logo.isEmpty && logo.isNotEmpty) design.logo = logo;
      if (design.stampIcon.isEmpty && stampIcon.isNotEmpty) {
        design.stampIcon = stampIcon;
      }
      if (design.unstampIcon.isEmpty && unstampIcon.isNotEmpty) {
        design.unstampIcon = unstampIcon;
      }
      if (design.stamps != stamps) design.syncStampCount(stamps);
    }

    return RewardProgram(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      logo: logo,
      stampIcon: stampIcon,
      unstampIcon: unstampIcon,
      label: json['label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      stamps: stamps,
      theme: json['theme'] != null
          ? RewardTheme.fromJson(json['theme'] as Map<String, dynamic>)
          : RewardTheme(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      stats: json['stats'] != null
          ? RewardStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      businessId: businessId,
      businessName: businessName,
      businessUsername: businessUsername,
      businessPhoto: businessPhoto,
      design: design,
    );
  }
}

class RewardStats {
  final int totalEnrollments;
  final int totalStampsGiven;

  RewardStats({this.totalEnrollments = 0, this.totalStampsGiven = 0});

  factory RewardStats.fromJson(Map<String, dynamic> json) => RewardStats(
    totalEnrollments: (json['totalEnrollments'] as num?)?.toInt() ?? 0,
    totalStampsGiven: (json['totalStampsGiven'] as num?)?.toInt() ?? 0,
  );
}

class RewardEnrollment {
  final String id;
  final RewardProgram? program;
  final String programId;
  final int stamps;
  final String status;

  RewardEnrollment({
    required this.id,
    this.program,
    this.programId = '',
    this.stamps = 0,
    this.status = 'ACTIVE',
  });

  bool get isCompleted => status == 'COMPLETED';

  factory RewardEnrollment.fromJson(Map<String, dynamic> json) {
    RewardProgram? prog;
    String progId = '';
    if (json['program'] is Map<String, dynamic>) {
      prog = RewardProgram.fromJson(json['program'] as Map<String, dynamic>);
      progId = prog.id;
    } else {
      progId = json['program']?.toString() ?? '';
    }
    return RewardEnrollment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      program: prog,
      programId: progId,
      stamps: (json['stamps'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

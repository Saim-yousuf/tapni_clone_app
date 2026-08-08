import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/constant.dart';

/// A user-created digital card with its own design and link visibility.
class UserCustomCard {
  static const String primaryId = 'primary';

  final String id;
  final String title;
  final String displayName;
  final String? subtitle;
  final String? bio;
  final String cardTemplateId;
  final String? backgroundColorHex;
  final String? textColorHex;
  final String? brandingColorHex;
  final String? labelColorHex;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final List<String> enabledLinkIds;
  /// Optional Canva-style print design for sized exports.
  final BusinessCardDesign? design;

  const UserCustomCard({
    required this.id,
    required this.title,
    required this.displayName,
    this.subtitle,
    this.bio,
    this.cardTemplateId = CardTemplateCatalog.defaultTemplateId,
    this.backgroundColorHex,
    this.textColorHex,
    this.brandingColorHex,
    this.labelColorHex,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.enabledLinkIds = const [],
    this.design,
  });

  bool get isPrimary => id == primaryId;

  factory UserCustomCard.fromJson(Map<String, dynamic> json) {
    final designJson = json['design'];
    return UserCustomCard(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'My Card',
      displayName: json['displayName']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      bio: json['bio']?.toString(),
      cardTemplateId: json['cardTemplateId'] as String? ??
          CardTemplateCatalog.defaultTemplateId,
      backgroundColorHex: json['backgroundColorHex']?.toString(),
      textColorHex: json['textColorHex']?.toString(),
      brandingColorHex: json['brandingColorHex']?.toString(),
      labelColorHex: json['labelColorHex']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      coverPhotoUrl: json['coverPhotoUrl']?.toString(),
      enabledLinkIds: (json['enabledLinkIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      design: designJson is Map
          ? BusinessCardDesign.fromJson(Map<String, dynamic>.from(designJson))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'displayName': displayName,
        if (subtitle != null && subtitle!.isNotEmpty) 'subtitle': subtitle,
        if (bio != null && bio!.isNotEmpty) 'bio': bio,
        'cardTemplateId': cardTemplateId,
        if (backgroundColorHex != null) 'backgroundColorHex': backgroundColorHex,
        if (textColorHex != null) 'textColorHex': textColorHex,
        if (brandingColorHex != null) 'brandingColorHex': brandingColorHex,
        if (labelColorHex != null) 'labelColorHex': labelColorHex,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
        'enabledLinkIds': enabledLinkIds,
        if (design != null && design!.hasLayers) 'design': design!.toJson(),
      };

  UserCustomCard copyWith({
    String? id,
    String? title,
    String? displayName,
    String? subtitle,
    String? bio,
    String? cardTemplateId,
    String? backgroundColorHex,
    String? textColorHex,
    String? brandingColorHex,
    String? labelColorHex,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    List<String>? enabledLinkIds,
    BusinessCardDesign? design,
    bool clearSubtitle = false,
    bool clearBio = false,
    bool clearBackgroundColor = false,
    bool clearCoverPhoto = false,
    bool clearDesign = false,
  }) {
    return UserCustomCard(
      id: id ?? this.id,
      title: title ?? this.title,
      displayName: displayName ?? this.displayName,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      bio: clearBio ? null : (bio ?? this.bio),
      cardTemplateId: cardTemplateId ?? this.cardTemplateId,
      backgroundColorHex:
          clearBackgroundColor ? null : (backgroundColorHex ?? this.backgroundColorHex),
      textColorHex: textColorHex ?? this.textColorHex,
      brandingColorHex: brandingColorHex ?? this.brandingColorHex,
      labelColorHex: labelColorHex ?? this.labelColorHex,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoUrl:
          clearCoverPhoto ? null : (coverPhotoUrl ?? this.coverPhotoUrl),
      enabledLinkIds: enabledLinkIds ?? this.enabledLinkIds,
      design: clearDesign ? null : (design ?? this.design),
    );
  }

  String profileUrl(String username) {
    if (isPrimary || id.isEmpty) {
      return '${Constants.appDomain}/$username';
    }
    return '${Constants.appDomain}/$username?card=$id';
  }

  CardTemplate effectiveTemplate() {
    final base = CardTemplateCatalog.byId(cardTemplateId);
    return CardTemplate(
      id: base.id,
      name: base.name,
      backgroundColor: _colorFromHex(backgroundColorHex) ?? base.backgroundColor,
      textColor: _colorFromHex(textColorHex) ?? base.textColor,
      labelColor: _colorFromHex(labelColorHex) ?? base.labelColor,
      brandingColor: _colorFromHex(brandingColorHex) ?? base.brandingColor,
      isPro: base.isPro,
      isDark: _colorFromHex(backgroundColorHex) != null
          ? _isDarkColor(_colorFromHex(backgroundColorHex)!)
          : base.isDark,
    );
  }

  static Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    return Color(int.parse(value, radix: 16));
  }

  static bool _isDarkColor(Color color) {
    return color.computeLuminance() < 0.5;
  }
}

/// Unified view for QR preview and sharing (primary or custom card).
class CardDisplayData {
  final String id;
  final String title;
  final String name;
  final String? subtitle;
  final String? bio;
  final CardTemplate template;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final List<String> enabledLinkIds;
  final String profileUrl;
  final bool isPrimary;
  final BusinessCardDesign? printDesign;

  const CardDisplayData({
    required this.id,
    required this.title,
    required this.name,
    required this.template,
    required this.profileUrl,
    this.subtitle,
    this.bio,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.enabledLinkIds = const [],
    this.isPrimary = false,
    this.printDesign,
  });
}

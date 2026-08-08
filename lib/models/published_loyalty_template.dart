import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/published_invitation_template.dart';

/// A user-published loyalty card template available to the community.
class PublishedLoyaltyTemplate {
  final String id;
  final PublishedTemplatePublisher publisher;
  final String name;
  final String description;
  final String category;
  final String locale;
  final bool rtl;
  final String previewColor;
  final String accentColor;
  final LoyaltyCardDesign design;
  final String thumbnail;
  final int useCount;
  final DateTime? createdAt;

  PublishedLoyaltyTemplate({
    required this.id,
    required this.publisher,
    required this.name,
    this.description = '',
    this.category = 'cafe',
    this.locale = 'en',
    this.rtl = false,
    this.previewColor = '#1B4332',
    this.accentColor = '#F4A261',
    required this.design,
    this.thumbnail = '',
    this.useCount = 0,
    this.createdAt,
  });

  factory PublishedLoyaltyTemplate.fromJson(Map<String, dynamic> json) {
    final designJson = json['design'];
    LoyaltyCardDesign design;
    if (designJson is Map<String, dynamic>) {
      design = LoyaltyCardDesign.fromJson(designJson);
    } else if (designJson is Map) {
      design = LoyaltyCardDesign.fromJson(Map<String, dynamic>.from(designJson));
    } else {
      design = LoyaltyCardDesign.blank();
    }

    return PublishedLoyaltyTemplate(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      publisher: PublishedTemplatePublisher.fromJson(
        json['publisher'] is Map<String, dynamic>
            ? json['publisher'] as Map<String, dynamic>
            : json['publisher'] is Map
                ? Map<String, dynamic>.from(json['publisher'] as Map)
                : null,
      ),
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'cafe',
      locale: json['locale'] as String? ?? 'en',
      rtl: json['rtl'] == true,
      previewColor: json['previewColor'] as String? ?? '#1B4332',
      accentColor: json['accentColor'] as String? ?? '#F4A261',
      design: design,
      thumbnail: json['thumbnail'] as String? ?? '',
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  LoyaltyCardDesign designCopy() => design.copy();
}

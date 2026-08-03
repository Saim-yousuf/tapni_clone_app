import 'package:tapni_app/models/invitation_design.dart';

class PublishedTemplatePublisher {
  final String id;
  final String name;
  final String username;
  final String profilePhoto;

  PublishedTemplatePublisher({
    required this.id,
    this.name = '',
    this.username = '',
    this.profilePhoto = '',
  });

  factory PublishedTemplatePublisher.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PublishedTemplatePublisher(id: '');
    return PublishedTemplatePublisher(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
    );
  }

  String get displayName =>
      name.isNotEmpty ? name : (username.isNotEmpty ? username : 'User');
}

/// A user-published invitation template available to the community.
class PublishedInvitationTemplate {
  final String id;
  final PublishedTemplatePublisher publisher;
  final String name;
  final String description;
  final String countryCode;
  final String category;
  final String locale;
  final bool rtl;
  final String previewColor;
  final String accentColor;
  final InvitationDesign design;
  final String thumbnail;
  final int useCount;
  final DateTime? createdAt;

  PublishedInvitationTemplate({
    required this.id,
    required this.publisher,
    required this.name,
    this.description = '',
    this.countryCode = 'SA',
    this.category = 'wedding',
    this.locale = 'ar',
    this.rtl = true,
    this.previewColor = '#0A0A0A',
    this.accentColor = '#D4AF37',
    required this.design,
    this.thumbnail = '',
    this.useCount = 0,
    this.createdAt,
  });

  factory PublishedInvitationTemplate.fromJson(Map<String, dynamic> json) {
    final designJson = json['design'];
    InvitationDesign design;
    if (designJson is Map<String, dynamic>) {
      design = InvitationDesign.fromJson(designJson);
    } else {
      design = InvitationDesign();
    }

    return PublishedInvitationTemplate(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      publisher: PublishedTemplatePublisher.fromJson(
        json['publisher'] is Map<String, dynamic>
            ? json['publisher'] as Map<String, dynamic>
            : null,
      ),
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'SA',
      category: json['category'] as String? ?? 'wedding',
      locale: json['locale'] as String? ?? 'ar',
      rtl: json['rtl'] != false,
      previewColor: json['previewColor'] as String? ?? '#0A0A0A',
      accentColor: json['accentColor'] as String? ?? '#D4AF37',
      design: design,
      thumbnail: json['thumbnail'] as String? ?? '',
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Fresh editable copy for the design editor.
  InvitationDesign designCopy() => design.copy();
}

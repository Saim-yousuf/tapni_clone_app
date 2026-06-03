enum SocialPlatform {
  whatsApp,
  linkedIn,
  instagram,
  facebook,
  youTube,
  website,
}

class SocialLink {
  final String id;
  final SocialPlatform platform;
  final String value; // username, phone number, or URL
  final bool isActive;

  SocialLink({
    required this.id,
    required this.platform,
    required this.value,
    this.isActive = true,
  });

  SocialLink copyWith({
    String? id,
    SocialPlatform? platform,
    String? value,
    bool? isActive,
  }) {
    return SocialLink(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
    );
  }

  // ─── API mapping ─────────────────────────────────────────────────────────────

  /// API type string for this platform.
  String get apiType {
    switch (platform) {
      case SocialPlatform.instagram:
        return 'instagram';
      case SocialPlatform.whatsApp:
        return 'whatsapp';
      case SocialPlatform.facebook:
        return 'facebook';
      case SocialPlatform.linkedIn:
      case SocialPlatform.youTube:
      case SocialPlatform.website:
        return 'custom';
    }
  }

  /// Convert to API link object.
  Map<String, String> toApiJson() {
    return {
      'title': platformName,
      'type': apiType,
      'url': fullUrl,
    };
  }

  /// Create from API link object.
  factory SocialLink.fromApiJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'custom';
    final url = json['url'] as String? ?? '';
    final title = json['title'] as String? ?? '';

    SocialPlatform platform;
    switch (type) {
      case 'instagram':
        platform = SocialPlatform.instagram;
        break;
      case 'whatsapp':
        platform = SocialPlatform.whatsApp;
        break;
      case 'facebook':
        platform = SocialPlatform.facebook;
        break;
      default:
        // Map by title if type is custom
        if (title.toLowerCase().contains('linkedin')) {
          platform = SocialPlatform.linkedIn;
        } else if (title.toLowerCase().contains('youtube')) {
          platform = SocialPlatform.youTube;
        } else {
          platform = SocialPlatform.website;
        }
    }

    return SocialLink(
      id: url, // use URL as stable id from API
      platform: platform,
      value: url,
      isActive: true,
    );
  }

  // ─── Display helpers ─────────────────────────────────────────────────────────

  String get platformName {
    switch (platform) {
      case SocialPlatform.whatsApp:
        return 'WhatsApp';
      case SocialPlatform.linkedIn:
        return 'LinkedIn';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.youTube:
        return 'YouTube';
      case SocialPlatform.website:
        return 'Website';
    }
  }

  String get label {
    switch (platform) {
      case SocialPlatform.whatsApp:
        return 'Phone / Link';
      case SocialPlatform.linkedIn:
        return 'LinkedIn Profile';
      case SocialPlatform.instagram:
        return 'Username';
      case SocialPlatform.facebook:
        return 'Profile Link';
      case SocialPlatform.youTube:
        return 'Channel Link';
      case SocialPlatform.website:
        return 'Website URL';
    }
  }

  String get baseUrlPrefix {
    switch (platform) {
      case SocialPlatform.whatsApp:
        return 'https://wa.me/';
      case SocialPlatform.linkedIn:
        return 'https://linkedin.com/in/';
      case SocialPlatform.instagram:
        return 'https://instagram.com/';
      case SocialPlatform.facebook:
        return 'https://facebook.com/';
      case SocialPlatform.youTube:
        return 'https://youtube.com/';
      case SocialPlatform.website:
        return '';
    }
  }

  String get fullUrl {
    if (platform == SocialPlatform.website) {
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return 'https://$value';
      }
      return value;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (platform == SocialPlatform.whatsApp) {
      final cleanPhone = value.replaceAll(RegExp(r'[+\s\-\(\)]'), '');
      return '$baseUrlPrefix$cleanPhone';
    }
    return '$baseUrlPrefix$value';
  }
}

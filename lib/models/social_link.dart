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
    // For WhatsApp, remove any symbols or spaces
    if (platform == SocialPlatform.whatsApp) {
      final cleanPhone = value.replaceAll(RegExp(r'[+\s\-\(\)]'), '');
      return '$baseUrlPrefix$cleanPhone';
    }
    return '$baseUrlPrefix$value';
  }
}

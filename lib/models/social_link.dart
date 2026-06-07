enum SocialPlatform {
  behance,
  calendly,
  contact,
  email,
  eventbrite,
  github,
  googleReview,
  googleMaps,
  instagram,
  linkedIn,
  meetup,
  mixcloud,
  patreon,
  signal,
  snapchat,
  soundcloud,
  spoonFork,
  spotify,
  threads,
  tiktok,
  tripadvisor,
  vk,
  vsco,
  wave,
  whatsApp,
  yandexMusic,
  zillow,
}

class SocialLink {
  final String id;
  final SocialPlatform platform;
  final String? templateId;
  final String? customLabel;
  final String? fieldLabel;
  final String? fieldType;
  final String? logoUrl;
  final String? url;
  final Map<String, String>? bankDetails;
  final Map<String, String>? contactCard;
  final bool isCustom;
  final String value; // username, phone number, or URL
  final bool isActive;
  final bool isPublic;

  SocialLink({
    required this.id,
    required this.platform,
    this.templateId,
    this.customLabel,
    this.fieldLabel,
    this.fieldType,
    this.logoUrl,
    this.url,
    this.bankDetails,
    this.contactCard,
    this.isCustom = false,
    required this.value,
    this.isActive = true,
    this.isPublic = true,
  });

  SocialLink copyWith({
    String? id,
    SocialPlatform? platform,
    String? templateId,
    String? customLabel,
    String? fieldLabel,
    String? fieldType,
    String? logoUrl,
    String? url,
    Map<String, String>? bankDetails,
    Map<String, String>? contactCard,
    bool? isCustom,
    String? value,
    bool? isActive,
    bool? isPublic,
  }) {
    return SocialLink(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      templateId: templateId ?? this.templateId,
      customLabel: customLabel ?? this.customLabel,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      fieldType: fieldType ?? this.fieldType,
      logoUrl: logoUrl ?? this.logoUrl,
      url: url ?? this.url,
      bankDetails: bankDetails ?? this.bankDetails,
      contactCard: contactCard ?? this.contactCard,
      isCustom: isCustom ?? this.isCustom,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
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
      case SocialPlatform.snapchat:
        return 'snapchat';
      case SocialPlatform.linkedIn:
        return 'linkedin';
      case SocialPlatform.github:
        return 'github';
      case SocialPlatform.spotify:
        return 'spotify';
      case SocialPlatform.threads:
        return 'threads';
      case SocialPlatform.tiktok:
        return 'tiktok';
      default:
        return 'custom';
    }
  }

  /// Convert to API link object.
  Map<String, dynamic> toApiJson() {
    return {
      if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id)) '_id': id,
      if (templateId != null && templateId!.isNotEmpty)
        'templateId': templateId,
      'label': platformName,
      'title': platformName,
      'type': fieldType ?? apiType,
      'value': value,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logo': logoUrl,
      if (bankDetails != null) 'bankDetails': bankDetails,
      if (contactCard != null) 'contactCard': contactCard,
      'isCustom': isCustom,
      'url': fullUrl,
      'isActive': isActive,
      'isPublic': isPublic,
    };
  }

  /// Create from API link object.
  factory SocialLink.fromApiJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'custom';
    final url = json['url'] as String? ?? '';
    final title = json['title'] as String? ?? json['label'] as String? ?? '';
    final value = json['value'] as String? ?? url;
    final logo = json['logo'] as String?;
    final bankDetailsJson = json['bankDetails'] as Map<String, dynamic>?;
    final contactCardJson = json['contactCard'] as Map<String, dynamic>?;
    final templateId = json['templateId']?.toString();
    final fieldLabel = json['fieldLabel']?.toString();

    SocialPlatform platform = SocialPlatform.wave;
    final combined = "${type.toLowerCase()} ${title.toLowerCase()}";

    if (combined.contains('whatsapp')) {
      platform = SocialPlatform.whatsApp;
    } else if (combined.contains('linkedin')) {
      platform = SocialPlatform.linkedIn;
    } else if (combined.contains('instagram')) {
      platform = SocialPlatform.instagram;
    } else if (combined.contains('behance')) {
      platform = SocialPlatform.behance;
    } else if (combined.contains('calendly')) {
      platform = SocialPlatform.calendly;
    } else if (combined.contains('contact')) {
      platform = SocialPlatform.contact;
    } else if (combined.contains('email')) {
      platform = SocialPlatform.email;
    } else if (combined.contains('eventbrite')) {
      platform = SocialPlatform.eventbrite;
    } else if (combined.contains('github')) {
      platform = SocialPlatform.github;
    } else if (combined.contains('googlereview') ||
        combined.contains('google-logo-review')) {
      platform = SocialPlatform.googleReview;
    } else if (combined.contains('googlemaps') ||
        combined.contains('google-maps') ||
        combined.contains('maps')) {
      platform = SocialPlatform.googleMaps;
    } else if (combined.contains('meetup')) {
      platform = SocialPlatform.meetup;
    } else if (combined.contains('mixcloud')) {
      platform = SocialPlatform.mixcloud;
    } else if (combined.contains('patreon')) {
      platform = SocialPlatform.patreon;
    } else if (combined.contains('signal')) {
      platform = SocialPlatform.signal;
    } else if (combined.contains('snapchat')) {
      platform = SocialPlatform.snapchat;
    } else if (combined.contains('soundcloud')) {
      platform = SocialPlatform.soundcloud;
    } else if (combined.contains('spoon') ||
        combined.contains('fork') ||
        combined.contains('menu')) {
      platform = SocialPlatform.spoonFork;
    } else if (combined.contains('spotify')) {
      platform = SocialPlatform.spotify;
    } else if (combined.contains('threads')) {
      platform = SocialPlatform.threads;
    } else if (combined.contains('tiktok')) {
      platform = SocialPlatform.tiktok;
    } else if (combined.contains('tripadvisor')) {
      platform = SocialPlatform.tripadvisor;
    } else if (combined.contains('vk')) {
      platform = SocialPlatform.vk;
    } else if (combined.contains('vsco')) {
      platform = SocialPlatform.vsco;
    } else if (combined.contains('wave')) {
      platform = SocialPlatform.wave;
    } else if (combined.contains('yandex')) {
      platform = SocialPlatform.yandexMusic;
    } else if (combined.contains('zillow')) {
      platform = SocialPlatform.zillow;
    }

    return SocialLink(
      id:
          json['_id']?.toString() ??
          json['id']?.toString() ??
          (url.isNotEmpty
              ? url
              : DateTime.now().millisecondsSinceEpoch.toString()),
      platform: platform,
      templateId: templateId,
      customLabel: title.isNotEmpty ? title : null,
      fieldLabel: fieldLabel,
      fieldType: type,
      isCustom: json['isCustom'] as bool? ?? false,
      logoUrl: logo,
      url: url,
      bankDetails: bankDetailsJson?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      contactCard: contactCardJson?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      value: value,
      isActive: json['isActive'] as bool? ?? true,
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  String get platformName => customLabel?.isNotEmpty == true
      ? customLabel!
      : getPlatformName(platform);

  static String getPlatformName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.behance:
        return 'Behance';
      case SocialPlatform.calendly:
        return 'Calendly';
      case SocialPlatform.contact:
        return 'Contact Card';
      case SocialPlatform.email:
        return 'Email';
      case SocialPlatform.eventbrite:
        return 'Eventbrite';
      case SocialPlatform.github:
        return 'GitHub';
      case SocialPlatform.googleReview:
        return 'Google Review';
      case SocialPlatform.googleMaps:
        return 'Google Maps';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.linkedIn:
        return 'LinkedIn';
      case SocialPlatform.meetup:
        return 'Meetup';
      case SocialPlatform.mixcloud:
        return 'Mixcloud';
      case SocialPlatform.patreon:
        return 'Patreon';
      case SocialPlatform.signal:
        return 'Signal';
      case SocialPlatform.snapchat:
        return 'Snapchat';
      case SocialPlatform.soundcloud:
        return 'SoundCloud';
      case SocialPlatform.spoonFork:
        return 'Restaurant Menu';
      case SocialPlatform.spotify:
        return 'Spotify';
      case SocialPlatform.threads:
        return 'Threads';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.tripadvisor:
        return 'Tripadvisor';
      case SocialPlatform.vk:
        return 'VK';
      case SocialPlatform.vsco:
        return 'VSCO';
      case SocialPlatform.wave:
        return 'Wave Link';
      case SocialPlatform.whatsApp:
        return 'WhatsApp';
      case SocialPlatform.yandexMusic:
        return 'Yandex Music';
      case SocialPlatform.zillow:
        return 'Zillow';
    }
  }

  String get label {
    if (fieldLabel?.isNotEmpty == true) return fieldLabel!;
    switch (platform) {
      case SocialPlatform.email:
        return 'Email address';
      case SocialPlatform.whatsApp:
        return 'Phone number (with country code)';
      case SocialPlatform.signal:
        return 'Signal phone number/username';
      case SocialPlatform.instagram:
        return 'Instagram username';
      case SocialPlatform.linkedIn:
        return 'LinkedIn username/link';
      case SocialPlatform.github:
        return 'GitHub username';
      case SocialPlatform.snapchat:
        return 'Snapchat username';
      case SocialPlatform.threads:
        return 'Threads username';
      case SocialPlatform.tiktok:
        return 'TikTok username';
      case SocialPlatform.vsco:
        return 'VSCO username';
      case SocialPlatform.behance:
        return 'Behance username';
      case SocialPlatform.soundcloud:
        return 'SoundCloud username';
      case SocialPlatform.mixcloud:
        return 'Mixcloud username';
      case SocialPlatform.patreon:
        return 'Patreon username';
      case SocialPlatform.calendly:
        return 'Calendly profile link';
      case SocialPlatform.eventbrite:
        return 'Eventbrite link';
      case SocialPlatform.meetup:
        return 'Meetup link';
      case SocialPlatform.tripadvisor:
        return 'Tripadvisor link';
      case SocialPlatform.zillow:
        return 'Zillow link';
      case SocialPlatform.spotify:
        return 'Spotify link';
      case SocialPlatform.yandexMusic:
        return 'Yandex Music link';
      case SocialPlatform.googleReview:
        return 'Google Review link';
      case SocialPlatform.googleMaps:
        return 'Google Maps location link';
      case SocialPlatform.contact:
        return 'Contact card details/link';
      case SocialPlatform.spoonFork:
        return 'Menu or reservation link';
      case SocialPlatform.vk:
        return 'VK profile link';
      case SocialPlatform.wave:
        return 'Custom URL';
    }
  }

  String get baseUrlPrefix {
    switch (platform) {
      case SocialPlatform.behance:
        return 'https://behance.net/';
      case SocialPlatform.calendly:
        return 'https://calendly.com/';
      case SocialPlatform.github:
        return 'https://github.com/';
      case SocialPlatform.instagram:
        return 'https://instagram.com/';
      case SocialPlatform.linkedIn:
        return 'https://linkedin.com/in/';
      case SocialPlatform.mixcloud:
        return 'https://mixcloud.com/';
      case SocialPlatform.patreon:
        return 'https://patreon.com/';
      case SocialPlatform.snapchat:
        return 'https://snapchat.com/add/';
      case SocialPlatform.soundcloud:
        return 'https://soundcloud.com/';
      case SocialPlatform.spotify:
        return 'https://open.spotify.com/';
      case SocialPlatform.threads:
        return 'https://threads.net/@';
      case SocialPlatform.tiktok:
        return 'https://tiktok.com/@';
      case SocialPlatform.vk:
        return 'https://vk.com/';
      case SocialPlatform.vsco:
        return 'https://vsco.co/';
      case SocialPlatform.whatsApp:
        return 'https://wa.me/';
      default:
        return '';
    }
  }

  String get assetPath => getAssetPath(platform);

  static String getAssetPath(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.behance:
        return 'assets/images/png/behance-logo.png';
      case SocialPlatform.calendly:
        return 'assets/images/png/calendly.png';
      case SocialPlatform.contact:
        return 'assets/images/png/contact-logo.png';
      case SocialPlatform.email:
        return 'assets/images/png/email-logo.png';
      case SocialPlatform.eventbrite:
        return 'assets/images/png/eventbrite-logo.png';
      case SocialPlatform.github:
        return 'assets/images/png/github-logo.png';
      case SocialPlatform.googleReview:
        return 'assets/images/png/google-logo-review.png';
      case SocialPlatform.googleMaps:
        return 'assets/images/png/google-maps.png';
      case SocialPlatform.instagram:
        return 'assets/images/png/instagram-logo.png';
      case SocialPlatform.linkedIn:
        return 'assets/images/png/linkedin-logo.png';
      case SocialPlatform.meetup:
        return 'assets/images/png/meetup-logo.png';
      case SocialPlatform.mixcloud:
        return 'assets/images/png/mixcloud-logo.png';
      case SocialPlatform.patreon:
        return 'assets/images/png/patreon-logo.png';
      case SocialPlatform.signal:
        return 'assets/images/png/signal-logo.png';
      case SocialPlatform.snapchat:
        return 'assets/images/png/snapchatlogo.png';
      case SocialPlatform.soundcloud:
        return 'assets/images/png/soundcloud-logo.png';
      case SocialPlatform.spoonFork:
        return 'assets/images/png/spoon-fork.png';
      case SocialPlatform.spotify:
        return 'assets/images/png/spotify-logo.png';
      case SocialPlatform.threads:
        return 'assets/images/png/threads-logo.png';
      case SocialPlatform.tiktok:
        return 'assets/images/png/tiktok-logo.png';
      case SocialPlatform.tripadvisor:
        return 'assets/images/png/tripadvisor-logo.png';
      case SocialPlatform.vk:
        return 'assets/images/png/vk-logo.png';
      case SocialPlatform.vsco:
        return 'assets/images/png/vsco-logo.png';
      case SocialPlatform.wave:
        return 'assets/images/png/wave.png';
      case SocialPlatform.whatsApp:
        return 'assets/images/png/whatsapp-logo.png';
      case SocialPlatform.yandexMusic:
        return 'assets/images/png/yandexmusic-logo.png';
      case SocialPlatform.zillow:
        return 'assets/images/png/zillow-logo.png';
    }
  }

  String get fullUrl {
    if (bankDetails != null) {
      final identifier = bankDetails!['iban']?.isNotEmpty == true
          ? bankDetails!['iban']!
          : bankDetails!['accountNumber'] ?? '';
      return identifier.isEmpty ? value : 'bank:$identifier';
    }
    if (contactCard != null) {
      final identifier = contactCard!['email']?.isNotEmpty == true
          ? contactCard!['email']!
          : contactCard!['phone'] ?? value;
      return identifier.isEmpty ? value : 'contact:$identifier';
    }
    if (url?.isNotEmpty == true) return url!;
    if (baseUrlPrefix.isEmpty) {
      if (platform == SocialPlatform.email && !value.startsWith('mailto:')) {
        return 'mailto:$value';
      }
      if (!value.startsWith('http://') &&
          !value.startsWith('https://') &&
          platform != SocialPlatform.email) {
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

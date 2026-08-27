import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/service_schedule.dart';

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

/// One selectable child under a profile link (e.g. a WhatsApp number).
class LinkEntry {
  final String id;
  final String name;
  final String value;
  final String? logo;

  const LinkEntry({
    required this.id,
    required this.name,
    required this.value,
    this.logo,
  });

  LinkEntry copyWith({
    String? id,
    String? name,
    String? value,
    String? logo,
  }) {
    return LinkEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      logo: logo ?? this.logo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id)) '_id': id,
      'name': name,
      'value': value,
      if (logo != null && logo!.isNotEmpty) 'logo': logo,
    };
  }

  factory LinkEntry.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ??
        json['label']?.toString() ??
        json['title']?.toString() ??
        '';
    return LinkEntry(
      id:
          json['_id']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      value: json['value']?.toString() ?? '',
      logo: json['logo']?.toString(),
    );
  }
}

class SocialLink {
  final String id;
  final SocialPlatform platform;
  final String? templateId;
  final String? customLabel;
  final String? fieldLabel;
  final String? fieldType;
  final String? actionType;
  final String? logoUrl;
  final String? url;
  final Map<String, String>? bankDetails;
  final Map<String, String>? contactCard;
  final List<CatalogItem>? catalogItems;
  final List<String>? catalogCategories;
  final String? catalogType;
  final String? fileExt;
  final ServiceSchedule? serviceSchedule;
  final List<LinkEntry>? entries;
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
    this.actionType,
    this.logoUrl,
    this.url,
    this.bankDetails,
    this.contactCard,
    this.catalogItems,
    this.catalogCategories,
    this.catalogType,
    this.fileExt,
    this.serviceSchedule,
    this.entries,
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
    String? actionType,
    String? logoUrl,
    String? url,
    Map<String, String>? bankDetails,
    Map<String, String>? contactCard,
    List<CatalogItem>? catalogItems,
    List<String>? catalogCategories,
    String? catalogType,
    String? fileExt,
    ServiceSchedule? serviceSchedule,
    List<LinkEntry>? entries,
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
      actionType: actionType ?? this.actionType,
      logoUrl: logoUrl ?? this.logoUrl,
      url: url ?? this.url,
      bankDetails: bankDetails ?? this.bankDetails,
      contactCard: contactCard ?? this.contactCard,
      catalogItems: catalogItems ?? this.catalogItems,
      catalogCategories: catalogCategories ?? this.catalogCategories,
      catalogType: catalogType ?? this.catalogType,
      fileExt: fileExt ?? this.fileExt,
      serviceSchedule: serviceSchedule ?? this.serviceSchedule,
      entries: entries ?? this.entries,
      isCustom: isCustom ?? this.isCustom,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  bool get hasMultipleEntries =>
      entries != null && entries!.where((e) => e.value.trim().isNotEmpty).length > 1;

  /// Entries for picker / launch; falls back to primary value when none stored.
  List<LinkEntry> get effectiveEntries {
    final stored = entries
        ?.where((e) => e.value.trim().isNotEmpty)
        .toList();
    if (stored != null && stored.isNotEmpty) return stored;
    if (value.trim().isEmpty) return const [];
    return [
      LinkEntry(
        id: id,
        name: platformName,
        value: value,
        logo: logoUrl,
      ),
    ];
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
      if (templateId != null &&
          RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(templateId!))
        'templateId': templateId,
      'label': platformName,
      'title': platformName,
      'type': isGalleryLink
          ? 'gallery'
          : isDocumentLink
          ? 'document'
          : (catalogItems != null && catalogItems!.isNotEmpty
                ? 'menu_catalog'
                : (fieldType ?? apiType)),
      'value': isGalleryLink ? 'gallery' : value,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logo': logoUrl,
      if (bankDetails != null) 'bankDetails': bankDetails,
      if (contactCard != null) 'contactCard': contactCard,
      if (catalogItems != null && catalogItems!.isNotEmpty)
        'catalogItems': catalogItems!.map((e) => e.toJson()).toList(),
      if (entries != null && entries!.isNotEmpty)
        'entries': entries!.map((e) => e.toJson()).toList(),
      if (!isDocumentLink &&
          catalogCategories != null &&
          catalogCategories!.isNotEmpty)
        'catalogCategories': catalogCategories,
      if (isCatalogLink && catalogType != null) 'catalogType': catalogType,
      if (isDocumentLink && catalogType != null) 'catalogType': catalogType,
      if (isDocumentLink && (fileExt?.trim().isNotEmpty ?? false))
        'fileExt': fileExt!.trim().toLowerCase(),
      if (serviceSchedule != null) 'serviceSchedule': serviceSchedule!.toJson(),
      'isCustom': isCustom,
      'url': isGalleryLink ? 'gallery:' : fullUrl,
      'isActive': isActive,
      'isPublic': isPublic,
    };
  }

  bool get isGalleryLink {
    if (actionType == 'gallery' || fieldType == 'gallery') return true;
    if (url?.startsWith('gallery:') == true) return true;
    return false;
  }

  bool get isDocumentLink {
    if (isGalleryLink) return false;
    if (fieldType == 'document' || actionType == 'document') return true;
    if (catalogType == 'documents') return true;
    return false;
  }

  bool get isCatalogLink {
    if (isDocumentLink || isGalleryLink) return false;
    if (actionType == 'link' ||
        actionType == 'contact_card' ||
        actionType == 'gallery') {
      return false;
    }
    // Real catalogs are tagged by actionType / items / catalog: url.
    // Do NOT trust catalogType alone — User.links.catalogType defaults to
    // "catalog" in Mongo for every link, which falsely opened the menu sheet.
    if (actionType == 'menu_catalog') return true;
    if (catalogItems != null && catalogItems!.isNotEmpty) return true;
    if (url?.startsWith('catalog:') == true) return true;
    if (fieldType == 'menu_catalog') {
      return url?.startsWith('catalog:') == true ||
          (catalogItems != null && catalogItems!.isNotEmpty);
    }
    return false;
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
    final catalogItemsJson = json['catalogItems'] as List<dynamic>?;
    final entriesJson = json['entries'] as List<dynamic>?;
    final templateId = json['templateId']?.toString();
    final fieldLabel = json['fieldLabel']?.toString();
    final actionType = json['actionType'] as String?;

    SocialPlatform platform = SocialPlatform.wave;
    final combined =
        "${type.toLowerCase()} ${title.toLowerCase()} ${url.toLowerCase()}";
    final isDocumentType =
        type == 'document' ||
        actionType == 'document' ||
        json['catalogType']?.toString() == 'documents';
    final isGalleryType =
        type == 'gallery' ||
        actionType == 'gallery' ||
        url.startsWith('gallery:');

    if (isGalleryType) {
      platform = SocialPlatform.wave;
    } else if (isDocumentType) {
      platform = SocialPlatform.wave;
    } else if (combined.contains('whatsapp')) {
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
        combined.contains('menu') ||
        combined.contains('product')) {
      platform = SocialPlatform.spoonFork;
    } else if (combined.contains('menu_catalog') ||
        combined.contains('catalog:') ||
        type == 'menu_catalog') {
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
      customLabel: title.isNotEmpty
          ? title
          : (isGalleryType ? 'Gallery' : null),
      fieldLabel: fieldLabel,
      fieldType: isGalleryType
          ? 'gallery'
          : isDocumentType
          ? 'document'
          : type,
      actionType: isGalleryType
          ? 'gallery'
          : isDocumentType
          ? 'document'
          : actionType,
      isCustom: json['isCustom'] as bool? ?? false,
      logoUrl: logo,
      url: url,
      bankDetails: bankDetailsJson?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      contactCard: contactCardJson?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      catalogItems: !isDocumentType &&
              catalogItemsJson != null &&
              catalogItemsJson.isNotEmpty
          ? catalogItemsJson
              .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      entries: entriesJson != null && entriesJson.isNotEmpty
          ? entriesJson
              .whereType<Map>()
              .map((e) => LinkEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      catalogType: () {
        final raw = json['catalogType']?.toString().trim();
        if (raw == null || raw.isEmpty) return null;
        if (isDocumentType) return 'documents';
        if (isGalleryType) return null;
        final isMenu =
            actionType == 'menu_catalog' ||
            type == 'menu_catalog' ||
            url.startsWith('catalog:') ||
            (catalogItemsJson != null && catalogItemsJson.isNotEmpty);
        return isMenu ? raw : null;
      }(),
      fileExt: json['fileExt']?.toString(),
      catalogCategories: (json['catalogCategories'] as List<dynamic>?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      serviceSchedule: json['serviceSchedule'] != null
          ? ServiceSchedule.fromJson(
              json['serviceSchedule'] as Map<String, dynamic>,
            )
          : null,
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

  bool get _looksLikeWhatsApp {
    if (platform == SocialPlatform.whatsApp) return true;
    final label = platformName.toLowerCase();
    final type = (fieldType ?? '').toLowerCase();
    return label.contains('whatsapp') || type.contains('whatsapp');
  }

  bool get _looksLikeEmail {
    if (platform == SocialPlatform.email) return true;
    final type = (fieldType ?? '').toLowerCase();
    return type == 'email';
  }

  /// Launch URL for [entryValue], using this link's platform / fieldType rules.
  String urlForValue(String entryValue) {
    final v = entryValue.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('mailto:') ||
        v.startsWith('tel:')) {
      return v;
    }
    if (_looksLikeEmail) {
      return v.startsWith('mailto:') ? v : 'mailto:$v';
    }
    if (_looksLikeWhatsApp ||
        (fieldType == 'phone' && platform == SocialPlatform.whatsApp)) {
      final cleanPhone = v.replaceAll(RegExp(r'[+\s\-\(\)]'), '');
      return 'https://wa.me/$cleanPhone';
    }
    if (fieldType == 'phone') {
      final cleanPhone = v.replaceAll(RegExp(r'[+\s\-\(\)]'), '');
      return 'tel:$cleanPhone';
    }
    if (baseUrlPrefix.isNotEmpty) {
      return '$baseUrlPrefix$v';
    }
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      return 'https://$v';
    }
    return v;
  }

  String get fullUrl {
    if (isGalleryLink) {
      return url?.isNotEmpty == true ? url! : 'gallery:';
    }
    if (isDocumentLink) {
      if (url != null &&
          url!.isNotEmpty &&
          !url!.startsWith('catalog:')) {
        return url!;
      }
      return value;
    }
    if (fieldType == 'bank' && bankDetails != null) {
      final identifier = bankDetails!['iban']?.isNotEmpty == true
          ? bankDetails!['iban']!
          : bankDetails!['accountNumber'] ?? '';
      return identifier.isEmpty ? value : 'bank:$identifier';
    }
    if ((actionType == 'contact_card' || platform == SocialPlatform.contact) &&
        contactCard != null) {
      final identifier = contactCard!['email']?.isNotEmpty == true
          ? contactCard!['email']!
          : contactCard!['phone'] ?? value;
      return identifier.isEmpty ? value : 'contact:$identifier';
    }
    if (catalogItems != null && catalogItems!.isNotEmpty) {
      return 'catalog:$id';
    }
    // Prefer computed launch URL from value so WhatsApp / phone stay correct
    // even when a stale absolute `url` was stored for a different entry.
    if (hasMultipleEntries || url == null || url!.isEmpty) {
      return urlForValue(value);
    }
    // Single-entry: keep stored url when it already looks absolute.
    if (url!.startsWith('http://') ||
        url!.startsWith('https://') ||
        url!.startsWith('mailto:') ||
        url!.startsWith('tel:')) {
      return url!;
    }
    return urlForValue(value);
  }
}

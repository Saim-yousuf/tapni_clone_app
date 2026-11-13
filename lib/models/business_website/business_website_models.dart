import 'package:tapni_app/utils/api_endpoint.dart';

class WebsiteCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int sortOrder;
  final bool isActive;

  const WebsiteCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory WebsiteCategory.fromJson(Map<String, dynamic> json) {
    return WebsiteCategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class WebsiteSubcategory {
  final String id;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final String icon;
  final int sortOrder;
  final bool isActive;

  const WebsiteSubcategory({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description = '',
    this.icon = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory WebsiteSubcategory.fromJson(Map<String, dynamic> json) {
    return WebsiteSubcategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class WebsiteTemplateSummary {
  final String id;
  final String name;
  final String description;
  final String thumbnail;
  final String defaultThemeColor;
  /// Template-owned default hero/front cover (absolute URL when from API).
  final String defaultFrontImage;
  final String templateType;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final int sortOrder;
  final bool isActive;

  const WebsiteTemplateSummary({
    required this.id,
    required this.name,
    this.description = '',
    this.thumbnail = '',
    this.defaultThemeColor = '#ff6fa5',
    this.defaultFrontImage = '',
    this.templateType = 'menu',
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory WebsiteTemplateSummary.fromJson(Map<String, dynamic> json) {
    return WebsiteTemplateSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      defaultThemeColor:
          json['defaultThemeColor']?.toString() ?? '#ff6fa5',
      defaultFrontImage: json['defaultFrontImage']?.toString() ?? '',
      templateType: json['templateType']?.toString() ?? 'menu',
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      subcategoryId: json['subcategoryId']?.toString(),
      subcategoryName: json['subcategoryName']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class BusinessWebsiteCatalog {
  final List<WebsiteCategory> categories;
  final List<WebsiteSubcategory> subcategories;
  final List<WebsiteTemplateSummary> templates;

  const BusinessWebsiteCatalog({
    required this.categories,
    required this.subcategories,
    required this.templates,
  });

  factory BusinessWebsiteCatalog.fromJson(Map<String, dynamic> json) {
    List<Map> asList(dynamic raw) =>
        (raw as List? ?? const []).whereType<Map>().toList();

    return BusinessWebsiteCatalog(
      categories: asList(json['categories'])
          .map((e) => WebsiteCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      subcategories: asList(json['subcategories'])
          .map(
            (e) => WebsiteSubcategory.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      templates: asList(json['templates'])
          .map(
            (e) =>
                WebsiteTemplateSummary.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class BusinessWebsiteDesign {
  final String themeColor;
  final String fontStyle;
  final String buttonStyle;
  final String cardStyle;
  /// Owner explicitly chose an accent (survives template switch).
  final bool hasCustomThemeColor;
  /// Empty → template keeps its original homepage heading.
  final String homepageHeadline;
  /// Missing on legacy docs → treated as true.
  final bool showLogo;
  final bool showBio;
  /// Absolute URL for storefront hero/front image (default Ember-style cover).
  final String frontImage;
  /// True when using the shared default cover (not an owner upload).
  final bool frontImageIsDefault;

  const BusinessWebsiteDesign({
    this.themeColor = '#ff6fa5',
    this.fontStyle = 'modern',
    this.buttonStyle = 'pill',
    this.cardStyle = 'bordered',
    this.hasCustomThemeColor = false,
    this.homepageHeadline = '',
    this.showLogo = true,
    this.showBio = true,
    this.frontImage = '',
    this.frontImageIsDefault = true,
  });

  Map<String, dynamic> toJson() => {
        'themeColor': themeColor,
        'fontStyle': fontStyle,
        'buttonStyle': buttonStyle,
        'cardStyle': cardStyle,
        'hasCustomThemeColor': hasCustomThemeColor,
        'homepageHeadline': homepageHeadline,
        'showLogo': showLogo,
        'showBio': showBio,
        'frontImage': frontImage,
        'frontImageIsDefault': frontImageIsDefault,
      };

  /// Partial payload for PUT design merge (does not wipe server fields).
  /// [frontImageOverride] — data URI upload, empty string to reset default,
  /// or null to leave front image unchanged on the server.
  Map<String, dynamic> toDesignPatchJson({String? frontImageOverride}) => {
        'themeColor': themeColor,
        'hasCustomThemeColor': hasCustomThemeColor,
        'homepageHeadline': homepageHeadline,
        'showLogo': showLogo,
        'showBio': showBio,
        if (frontImageOverride != null) 'frontImage': frontImageOverride,
      };

  factory BusinessWebsiteDesign.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BusinessWebsiteDesign();
    final front = json['frontImage']?.toString() ?? '';
    final isDefault = json['frontImageIsDefault'] == true ||
        front.isEmpty ||
        front.contains('/uploads/website-templates/ember-kitchen-cover.jpg') ||
        front.contains('/uploads/website-templates/black-olive-cover.jpg') ||
        front.contains('/uploads/website-templates/menu-default-cover.jpg');
    return BusinessWebsiteDesign(
      themeColor: json['themeColor']?.toString() ?? '#ff6fa5',
      fontStyle: json['fontStyle']?.toString() ?? 'modern',
      buttonStyle: json['buttonStyle']?.toString() ?? 'pill',
      cardStyle: json['cardStyle']?.toString() ?? 'bordered',
      hasCustomThemeColor: json['hasCustomThemeColor'] == true,
      homepageHeadline: json['homepageHeadline']?.toString() ?? '',
      showLogo: json['showLogo'] != false,
      showBio: json['showBio'] != false,
      frontImage: front,
      frontImageIsDefault: isDefault,
    );
  }

  BusinessWebsiteDesign copyWith({
    String? themeColor,
    String? fontStyle,
    String? buttonStyle,
    String? cardStyle,
    bool? hasCustomThemeColor,
    String? homepageHeadline,
    bool? showLogo,
    bool? showBio,
    String? frontImage,
    bool? frontImageIsDefault,
  }) {
    return BusinessWebsiteDesign(
      themeColor: themeColor ?? this.themeColor,
      fontStyle: fontStyle ?? this.fontStyle,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      cardStyle: cardStyle ?? this.cardStyle,
      hasCustomThemeColor: hasCustomThemeColor ?? this.hasCustomThemeColor,
      homepageHeadline: homepageHeadline ?? this.homepageHeadline,
      showLogo: showLogo ?? this.showLogo,
      showBio: showBio ?? this.showBio,
      frontImage: frontImage ?? this.frontImage,
      frontImageIsDefault: frontImageIsDefault ?? this.frontImageIsDefault,
    );
  }
}

/// One day in weeklyHours (open/close are "HH:mm").
class WebsiteDayHours {
  final bool closed;
  final String open;
  final String close;

  const WebsiteDayHours({
    this.closed = false,
    this.open = '11:00',
    this.close = '23:00',
  });

  factory WebsiteDayHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WebsiteDayHours();
    return WebsiteDayHours(
      closed: json['closed'] == true,
      open: json['open']?.toString() ?? '11:00',
      close: json['close']?.toString() ?? '23:00',
    );
  }

  Map<String, dynamic> toJson() => {
        'closed': closed,
        'open': open,
        'close': close,
      };

  WebsiteDayHours copyWith({bool? closed, String? open, String? close}) {
    return WebsiteDayHours(
      closed: closed ?? this.closed,
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }
}

/// Menu storefront ordering rules on BusinessWebsite.
class WebsiteOrdering {
  static const dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const dayLabels = {
    'mon': 'Monday',
    'tue': 'Tuesday',
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
    'sat': 'Saturday',
    'sun': 'Sunday',
  };

  final bool ordersPaused;
  final bool acceptPickup;
  final bool acceptDelivery;
  final double minOrderAmount;
  final double deliveryFee;
  final double freeDeliveryAbove;
  final List<String> deliveryAreas;
  final int prepTimeMinutes;
  final bool tipsEnabled;
  final bool scheduleOrdersEnabled;
  final String timezone;
  final Map<String, WebsiteDayHours> weeklyHours;
  final bool isOpenNow;

  const WebsiteOrdering({
    this.ordersPaused = false,
    this.acceptPickup = true,
    this.acceptDelivery = true,
    this.minOrderAmount = 0,
    this.deliveryFee = 0,
    this.freeDeliveryAbove = 0,
    this.deliveryAreas = const [],
    this.prepTimeMinutes = 25,
    this.tipsEnabled = false,
    this.scheduleOrdersEnabled = false,
    this.timezone = 'Asia/Karachi',
    this.weeklyHours = const {},
    this.isOpenNow = true,
  });

  Map<String, WebsiteDayHours> get resolvedWeeklyHours {
    if (weeklyHours.length >= dayKeys.length) return weeklyHours;
    final out = <String, WebsiteDayHours>{};
    for (final k in dayKeys) {
      out[k] = weeklyHours[k] ?? const WebsiteDayHours();
    }
    return out;
  }

  factory WebsiteOrdering.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WebsiteOrdering();
    final hoursRaw = json['weeklyHours'];
    final hours = <String, WebsiteDayHours>{};
    if (hoursRaw is Map) {
      for (final k in dayKeys) {
        final v = hoursRaw[k];
        hours[k] = WebsiteDayHours.fromJson(
          v is Map ? Map<String, dynamic>.from(v) : null,
        );
      }
    }
    final areas = <String>[];
    final areasRaw = json['deliveryAreas'];
    if (areasRaw is List) {
      for (final a in areasRaw) {
        final t = a?.toString().trim() ?? '';
        if (t.isNotEmpty) areas.add(t);
      }
    }
    return WebsiteOrdering(
      ordersPaused: json['ordersPaused'] == true,
      acceptPickup: json['acceptPickup'] != false,
      acceptDelivery: json['acceptDelivery'] != false,
      minOrderAmount: (json['minOrderAmount'] is num)
          ? (json['minOrderAmount'] as num).toDouble()
          : double.tryParse('${json['minOrderAmount']}') ?? 0,
      deliveryFee: (json['deliveryFee'] is num)
          ? (json['deliveryFee'] as num).toDouble()
          : double.tryParse('${json['deliveryFee']}') ?? 0,
      freeDeliveryAbove: (json['freeDeliveryAbove'] is num)
          ? (json['freeDeliveryAbove'] as num).toDouble()
          : double.tryParse('${json['freeDeliveryAbove']}') ?? 0,
      deliveryAreas: areas,
      prepTimeMinutes: (json['prepTimeMinutes'] is num)
          ? (json['prepTimeMinutes'] as num).toInt()
          : int.tryParse('${json['prepTimeMinutes']}') ?? 25,
      tipsEnabled: json['tipsEnabled'] == true,
      scheduleOrdersEnabled: json['scheduleOrdersEnabled'] == true,
      timezone: json['timezone']?.toString().trim().isNotEmpty == true
          ? json['timezone'].toString().trim()
          : 'Asia/Karachi',
      weeklyHours: hours,
      isOpenNow: json['isOpenNow'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'ordersPaused': ordersPaused,
        'acceptPickup': acceptPickup,
        'acceptDelivery': acceptDelivery,
        'minOrderAmount': minOrderAmount,
        'deliveryFee': deliveryFee,
        'freeDeliveryAbove': freeDeliveryAbove,
        'deliveryAreas': deliveryAreas,
        'prepTimeMinutes': prepTimeMinutes,
        'tipsEnabled': tipsEnabled,
        'scheduleOrdersEnabled': scheduleOrdersEnabled,
        'timezone': timezone,
        'weeklyHours': {
          for (final e in resolvedWeeklyHours.entries) e.key: e.value.toJson(),
        },
      };

  WebsiteOrdering copyWith({
    bool? ordersPaused,
    bool? acceptPickup,
    bool? acceptDelivery,
    double? minOrderAmount,
    double? deliveryFee,
    double? freeDeliveryAbove,
    List<String>? deliveryAreas,
    int? prepTimeMinutes,
    bool? tipsEnabled,
    bool? scheduleOrdersEnabled,
    String? timezone,
    Map<String, WebsiteDayHours>? weeklyHours,
    bool? isOpenNow,
  }) {
    return WebsiteOrdering(
      ordersPaused: ordersPaused ?? this.ordersPaused,
      acceptPickup: acceptPickup ?? this.acceptPickup,
      acceptDelivery: acceptDelivery ?? this.acceptDelivery,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      deliveryAreas: deliveryAreas ?? this.deliveryAreas,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      scheduleOrdersEnabled:
          scheduleOrdersEnabled ?? this.scheduleOrdersEnabled,
      timezone: timezone ?? this.timezone,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      isOpenNow: isOpenNow ?? this.isOpenNow,
    );
  }
}

class BusinessWebsite {
  final String id;
  final String? userId;
  final String slug;
  final String name;
  final String description;
  final String logo;
  final String coverImage;
  final String status;
  final String websiteType;
  final String catalogLinkId;
  final BusinessWebsiteDesign design;
  final WebsiteOrdering ordering;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? templateId;
  final String? templateName;
  final String publicPath;
  final String publicUrl;

  const BusinessWebsite({
    required this.id,
    this.userId,
    required this.slug,
    required this.name,
    this.description = '',
    this.logo = '',
    this.coverImage = '',
    this.status = 'draft',
    this.websiteType = 'menu',
    this.catalogLinkId = '',
    this.design = const BusinessWebsiteDesign(),
    this.ordering = const WebsiteOrdering(),
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.templateId,
    this.templateName,
    this.publicPath = '',
    this.publicUrl = '',
  });

  /// Maps website type → existing Links catalogType.
  String get catalogType {
    switch (websiteType) {
      case 'service':
        return 'services';
      case 'products':
        return 'products';
      case 'portfolio':
        return 'portfolio';
      case 'menu':
      default:
        return 'menu';
    }
  }

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isUnpublished => status == 'unpublished';

  /// Friendly display like barqody.com/username/menu (actual host may still be backend).
  String get displayHostPath {
    final raw = publicPath.trim();
    if (raw.isNotEmpty) {
      final path = raw.startsWith('/') ? raw.substring(1) : raw;
      if (path.isNotEmpty) return 'barqody.com/$path';
    }
    if (slug.isEmpty) return 'barqody.com';
    return 'barqody.com/$slug';
  }

  String get resolvedPublicUrl {
    // Always prefer path + current Api.baseUrl so Android/LAN never sticks
    // on localhost from a Chrome session.
    if (publicPath.isNotEmpty) {
      return '${Api.baseUrl}$publicPath';
    }
    if (slug.isNotEmpty) {
      return Api.businessWebsite.publicSite(slug);
    }
    return rewriteLocalhostToApiBase(publicUrl);
  }

  BusinessWebsite copyWith({
    String? id,
    String? userId,
    String? slug,
    String? name,
    String? description,
    String? logo,
    String? coverImage,
    String? status,
    String? websiteType,
    String? catalogLinkId,
    BusinessWebsiteDesign? design,
    WebsiteOrdering? ordering,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    String? templateId,
    String? templateName,
    String? publicPath,
    String? publicUrl,
  }) {
    return BusinessWebsite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      coverImage: coverImage ?? this.coverImage,
      status: status ?? this.status,
      websiteType: websiteType ?? this.websiteType,
      catalogLinkId: catalogLinkId ?? this.catalogLinkId,
      design: design ?? this.design,
      ordering: ordering ?? this.ordering,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      publicPath: publicPath ?? this.publicPath,
      publicUrl: publicUrl ?? this.publicUrl,
    );
  }

  factory BusinessWebsite.fromJson(Map<String, dynamic> json) {
    final designRaw = json['design'];
    final orderingRaw = json['ordering'];
    return BusinessWebsite(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      websiteType: json['websiteType']?.toString() ?? 'menu',
      catalogLinkId: json['catalogLinkId']?.toString() ?? '',
      design: BusinessWebsiteDesign.fromJson(
        designRaw is Map ? Map<String, dynamic>.from(designRaw) : null,
      ),
      ordering: WebsiteOrdering.fromJson(
        orderingRaw is Map ? Map<String, dynamic>.from(orderingRaw) : null,
      ),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      subcategoryId: json['subcategoryId']?.toString(),
      subcategoryName: json['subcategoryName']?.toString(),
      templateId: json['templateId']?.toString(),
      templateName: json['templateName']?.toString(),
      publicPath: json['publicPath']?.toString() ?? '',
      publicUrl: json['publicUrl']?.toString() ?? '',
    );
  }
}

class BusinessContentCategory {
  final String id;
  final String websiteId;
  final String name;
  final int sortOrder;
  final bool isActive;

  const BusinessContentCategory({
    required this.id,
    required this.websiteId,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BusinessContentCategory.fromJson(Map<String, dynamic> json) {
    return BusinessContentCategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      websiteId: json['websiteId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class BusinessContentItem {
  final String id;
  final String websiteId;
  final String type;
  final String? contentCategoryId;
  final String name;
  final String description;
  final String price;
  final String image;
  final List<String> images;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic> meta;

  const BusinessContentItem({
    required this.id,
    required this.websiteId,
    required this.type,
    this.contentCategoryId,
    required this.name,
    this.description = '',
    this.price = '',
    this.image = '',
    this.images = const [],
    this.sortOrder = 0,
    this.isActive = true,
    this.meta = const {},
  });

  factory BusinessContentItem.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'] as List? ?? const [];
    return BusinessContentItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      websiteId: json['websiteId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'product',
      contentCategoryId: json['contentCategoryId']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      images: imagesRaw.map((e) => e.toString()).toList(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : const {},
    );
  }
}

class BusinessWebsitePreview {
  final String html;
  final String publicUrl;
  final String status;

  const BusinessWebsitePreview({
    required this.html,
    required this.publicUrl,
    required this.status,
  });

  factory BusinessWebsitePreview.fromJson(Map<String, dynamic> json) {
    return BusinessWebsitePreview(
      html: json['html']?.toString() ?? '',
      publicUrl: json['publicUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
    );
  }
}

/// Pin website URLs to the current [Api.baseUrl] host.
/// Chrome often stores `localhost`; Android cannot reach the PC that way.
String rewriteLocalhostToApiBase(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return '';
  final uri = Uri.tryParse(value);
  final base = Uri.tryParse(Api.baseUrl);
  if (uri == null || base == null || !uri.hasScheme || uri.host.isEmpty) {
    return value;
  }
  if (uri.host == base.host &&
      uri.scheme == base.scheme &&
      (uri.hasPort ? uri.port : null) == (base.hasPort ? base.port : null)) {
    return value;
  }
  return uri
      .replace(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
      )
      .toString();
}

/// Resolve a stored profile link value / url to an absolute public site URL.
String resolveBusinessWebsitePublicUrl(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return rewriteLocalhostToApiBase(value);
  }
  if (value.startsWith('business-website:')) {
    final slug = value.substring('business-website:'.length).trim();
    if (slug.isEmpty) return '';
    return Api.businessWebsite.publicSite(slug);
  }
  // Vanity or /w/ paths — always pin to current Api.baseUrl.
  if (value.startsWith('/')) {
    return '${Api.baseUrl}$value';
  }
  if (value.startsWith('w/')) {
    return '${Api.baseUrl}/$value';
  }
  // Bare slug
  if (!value.contains('/') && !value.contains(':')) {
    return Api.businessWebsite.publicSite(value);
  }
  return rewriteLocalhostToApiBase(value);
}

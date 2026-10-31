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

  const BusinessWebsiteDesign({
    this.themeColor = '#ff6fa5',
    this.fontStyle = 'modern',
    this.buttonStyle = 'pill',
    this.cardStyle = 'bordered',
    this.hasCustomThemeColor = false,
    this.homepageHeadline = '',
    this.showLogo = true,
    this.showBio = true,
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
      };

  /// Partial payload for PUT design merge (does not wipe server fields).
  Map<String, dynamic> toDesignPatchJson() => {
        'themeColor': themeColor,
        'hasCustomThemeColor': hasCustomThemeColor,
        'homepageHeadline': homepageHeadline,
        'showLogo': showLogo,
        'showBio': showBio,
      };

  factory BusinessWebsiteDesign.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BusinessWebsiteDesign();
    return BusinessWebsiteDesign(
      themeColor: json['themeColor']?.toString() ?? '#ff6fa5',
      fontStyle: json['fontStyle']?.toString() ?? 'modern',
      buttonStyle: json['buttonStyle']?.toString() ?? 'pill',
      cardStyle: json['cardStyle']?.toString() ?? 'bordered',
      hasCustomThemeColor: json['hasCustomThemeColor'] == true,
      homepageHeadline: json['homepageHeadline']?.toString() ?? '',
      showLogo: json['showLogo'] != false,
      showBio: json['showBio'] != false,
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

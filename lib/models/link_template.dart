class LinkCategory {
  final String id;
  final String name;
  final List<LinkTemplate> templates;

  LinkCategory({
    required this.id,
    required this.name,
    required this.templates,
  });

  factory LinkCategory.fromJson(Map<String, dynamic> json) {
    return LinkCategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      templates: (json['templates'] as List<dynamic>? ?? [])
          .map((item) => LinkTemplate.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  LinkCategory copyWith({
    String? id,
    String? name,
    List<LinkTemplate>? templates,
  }) {
    return LinkCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      templates: templates ?? this.templates,
    );
  }
}

class LinkTemplate {
  final String id;
  final String categoryId;
  final String label;
  final String fieldType;
  final String fieldLabel;
  final String prefix;
  final String logo;
  final bool isPro;
  final bool isFeatured;
  final bool isSystem;
  final String actionType;
  final String? catalogType;
  final String country;

  LinkTemplate({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.fieldType,
    required this.fieldLabel,
    required this.prefix,
    required this.logo,
    required this.isPro,
    required this.isFeatured,
    required this.isSystem,
    required this.actionType,
    this.catalogType,
    this.country = '',
  });

  factory LinkTemplate.fromJson(Map<String, dynamic> json) {
    return LinkTemplate(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fieldType: json['fieldType']?.toString() ?? 'url',
      fieldLabel: json['fieldLabel']?.toString() ?? 'Link',
      prefix: json['prefix']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      isPro: json['isPro'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isSystem: json['isSystem'] as bool? ?? false,
      actionType: json['actionType']?.toString() ?? 'link',
      catalogType: json['catalogType']?.toString(),
      country: json['country']?.toString() ?? '',
    );
  }
}

bool isBankVisibleToUser(LinkTemplate template, String? userCountry) {
  if (template.fieldType != 'bank' || template.isSystem) return true;
  final country = (userCountry ?? '').trim().toLowerCase();
  if (country.isEmpty) return true;
  final bankCountry = template.country.trim().toLowerCase();
  if (bankCountry.isEmpty) return false;
  return bankCountry == country;
}

List<LinkCategory> filterCatalogByUserCountry(
  List<LinkCategory> catalog,
  String? userCountry,
) {
  return catalog
      .map(
        (category) => category.copyWith(
          templates: category.templates
              .where((template) => isBankVisibleToUser(template, userCountry))
              .toList(),
        ),
      )
      .where((category) => category.templates.isNotEmpty)
      .toList();
}

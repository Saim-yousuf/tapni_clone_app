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

bool isDocumentsLinkTemplate(LinkTemplate template) {
  return _isDocumentsTemplate(template);
}

bool _isDocumentsTemplate(LinkTemplate template) {
  return template.actionType == 'document' ||
      template.fieldType == 'document' ||
      template.catalogType == 'documents' ||
      template.label.trim().toLowerCase() == 'documents';
}

LinkTemplate documentsLinkTemplate({String categoryId = ''}) {
  return LinkTemplate(
    id: '',
    categoryId: categoryId,
    label: 'Documents',
    fieldType: 'document',
    fieldLabel: 'Documents',
    prefix: '',
    logo: '',
    isPro: false,
    isFeatured: false,
    isSystem: true,
    actionType: 'document',
    catalogType: 'documents',
  );
}

/// Always show Documents next to Catalog, even if the API has not seeded it yet.
List<LinkCategory> ensureDocumentsCatalogTemplate(List<LinkCategory> catalog) {
  if (catalog.any(
    (category) => category.templates.any(_isDocumentsTemplate),
  )) {
    return catalog;
  }

  final documents = documentsLinkTemplate();
  final businessIndex = catalog.indexWhere(
    (category) => category.name.trim().toLowerCase() == 'business',
  );

  if (businessIndex == -1) {
    return [
      ...catalog,
      LinkCategory(id: 'documents', name: 'Documents', templates: [documents]),
    ];
  }

  final business = catalog[businessIndex];
  final templates = List<LinkTemplate>.from(business.templates);
  final catalogIndex = templates.indexWhere(
    (template) =>
        template.catalogType == 'catalog' ||
        template.label.trim().toLowerCase() == 'catalog',
  );
  final insertAt = catalogIndex >= 0 ? catalogIndex + 1 : templates.length;
  templates.insert(
    insertAt,
    documentsLinkTemplate(categoryId: business.id),
  );

  final updated = List<LinkCategory>.from(catalog);
  updated[businessIndex] = business.copyWith(templates: templates);
  return updated;
}

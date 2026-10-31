import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class BusinessWebsiteRepo {
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  Future<ApiResponse> getCatalog({String? websiteType}) {
    return ApiHandler.request(
      api: Api.businessWebsite.catalog,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (websiteType != null && websiteType.isNotEmpty)
          'websiteType': websiteType,
      },
    );
  }

  BusinessWebsiteCatalog? parseCatalog(dynamic data) {
    final root = _asMap(data);
    if (root.isEmpty) return null;
    return BusinessWebsiteCatalog.fromJson(root);
  }

  Future<ApiResponse> getMine({
    String? websiteType,
    String? websiteId,
    bool all = false,
  }) {
    return ApiHandler.request(
      api: Api.businessWebsite.mine,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (websiteType != null && websiteType.isNotEmpty)
          'websiteType': websiteType,
        if (websiteId != null && websiteId.isNotEmpty) 'websiteId': websiteId,
        if (all) 'all': '1',
      },
    );
  }

  BusinessWebsite? parseWebsite(dynamic data) {
    final root = _asMap(data);
    final website = root['website'];
    if (website == null) return null;
    if (website is! Map) return null;
    return BusinessWebsite.fromJson(Map<String, dynamic>.from(website));
  }

  Future<ApiResponse> createWebsite({
    required String categoryId,
    required String subcategoryId,
    required String templateId,
    required String websiteType,
    String? name,
    String? description,
    String? catalogLinkId,
  }) {
    return ApiHandler.request(
      api: Api.businessWebsite.mine,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'templateId': templateId,
        'websiteType': websiteType,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
        if (catalogLinkId != null && catalogLinkId.isNotEmpty)
          'catalogLinkId': catalogLinkId,
      },
    );
  }

  Future<ApiResponse> updateWebsite(
    Map<String, dynamic> body, {
    String? websiteType,
    String? websiteId,
  }) {
    return ApiHandler.request(
      api: Api.businessWebsite.mine,
      method: ApiMethod.put,
      authorization: true,
      queryParams: {
        if (websiteType != null && websiteType.isNotEmpty)
          'websiteType': websiteType,
        if (websiteId != null && websiteId.isNotEmpty) 'websiteId': websiteId,
      },
      jsonBody: body,
    );
  }

  Future<ApiResponse> deleteWebsite({
    String? websiteType,
    String? websiteId,
  }) {
    return ApiHandler.request(
      api: Api.businessWebsite.mine,
      method: ApiMethod.delete,
      authorization: true,
      queryParams: {
        if (websiteType != null && websiteType.isNotEmpty)
          'websiteType': websiteType,
        if (websiteId != null && websiteId.isNotEmpty) 'websiteId': websiteId,
      },
    );
  }

  Future<ApiResponse> previewMine({
    String pageType = 'home',
    bool asJson = true,
    String? websiteType,
    String? websiteId,
    /// Draft design for authenticated preview only — never published.
    Map<String, dynamic>? designDraft,
  }) {
    final hasDraft = designDraft != null && designDraft.isNotEmpty;
    return ApiHandler.request(
      api: Api.businessWebsite.preview,
      method: hasDraft ? ApiMethod.post : ApiMethod.get,
      authorization: true,
      queryParams: {
        'pageType': pageType,
        if (asJson) 'format': 'json',
        if (websiteType != null && websiteType.isNotEmpty)
          'websiteType': websiteType,
        if (websiteId != null && websiteId.isNotEmpty) 'websiteId': websiteId,
      },
      jsonBody: hasDraft
          ? {
              'pageType': pageType,
              if (asJson) 'format': 'json',
              'design': designDraft,
            }
          : null,
    );
  }

  Future<ApiResponse> previewTemplateSample({
    required String templateId,
    String pageType = 'home',
    String? pageKey,
    String? pageSlug,
    String? itemId,
    bool asJson = true,
  }) {
    return ApiHandler.request(
      api: Api.businessWebsite.templatePreview(templateId),
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (pageKey != null && pageKey.isNotEmpty)
          'pageKey': pageKey
        else
          'pageType': pageType,
        if (pageSlug != null && pageSlug.isNotEmpty) 'pageSlug': pageSlug,
        if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
        if (asJson) 'format': 'json',
      },
    );
  }

  BusinessWebsitePreview? parsePreview(dynamic data) {
    final root = _asMap(data);
    if (root.isEmpty || root['html'] == null) return null;
    return BusinessWebsitePreview.fromJson(root);
  }

  Future<ApiResponse> listContentCategories() {
    return ApiHandler.request(
      api: Api.businessWebsite.contentCategories,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  List<BusinessContentCategory> parseContentCategories(dynamic data) {
    final root = _asMap(data);
    final list = root['categories'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map(
          (e) =>
              BusinessContentCategory.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<ApiResponse> createContentCategory({
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) {
    return ApiHandler.request(
      api: Api.businessWebsite.contentCategories,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'name': name.trim(),
        'sortOrder': sortOrder,
        'isActive': isActive,
      },
    );
  }

  Future<ApiResponse> updateContentCategory(
    String id,
    Map<String, dynamic> body,
  ) {
    return ApiHandler.request(
      api: Api.businessWebsite.contentCategory(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> deleteContentCategory(String id) {
    return ApiHandler.request(
      api: Api.businessWebsite.contentCategory(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> listContent({String? type}) {
    return ApiHandler.request(
      api: Api.businessWebsite.content,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
  }

  List<BusinessContentItem> parseContentItems(dynamic data) {
    final root = _asMap(data);
    final list = root['items'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map(
          (e) => BusinessContentItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<ApiResponse> createContent(Map<String, dynamic> body) {
    return ApiHandler.request(
      api: Api.businessWebsite.content,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> updateContent(String id, Map<String, dynamic> body) {
    return ApiHandler.request(
      api: Api.businessWebsite.contentItem(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> deleteContent(String id) {
    return ApiHandler.request(
      api: Api.businessWebsite.contentItem(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }
}

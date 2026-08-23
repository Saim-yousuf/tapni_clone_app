class GalleryItem {
  final String id;
  final String url;
  final String caption;
  final DateTime? createdAt;

  const GalleryItem({
    required this.id,
    required this.url,
    this.caption = '',
    this.createdAt,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final rawDate = json['createdAt'];
    if (rawDate is String && rawDate.isNotEmpty) {
      createdAt = DateTime.tryParse(rawDate);
    }

    return GalleryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  static List<GalleryItem> listFrom(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => GalleryItem.fromJson(Map<String, dynamic>.from(e)))
        .where((item) => item.id.isNotEmpty && item.url.isNotEmpty)
        .toList();
  }
}

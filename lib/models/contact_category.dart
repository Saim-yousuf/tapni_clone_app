class ContactCategory {
  final String id;
  final String name;
  final String color;

  ContactCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  factory ContactCategory.fromJson(Map<String, dynamic> json) {
    return ContactCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
    );
  }
}

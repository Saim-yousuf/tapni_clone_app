class BookableResource {
  final String id;
  final String businessId;
  final String type;
  final String name;
  final String tableToken;
  final String? refUserId;
  final String refUserName;
  final String refUserPhoto;
  final bool isActive;

  const BookableResource({
    required this.id,
    required this.businessId,
    required this.type,
    required this.name,
    this.tableToken = '',
    this.refUserId,
    this.refUserName = '',
    this.refUserPhoto = '',
    this.isActive = true,
  });

  factory BookableResource.fromJson(Map<String, dynamic> json) {
    return BookableResource(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'staff',
      name: json['name']?.toString() ?? '',
      tableToken: json['tableToken']?.toString() ?? '',
      refUserId: json['refUserId']?.toString(),
      refUserName: json['refUserName']?.toString() ?? '',
      refUserPhoto: json['refUserPhoto']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

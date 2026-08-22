class BusinessReview {
  final String id;
  final String targetType;
  final String targetId;
  final String targetLabel;
  final String businessId;
  final int rating;
  final String text;
  final bool verified;
  final DateTime? createdAt;
  final String reviewerName;
  final String reviewerUsername;
  final String? reviewerPhoto;

  const BusinessReview({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.targetLabel = '',
    required this.businessId,
    required this.rating,
    this.text = '',
    this.verified = false,
    this.createdAt,
    this.reviewerName = '',
    this.reviewerUsername = '',
    this.reviewerPhoto,
  });

  factory BusinessReview.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] is Map
        ? Map<String, dynamic>.from(json['reviewer'] as Map)
        : <String, dynamic>{};
    return BusinessReview(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? 'business',
      targetId: json['targetId']?.toString() ?? '',
      targetLabel: json['targetLabel']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
      verified: json['verified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reviewerName: reviewer['name']?.toString() ?? '',
      reviewerUsername: reviewer['username']?.toString() ?? '',
      reviewerPhoto: reviewer['profilePhoto']?.toString(),
    );
  }
}

class ItemReviewSummary {
  final String targetId;
  final String targetLabel;
  final double avgRating;
  final int reviewCount;

  const ItemReviewSummary({
    required this.targetId,
    required this.targetLabel,
    required this.avgRating,
    required this.reviewCount,
  });

  factory ItemReviewSummary.fromJson(Map<String, dynamic> json) {
    return ItemReviewSummary(
      targetId: json['targetId']?.toString() ?? '',
      targetLabel: json['targetLabel']?.toString() ?? '',
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

import 'package:tapni_app/models/profile.dart';

/// Business listing readiness: name + industry + map location.
class BusinessCompleteness {
  final bool hasName;
  final bool hasIndustry;
  final bool hasLocation;

  const BusinessCompleteness({
    required this.hasName,
    required this.hasIndustry,
    required this.hasLocation,
  });

  factory BusinessCompleteness.fromProfile(UserProfile profile) {
    return BusinessCompleteness(
      hasName: (profile.businessName ?? '').trim().isNotEmpty,
      hasIndustry: (profile.businessCategory ?? '').trim().isNotEmpty,
      hasLocation:
          profile.latitude != null &&
          profile.longitude != null &&
          !profile.latitude!.isNaN &&
          !profile.longitude!.isNaN,
    );
  }

  int get completedCount =>
      (hasName ? 1 : 0) + (hasIndustry ? 1 : 0) + (hasLocation ? 1 : 0);

  int get totalCount => 3;

  bool get isComplete => hasName && hasIndustry && hasLocation;

  String get progressLabel => '$completedCount/$totalCount complete';

  List<String> get missingLabels {
    final missing = <String>[];
    if (!hasName) missing.add('Business name');
    if (!hasIndustry) missing.add('Industry category');
    if (!hasLocation) missing.add('Business location');
    return missing;
  }
}

enum UsernameAvailabilityStatus {
  idle,
  checking,
  available,
  taken,
  unavailable,
  invalid,
}

class UsernameCheckResult {
  final UsernameAvailabilityStatus status;
  final String? reason;
  final String username;

  const UsernameCheckResult({
    required this.status,
    required this.username,
    this.reason,
  });

  bool get canSave => status == UsernameAvailabilityStatus.available;

  bool get canClaim =>
      status == UsernameAvailabilityStatus.unavailable ||
      status == UsernameAvailabilityStatus.taken;

  factory UsernameCheckResult.fromApi(Map<String, dynamic> json, String username) {
    final available = json['available'] == true;
    if (available) {
      return UsernameCheckResult(
        status: UsernameAvailabilityStatus.available,
        username: username,
      );
    }

    final reason = json['reason']?.toString() ?? '';
    UsernameAvailabilityStatus status;
    switch (reason) {
      case 'USERNAME_TAKEN':
        status = UsernameAvailabilityStatus.taken;
        break;
      case 'USERNAME_UNAVAILABLE':
        status = UsernameAvailabilityStatus.unavailable;
        break;
      case 'USERNAME_FORMAT':
      case 'USERNAME_REQUIRED':
        status = UsernameAvailabilityStatus.invalid;
        break;
      default:
        status = UsernameAvailabilityStatus.unavailable;
    }

    return UsernameCheckResult(
      status: status,
      username: username,
      reason: reason,
    );
  }
}

class UsernameClaimItem {
  final String id;
  final String username;
  final String reason;
  final String businessEmail;
  final String status;
  final DateTime? createdAt;

  const UsernameClaimItem({
    required this.id,
    required this.username,
    required this.reason,
    required this.businessEmail,
    required this.status,
    this.createdAt,
  });

  factory UsernameClaimItem.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['createdAt']?.toString();
    if (rawCreated != null && rawCreated.isNotEmpty) {
      created = DateTime.tryParse(rawCreated);
    }

    return UsernameClaimItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      businessEmail: json['businessEmail']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: created,
    );
  }
}

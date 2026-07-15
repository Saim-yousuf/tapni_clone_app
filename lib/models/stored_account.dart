class StoredAccount {
  final String userId;
  final String name;
  final String email;
  final String? username;
  final String? profilePhoto;
  final String token;
  final String? deviceSessionId;

  const StoredAccount({
    required this.userId,
    required this.name,
    required this.email,
    this.username,
    this.profilePhoto,
    required this.token,
    this.deviceSessionId,
  });

  StoredAccount copyWith({
    String? userId,
    String? name,
    String? email,
    String? username,
    String? profilePhoto,
    String? token,
    String? deviceSessionId,
  }) {
    return StoredAccount(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      token: token ?? this.token,
      deviceSessionId: deviceSessionId ?? this.deviceSessionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'username': username,
        'profilePhoto': profilePhoto,
        'token': token,
        'deviceSessionId': deviceSessionId,
      };

  factory StoredAccount.fromJson(Map<String, dynamic> json) {
    return StoredAccount(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: json['username']?.toString(),
      profilePhoto: json['profilePhoto']?.toString(),
      token: (json['token'] ?? '').toString(),
      deviceSessionId: json['deviceSessionId']?.toString(),
    );
  }

  String get displayName => name.isNotEmpty ? name : email;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

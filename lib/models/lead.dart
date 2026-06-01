class Lead {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final DateTime timestamp;

  Lead({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.timestamp,
  });

  Lead copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    DateTime? timestamp,
  }) {
    return Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

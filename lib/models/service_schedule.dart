class ServiceSchedule {
  final int startHour;
  final int endHour;
  final int slotMinutes;
  final List<int> workingDays;

  const ServiceSchedule({
    this.startHour = 9,
    this.endHour = 18,
    this.slotMinutes = 30,
    this.workingDays = const [1, 2, 3, 4, 5, 6],
  });

  factory ServiceSchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ServiceSchedule();
    return ServiceSchedule(
      startHour: (json['startHour'] is num) ? (json['startHour'] as num).toInt() : 9,
      endHour: (json['endHour'] is num) ? (json['endHour'] as num).toInt() : 18,
      slotMinutes:
          (json['slotMinutes'] is num) ? (json['slotMinutes'] as num).toInt() : 30,
      workingDays: (json['workingDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6],
    );
  }

  Map<String, dynamic> toJson() => {
        'startHour': startHour,
        'endHour': endHour,
        'slotMinutes': slotMinutes,
        'workingDays': workingDays,
      };

  ServiceSchedule copyWith({
    int? startHour,
    int? endHour,
    int? slotMinutes,
    List<int>? workingDays,
  }) {
    return ServiceSchedule(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      slotMinutes: slotMinutes ?? this.slotMinutes,
      workingDays: workingDays ?? this.workingDays,
    );
  }
}

class TimeSlot {
  final String time;
  final bool available;

  const TimeSlot({required this.time, required this.available});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time']?.toString() ?? '',
      available: json['available'] as bool? ?? false,
    );
  }
}

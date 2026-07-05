class AttendanceLocation {
  final double latitude;
  final double longitude;
  final String address;
  final int radiusMeters;

  AttendanceLocation({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.radiusMeters = 100,
  });

  factory AttendanceLocation.fromJson(Map<String, dynamic> json) {
    return AttendanceLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      radiusMeters: json['radiusMeters'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'radiusMeters': radiusMeters,
  };
}

class AttendanceUserSummary {
  final String id;
  final String name;
  final String username;
  final String profilePhoto;
  final String businessName;

  AttendanceUserSummary({
    required this.id,
    this.name = '',
    this.username = '',
    this.profilePhoto = '',
    this.businessName = '',
  });

  factory AttendanceUserSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AttendanceUserSummary(id: '');
    }
    return AttendanceUserSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
    );
  }

  String get displayName =>
      businessName.isNotEmpty ? businessName : (name.isNotEmpty ? name : username);
}

class AttendanceEmployee {
  final String id;
  final AttendanceUserSummary business;
  final AttendanceUserSummary employee;
  final String shiftStart;
  final String shiftEnd;
  final AttendanceLocation location;
  final List<int> weekendDays;
  final String facePhoto;
  final bool isActive;

  AttendanceEmployee({
    required this.id,
    required this.business,
    required this.employee,
    this.shiftStart = '09:00',
    this.shiftEnd = '18:00',
    required this.location,
    this.weekendDays = const [0, 6],
    this.facePhoto = '',
    this.isActive = true,
  });

  factory AttendanceEmployee.fromJson(Map<String, dynamic> json) {
    final businessJson = json['business'];
    final employeeJson = json['employee'];

    return AttendanceEmployee(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      business: businessJson is Map<String, dynamic>
          ? AttendanceUserSummary.fromJson(businessJson)
          : AttendanceUserSummary(id: json['business']?.toString() ?? ''),
      employee: employeeJson is Map<String, dynamic>
          ? AttendanceUserSummary.fromJson(employeeJson)
          : AttendanceUserSummary(id: json['employee']?.toString() ?? ''),
      shiftStart: json['shiftStart'] as String? ?? '09:00',
      shiftEnd: json['shiftEnd'] as String? ?? '18:00',
      location: AttendanceLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      weekendDays: (json['weekendDays'] as List?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          const [0, 6],
      facePhoto: json['facePhoto'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  String get weekendLabel {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekendDays.map((d) => names[d.clamp(0, 6)]).join(', ');
  }
}

class AttendanceRecord {
  final String id;
  final String employeeRefId;
  final AttendanceUserSummary business;
  final AttendanceUserSummary employee;
  final String date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool checkInLocationVerified;
  final bool checkOutLocationVerified;
  final String status;

  AttendanceRecord({
    required this.id,
    required this.employeeRefId,
    required this.business,
    required this.employee,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocationVerified = false,
    this.checkOutLocationVerified = false,
    this.status = 'present',
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final businessJson = json['business'];
    final employeeJson = json['employee'];
    final employeeRef = json['employeeRef'];

    return AttendanceRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      employeeRefId: employeeRef is Map<String, dynamic>
          ? (employeeRef['_id'] ?? employeeRef['id'] ?? '').toString()
          : (json['employeeRef']?.toString() ?? ''),
      business: businessJson is Map<String, dynamic>
          ? AttendanceUserSummary.fromJson(businessJson)
          : AttendanceUserSummary(id: json['business']?.toString() ?? ''),
      employee: employeeJson is Map<String, dynamic>
          ? AttendanceUserSummary.fromJson(employeeJson)
          : AttendanceUserSummary(id: json['employee']?.toString() ?? ''),
      date: json['date'] as String? ?? '',
      checkInTime: json['checkInTime'] != null
          ? DateTime.tryParse(json['checkInTime'].toString())
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.tryParse(json['checkOutTime'].toString())
          : null,
      checkInLocationVerified:
          json['checkInLocationVerified'] as bool? ?? false,
      checkOutLocationVerified:
          json['checkOutLocationVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'present',
    );
  }
}

class AttendanceTodayStatus {
  final AttendanceEmployee employeeRef;
  final String date;
  final bool isWeekend;
  final AttendanceRecord? record;
  final bool canCheckIn;
  final bool canCheckOut;

  AttendanceTodayStatus({
    required this.employeeRef,
    required this.date,
    this.isWeekend = false,
    this.record,
    this.canCheckIn = false,
    this.canCheckOut = false,
  });

  factory AttendanceTodayStatus.fromJson(Map<String, dynamic> json) {
    final recordJson = json['record'];
    return AttendanceTodayStatus(
      employeeRef: AttendanceEmployee.fromJson(
        json['employeeRef'] as Map<String, dynamic>? ?? {},
      ),
      date: json['date'] as String? ?? '',
      isWeekend: json['isWeekend'] as bool? ?? false,
      record: recordJson is Map<String, dynamic>
          ? AttendanceRecord.fromJson(recordJson)
          : null,
      canCheckIn: json['canCheckIn'] as bool? ?? false,
      canCheckOut: json['canCheckOut'] as bool? ?? false,
    );
  }
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int partial;
  final int weekend;
  final int totalWorkingDays;
  final List<AttendanceDailyStatus> daily;

  AttendanceSummary({
    this.present = 0,
    this.absent = 0,
    this.partial = 0,
    this.weekend = 0,
    this.totalWorkingDays = 0,
    this.daily = const [],
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    final dailyList = json['daily'] as List? ?? [];
    return AttendanceSummary(
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      partial: json['partial'] as int? ?? 0,
      weekend: json['weekend'] as int? ?? 0,
      totalWorkingDays: json['totalWorkingDays'] as int? ?? 0,
      daily: dailyList
          .map((e) => AttendanceDailyStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AttendanceDailyStatus {
  final String date;
  final String status;
  final AttendanceRecord? record;

  AttendanceDailyStatus({
    required this.date,
    required this.status,
    this.record,
  });

  factory AttendanceDailyStatus.fromJson(Map<String, dynamic> json) {
    final recordJson = json['record'];
    return AttendanceDailyStatus(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      record: recordJson is Map<String, dynamic>
          ? AttendanceRecord.fromJson(recordJson)
          : null,
    );
  }
}

List<T> parseAttendanceList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is List) {
    return data
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is List) {
      return inner
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
  return [];
}

Map<String, dynamic> unwrapAttendancePayload(dynamic data) {
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }
  return {};
}

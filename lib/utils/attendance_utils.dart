import 'package:tapni_app/models/attendance.dart';

/// Hours worked when both check-in and check-out exist.
Duration? attendanceWorkedDuration(AttendanceRecord? record) {
  if (record?.checkInTime == null || record?.checkOutTime == null) {
    return null;
  }
  return record!.checkOutTime!.difference(record.checkInTime!);
}

/// Sum of daily hours for days with complete check-in/out.
Duration totalWorkedDuration(AttendanceSummary summary) {
  var total = Duration.zero;
  for (final day in summary.daily) {
    final worked = attendanceWorkedDuration(day.record);
    if (worked != null) total += worked;
  }
  return total;
}

/// Average hours per fully-present day in the month.
Duration? averageWorkedDuration(AttendanceSummary summary) {
  if (summary.present <= 0) return null;
  return Duration(
    microseconds: totalWorkedDuration(summary).inMicroseconds ~/ summary.present,
  );
}

/// `{hours}h {minutes}m` — pass to l10n or use directly for display.
({int hours, int minutes}) splitDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return (hours: hours, minutes: minutes);
}

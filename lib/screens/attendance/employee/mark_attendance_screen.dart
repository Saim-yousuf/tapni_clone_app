import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/attendance_report_screen.dart';
import 'package:tapni_app/screens/attendance/employee/attendance_success_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/face_capture_sheet.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<AttendanceEmployee> _employers = [];
  AttendanceEmployee? _selectedEmployer;
  AttendanceTodayStatus? _todayStatus;
  AttendanceSummary? _summary;
  bool _isLoading = true;
  bool _isMarking = false;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadEmployers();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployers() async {
    setState(() => _isLoading = true);
    final res = await AttendanceRepo().getMyEmployers();
    if (!mounted) return;

    final employers = res.success
        ? parseAttendanceList(res.data, AttendanceEmployee.fromJson)
        : <AttendanceEmployee>[];

    setState(() {
      _employers = employers;
      _isLoading = false;
      if (_selectedEmployer == null && employers.isNotEmpty) {
        _selectedEmployer = employers.first;
      } else if (_selectedEmployer != null) {
        final stillThere = employers.any((e) => e.id == _selectedEmployer!.id);
        if (!stillThere) {
          _selectedEmployer = employers.isNotEmpty ? employers.first : null;
        }
      }
    });

    if (_selectedEmployer != null) {
      await _loadTodayStatus();
    }
  }

  Future<void> _loadTodayStatus() async {
    final employer = _selectedEmployer;
    if (employer == null) return;

    final todayRes = await AttendanceRepo().getTodayStatus(employer.id);
    final now = DateTime.now();
    final summaryRes = await AttendanceRepo().getSummary(
      employeeRefId: employer.id,
      month: now.month,
      year: now.year,
    );

    if (!mounted) return;

    setState(() {
      if (todayRes.success) {
        _todayStatus = AttendanceTodayStatus.fromJson(
          unwrapAttendancePayload(todayRes.data),
        );
      }
      if (summaryRes.success) {
        _summary = AttendanceSummary.fromJson(
          unwrapAttendancePayload(summaryRes.data),
        );
      }
    });
  }

  String _greetingFirstName() {
    final profileName =
        Provider.of<ProfileProvider>(context, listen: false).profile.name.trim();
    if (profileName.isNotEmpty) {
      return _firstName(profileName);
    }
    final employeeName = _selectedEmployer?.employee.name.trim() ?? '';
    if (employeeName.isNotEmpty) {
      return _firstName(employeeName);
    }
    return 'there';
  }

  String _firstName(String fullName) {
    final parts = fullName.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : fullName;
  }

  String _timeOfDayGreeting() {
    final hour = _now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static DateTime? _parseShiftOnDay(String hhmm, DateTime day) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  static int _lateMinutes(DateTime checkIn, String shiftStart) {
    final shift = _parseShiftOnDay(shiftStart, checkIn.toLocal());
    if (shift == null) return 0;
    final diff = checkIn.toLocal().difference(shift);
    if (diff.inMinutes <= 0) return 0;
    return diff.inMinutes;
  }

  static String _formatElapsed(Duration d) {
    if (d.isNegative) return '0m';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _openSchedules() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceReportScreen(
          employee: _selectedEmployer,
        ),
      ),
    );
  }

  void _showCompanyPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SheetDragHandle()),
                const SizedBox(height: 16),
                Text(
                  context.l10n.selectCompany,
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _employers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final employer = _employers[index];
                      final selected = _selectedEmployer?.id == employer.id;
                      return Material(
                        color: selected
                            ? BarqodyChrome.fieldFill
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            Navigator.pop(ctx);
                            setState(() => _selectedEmployer = employer);
                            await _loadTodayStatus();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? Colors.black : BarqodyChrome.divider,
                                width: selected ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: BarqodyChrome.fieldFill,
                                  backgroundImage: employer
                                          .business.profilePhoto.isNotEmpty
                                      ? NetworkImage(
                                          employer.business.profilePhoto,
                                        )
                                      : null,
                                  child: employer.business.profilePhoto.isEmpty
                                      ? Text(
                                          employer.business.displayName.isNotEmpty
                                              ? employer.business.displayName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: WaUi.avatarInitial,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employer.business.displayName,
                                        style: WaUi.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.l10n.shiftRange(
                                          employer.shiftStart,
                                          employer.shiftEnd,
                                        ),
                                        style: WaUi.body.copyWith(
                                          color: BarqodyChrome.secondaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.black,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAttendance(String type) async {
    final employer = _selectedEmployer;
    if (employer == null) return;

    final priorCheckIn = _todayStatus?.record?.checkInTime;

    setState(() => _isMarking = true);

    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;

    if (location == null) {
      setState(() => _isMarking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.l10n.locationPermissionRequiredForAttendance,
            style: WaUi.body,
          ),
        ),
      );
      return;
    }

    final facePhoto = await FaceCaptureSheet.show(
      context,
      title: type == 'check_in'
          ? context.l10n.checkInFace
          : context.l10n.checkOutFace,
    );

    if (!mounted) return;

    final res = await AttendanceRepo().markAttendance({
      'employeeRefId': employer.id,
      'type': type,
      'latitude': location.latitude,
      'longitude': location.longitude,
      if (facePhoto != null && facePhoto.isNotEmpty) 'facePhoto': facePhoto,
    });

    if (!mounted) return;
    setState(() => _isMarking = false);

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            res.message ?? context.l10n.attendanceFailed,
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      return;
    }

    final recordedAt = DateTime.now();
    final companyName = employer.business.displayName;

    if (type == 'check_in') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceSuccessScreen(
            kind: AttendanceSuccessKind.checkIn,
            companyName: companyName,
            timestamp: recordedAt,
            checkInTime: recordedAt,
            shiftStart: employer.shiftStart,
            shiftEnd: employer.shiftEnd,
            lateMinutes: _lateMinutes(recordedAt, employer.shiftStart),
            onCheckOut: () => _markAttendance('check_out'),
          ),
        ),
      );
    } else {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceSuccessScreen(
            kind: AttendanceSuccessKind.checkOut,
            companyName: companyName,
            timestamp: recordedAt,
            checkInTime: priorCheckIn,
            checkOutTime: recordedAt,
            shiftStart: employer.shiftStart,
            shiftEnd: employer.shiftEnd,
          ),
        ),
      );
    }

    if (mounted) await _loadTodayStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: 'Attendance',
              trailing: CircleAssetButton(
                asset: 'assets/images/png/card-icon.png',
                iconSize: 18,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployeeBusinessCardsScreen(),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _employers.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: WaUi.accent,
                          backgroundColor: Colors.white,
                          onRefresh: _loadEmployers,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              BarqodyChrome.sidePad,
                              8,
                              BarqodyChrome.sidePad,
                              24,
                            ),
                            children: [
                              Text(
                                '${_timeOfDayGreeting()}, ${_greetingFirstName()} 👋',
                                style: WaUi.toolsTitleOf(
                                  size: 22,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Start your workday',
                                style: WaUi.body.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _CompanyCard(
                                companyName:
                                    _selectedEmployer?.business.displayName ?? '',
                                onTap: _showCompanyPicker,
                              ),
                              const SizedBox(height: 16),
                              if (_todayStatus != null) _buildStateContent(),
                              if (_summary != null) const SizedBox(height: 8),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    final status = _todayStatus!;
    final employer = _selectedEmployer!;
    final record = status.record;

    if (status.isWeekend) {
      return _WeekendContent(
        now: _now,
        onSchedules: _openSchedules,
      );
    }

    if (status.canCheckOut) {
      final checkIn = record?.checkInTime?.toLocal();
      final elapsed = checkIn != null
          ? _formatElapsed(_now.difference(checkIn))
          : '—';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(
            title: 'Check In',
            primary: checkIn != null
                ? DateFormat('hh:mm a').format(checkIn)
                : '—',
            secondary: DateFormat('EEE, MMM d').format(_now),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            title: 'Working',
            primary: elapsed,
            secondary: 'Time elapsed since check-in',
          ),
          const SizedBox(height: 20),
          PillButton(
            label: context.l10n.checkOut,
            onPressed: () => _markAttendance('check_out'),
            enabled: !_isMarking,
          ),
          if (_isMarking) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ],
          const SizedBox(height: 12),
          PillButton(
            label: 'Schedules',
            filled: false,
            onPressed: _openSchedules,
          ),
        ],
      );
    }

    if (!status.canCheckIn &&
        !status.canCheckOut &&
        record?.checkOutTime != null) {
      return _CompletedDayContent(
        checkIn: record!.checkInTime?.toLocal(),
        checkOut: record.checkOutTime?.toLocal(),
        onSchedules: _openSchedules,
      );
    }

    if (status.canCheckIn) {
      return _ReadyCheckInContent(
        now: _now,
        shiftStart: employer.shiftStart,
        shiftEnd: employer.shiftEnd,
        isMarking: _isMarking,
        onCheckIn: () => _markAttendance('check_in'),
        onSchedules: _openSchedules,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (record?.checkInTime != null)
          _InfoCard(
            title: 'Check In',
            primary: DateFormat('hh:mm a').format(record!.checkInTime!.toLocal()),
            secondary: DateFormat('EEE, MMM d').format(_now),
          ),
        const SizedBox(height: 12),
        PillButton(
          label: 'Schedules',
          filled: false,
          onPressed: _openSchedules,
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BarqodyChrome.sidePad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BarqodyChrome.fieldFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_off_outlined,
                size: 36,
                color: BarqodyChrome.secondaryText.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noEmployerFound,
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: 18,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.askYourBusinessToScanYourQRAndAddYouAsAnEmployee,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                color: BarqodyChrome.secondaryText,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.companyName,
    required this.onTap,
  });

  final String companyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your selected company',
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _ReadyCheckInContent extends StatelessWidget {
  const _ReadyCheckInContent({
    required this.now,
    required this.shiftStart,
    required this.shiftEnd,
    required this.isMarking,
    required this.onCheckIn,
    required this.onSchedules,
  });

  final DateTime now;
  final String shiftStart;
  final String shiftEnd;
  final bool isMarking;
  final VoidCallback onCheckIn;
  final VoidCallback onSchedules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(now),
                      style: WaUi.toolsTitleOf(
                        size: 28,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEE, MMM d').format(now),
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Time Now',
                    style: WaUi.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today Shift',
                style: WaUi.body.copyWith(
                  color: BarqodyChrome.secondaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AttendanceSuccessScreen.formatShiftRange(shiftStart, shiftEnd),
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: context.l10n.checkIn,
          onPressed: onCheckIn,
          enabled: !isMarking,
        ),
        if (isMarking) ...[
          const SizedBox(height: 12),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ],
        const SizedBox(height: 12),
        PillButton(
          label: 'Schedules',
          filled: false,
          onPressed: onSchedules,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: WaUi.toolsTitleOf(
              size: 22,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekendContent extends StatelessWidget {
  const _WeekendContent({
    required this.now,
    required this.onSchedules,
  });

  final DateTime now;
  final VoidCallback onSchedules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "It's a Day Off",
                    style: WaUi.toolsTitleOf(
                      size: 20,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEE, MMM d').format(now),
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You don't have a scheduled shift for today",
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.bodyText,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Image.asset(
                'assets/images/png/cancel-icon.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.block_rounded,
                  size: 22,
                  color: BarqodyChrome.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Check IN',
          onPressed: () {},
          enabled: false,
        ),
        const SizedBox(height: 12),
        PillButton(
          label: 'Schedules',
          filled: false,
          onPressed: onSchedules,
        ),
      ],
    );
  }
}

class _CompletedDayContent extends StatelessWidget {
  const _CompletedDayContent({
    required this.checkIn,
    required this.checkOut,
    required this.onSchedules,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoidCallback onSchedules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (checkIn != null)
          _InfoCard(
            title: 'Check In',
            primary: DateFormat('hh:mm a').format(checkIn!),
            secondary: DateFormat('EEE, MMM d').format(checkIn!),
          ),
        if (checkIn != null && checkOut != null) const SizedBox(height: 10),
        if (checkOut != null)
          _InfoCard(
            title: 'Check Out',
            primary: DateFormat('hh:mm a').format(checkOut!),
            secondary: DateFormat('EEE, MMM d').format(checkOut!),
          ),
        const SizedBox(height: 12),
        Text(
          context.l10n.attendanceCompletedForToday,
          textAlign: TextAlign.center,
          style: WaUi.body.copyWith(
            color: BarqodyChrome.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        PillButton(
          label: 'Schedules',
          filled: false,
          onPressed: onSchedules,
        ),
      ],
    );
  }
}

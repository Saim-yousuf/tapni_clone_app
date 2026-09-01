import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/attendance_report_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
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

  @override
  void initState() {
    super.initState();
    _loadEmployers();
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

  Future<void> _markAttendance(String type) async {
    final employer = _selectedEmployer;
    if (employer == null) return;

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          res.success
              ? (type == 'check_in'
                  ? context.l10n.checkInSuccessful
                  : context.l10n.checkOutSuccessful)
              : (res.message ?? context.l10n.attendanceFailed),
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        backgroundColor:
            res.success ? WaUi.navGreen : const Color(0xFFC62828),
      ),
    );

    if (res.success) _loadTodayStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar(
        context.l10n.workplaceCheckIn,
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: context.l10n.companyEmployeeCard,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmployeeBusinessCardsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _employers.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: WaUi.accent,
                  backgroundColor: Colors.white,
                  onRefresh: _loadEmployers,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        context.l10n.selectCompany,
                        style: WaUi.label.copyWith(
                          color: WaUi.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._employers.map((employer) {
                        final selected = _selectedEmployer?.id == employer.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AttendanceUi.radius),
                            child: InkWell(
                              onTap: () async {
                                setState(() => _selectedEmployer = employer);
                                await _loadTodayStatus();
                              },
                              borderRadius:
                                  BorderRadius.circular(AttendanceUi.radius),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AttendanceUi.radius,
                                  ),
                                  border: Border.all(
                                    color: selected
                                        ? WaUi.buttonDark
                                        : WaUi.divider,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AttendanceUi.tileBg,
                                      backgroundImage: employer.business
                                              .profilePhoto.isNotEmpty
                                          ? NetworkImage(
                                              employer.business.profilePhoto,
                                            )
                                          : null,
                                      child: employer
                                              .business.profilePhoto.isEmpty
                                          ? Text(
                                              employer.business.displayName
                                                      .isNotEmpty
                                                  ? employer.business
                                                      .displayName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: WaUi.avatarInitial,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            employer.business.displayName,
                                            style: AttendanceUi.cardTitle,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            context.l10n.shiftRange(
                                              employer.shiftStart,
                                              employer.shiftEnd,
                                            ),
                                            style: AttendanceUi.bodyMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: WaUi.buttonDark,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      if (_todayStatus != null) _buildTodayCard(),
                      if (_summary != null) ...[
                        const SizedBox(height: 12),
                        _buildSummaryCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildTodayCard() {
    final status = _todayStatus!;
    final record = status.record;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AttendanceUi.radius),
        border: Border.all(color: WaUi.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.todayWithDate(
              DateFormat('EEE, MMM d').format(DateTime.now()),
            ),
            style: AttendanceUi.sectionTitle,
          ),
          const SizedBox(height: 12),
          if (status.isWeekend)
            Text(context.l10n.todayIsYourWeekend, style: AttendanceUi.body)
          else ...[
            if (record?.checkInTime != null)
              _timeRow(
                context.l10n.checkInColon,
                DateFormat('hh:mm a').format(record!.checkInTime!.toLocal()),
              ),
            if (record?.checkOutTime != null) ...[
              const SizedBox(height: 6),
              _timeRow(
                context.l10n.checkOutColon,
                DateFormat('hh:mm a').format(record!.checkOutTime!.toLocal()),
              ),
            ],
            if (record == null || record.checkInTime == null)
              Text(
                context.l10n.notCheckedInYet,
                style: AttendanceUi.body.copyWith(
                  color: const Color(0xFFC62828),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
          const SizedBox(height: 16),
          if (!status.isWeekend && status.canCheckIn)
            CustomAppButton(
              width: double.infinity,
              text: context.l10n.checkIn,
              icon: Icons.login_rounded,
              backgroundColor: WaUi.buttonDark,
              isLoading: _isMarking,
              onTap: () => _markAttendance('check_in'),
            ),
          if (!status.isWeekend && status.canCheckOut) ...[
            if (status.canCheckIn) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: WaUi.primaryButtonHeight,
              child: OutlinedButton.icon(
                onPressed:
                    _isMarking ? null : () => _markAttendance('check_out'),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(context.l10n.checkOut, style: WaUi.bodyMedium),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WaUi.primaryText,
                  side: const BorderSide(color: WaUi.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                  ),
                ),
              ),
            ),
          ],
          if (!status.isWeekend &&
              !status.canCheckIn &&
              !status.canCheckOut &&
              record?.checkOutTime != null)
            Text(
              context.l10n.attendanceCompletedForToday,
              style: AttendanceUi.body.copyWith(
                color: WaUi.navGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: AttendanceUi.bodyMuted),
        const SizedBox(width: 6),
        Text(value, style: WaUi.bodyMedium),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final summary = _summary!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceReportScreen(
                employee: _selectedEmployer,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AttendanceUi.softCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AttendanceUi.softIconBox(
                    icon: Icons.assessment_outlined,
                    bg: WaUi.chipBg,
                    fg: WaUi.navGreen,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.thisMonth,
                          style: WaUi.listTitle,
                        ),
                        Text(
                          DateFormat(context.l10n.mmmmYyyy)
                              .format(DateTime.now()),
                          style: WaUi.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    context.l10n.viewFullReport,
                    style: WaUi.caption.copyWith(
                      color: WaUi.navGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: WaUi.navGreen,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AttendanceUi.softStatTile(
                    label: context.l10n.present,
                    value: '${summary.present}',
                    tint: WaUi.navGreen,
                  ),
                  AttendanceUi.softStatTile(
                    label: context.l10n.absent,
                    value: '${summary.absent}',
                    tint: const Color(0xFFE57373),
                  ),
                  AttendanceUi.softStatTile(
                    label: context.l10n.partial,
                    value: '${summary.partial}',
                    tint: const Color(0xFFFFB74D),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 52,
              color: WaUi.secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.noEmployerFound,
              style: AttendanceUi.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.askYourBusinessToScanYourQRAndAddYouAsAnEmployee,
              textAlign: TextAlign.center,
              style: AttendanceUi.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}

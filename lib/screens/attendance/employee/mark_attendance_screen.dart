import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
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
        const SnackBar(
          content: Text('Location permission required for attendance'),
        ),
      );
      return;
    }

    final facePhoto = await FaceCaptureSheet.show(
      context,
      title: type == 'check_in' ? 'Check-in Face' : 'Check-out Face',
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
        content: Text(
          res.success
              ? (type == 'check_in'
                  ? 'Check-in successful'
                  : 'Check-out successful')
              : (res.message ?? 'Attendance failed'),
          style: AttendanceUi.body.copyWith(color: Colors.white),
        ),
        backgroundColor:
            res.success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );

    if (res.success) _loadTodayStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar(
        'Mark Attendance',
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet_outlined, size: 24),
            tooltip: 'Company Employee Card',
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
          ? const Center(child: CircularProgressIndicator())
          : _employers.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadEmployers,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      AttendanceUi.sectionHeader('Select Company'),
                      ..._employers.map((employer) {
                        final selected = _selectedEmployer?.id == employer.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () async {
                              setState(() => _selectedEmployer = employer);
                              await _loadTodayStatus();
                            },
                            borderRadius:
                                BorderRadius.circular(AttendanceUi.radius),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: selected
                                  ? AttendanceUi.thickCardFilled()
                                  : AttendanceUi.thickCard,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: selected
                                        ? Colors.white
                                        : WaUi.navPill,
                                    backgroundImage: employer
                                            .business.profilePhoto.isNotEmpty
                                        ? NetworkImage(
                                            employer.business.profilePhoto,
                                          )
                                        : null,
                                    child: employer.business.profilePhoto.isEmpty
                                        ? Text(
                                            employer.business.displayName
                                                    .isNotEmpty
                                                ? employer
                                                    .business.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: WaUi.avatarInitial.copyWith(
                                              color: selected
                                                  ? WaUi.primaryText
                                                  : WaUi.primaryText,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employer.business.displayName,
                                          style:
                                              AttendanceUi.cardTitle.copyWith(
                                            color: selected
                                                ? Colors.white
                                                : WaUi.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Shift ${employer.shiftStart} - ${employer.shiftEnd}',
                                          style: AttendanceUi.bodyMuted.copyWith(
                                            color: selected
                                                ? Colors.white70
                                                : WaUi.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: WaUi.accent,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      if (_todayStatus != null) _buildTodayCard(),
                      const SizedBox(height: 12),
                      if (_summary != null) _buildSummaryCard(),
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
      decoration: AttendanceUi.thickCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today • ${DateFormat('EEE, MMM d').format(DateTime.now())}',
            style: AttendanceUi.sectionTitle,
          ),
          const SizedBox(height: 12),
          if (status.isWeekend)
            Text('Today is your weekend', style: AttendanceUi.body)
          else ...[
            if (record?.checkInTime != null)
              Text(
                'Check-in: ${DateFormat('hh:mm a').format(record!.checkInTime!.toLocal())}',
                style: AttendanceUi.body,
              ),
            if (record?.checkOutTime != null)
              Text(
                'Check-out: ${DateFormat('hh:mm a').format(record!.checkOutTime!.toLocal())}',
                style: AttendanceUi.body,
              ),
            if (record == null || record.checkInTime == null)
              Text(
                'Not checked in yet',
                style: AttendanceUi.body.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
          const SizedBox(height: 16),
          if (!status.isWeekend && status.canCheckIn)
            AttendanceUi.primaryButton(
              label: 'Check in',
              icon: Icons.login,
              loading: _isMarking,
              onPressed: () => _markAttendance('check_in'),
            ),
          if (!status.isWeekend && status.canCheckOut) ...[
            const SizedBox(height: 10),
            AttendanceUi.secondaryButton(
              label: 'Check out',
              icon: Icons.logout,
              loading: _isMarking,
              onPressed: () => _markAttendance('check_out'),
            ),
          ],
          if (!status.isWeekend &&
              !status.canCheckIn &&
              !status.canCheckOut &&
              record?.checkOutTime != null)
            Text(
              'Attendance completed for today',
              style: AttendanceUi.body.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _summary!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AttendanceUi.thickCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month', style: AttendanceUi.sectionTitle),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: AttendanceUi.bodyMuted,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('Present', summary.present, Colors.green.shade700),
              _miniStat('Absent', summary.absent, Colors.red.shade700),
              _miniStat('Partial', summary.partial, Colors.orange.shade800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: AttendanceUi.statNumber.copyWith(color: color)),
          const SizedBox(height: 6),
          Text(label, style: AttendanceUi.statLabel),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AttendanceUi.thickCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.work_off_outlined,
                size: 48,
                color: WaUi.promoIconFg,
              ),
              const SizedBox(height: 16),
              Text('No employer found', style: AttendanceUi.sectionTitle),
              const SizedBox(height: 8),
              Text(
                'Ask your business to scan your QR and add you as an employee',
                textAlign: TextAlign.center,
                style: AttendanceUi.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

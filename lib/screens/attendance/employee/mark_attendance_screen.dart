import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/utils/location_helper.dart';
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
        backgroundColor: res.success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );

    if (res.success) _loadTodayStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar('Mark Attendance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : _employers.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadEmployers,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      AttendanceUi.sectionHeader('Select Company'),
                      ..._employers.map((employer) {
                        final selected = _selectedEmployer?.id == employer.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            onTap: () async {
                              setState(() => _selectedEmployer = employer);
                              await _loadTodayStatus();
                            },
                            borderRadius:
                                BorderRadius.circular(AttendanceUi.radius),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: selected
                                  ? AttendanceUi.thickCardFilled()
                                  : AttendanceUi.thickCard,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        selected ? Colors.white : Colors.black,
                                    backgroundImage: employer
                                            .business.profilePhoto.isNotEmpty
                                        ? NetworkImage(
                                            employer.business.profilePhoto,
                                          )
                                        : null,
                                    child: employer
                                            .business.profilePhoto.isEmpty
                                        ? Text(
                                            employer.business.displayName
                                                    .isNotEmpty
                                                ? employer
                                                    .business.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: selected
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employer.business.displayName,
                                          style: AttendanceUi.cardTitle.copyWith(
                                            color: selected
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Shift ${employer.shiftStart} - ${employer.shiftEnd}',
                                          style: AttendanceUi.bodyMuted.copyWith(
                                            color: selected
                                                ? Colors.white70
                                                : Colors.grey.shade700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      if (_todayStatus != null) _buildTodayCard(),
                      const SizedBox(height: 18),
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
      padding: const EdgeInsets.all(20),
      decoration: AttendanceUi.thickCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY • ${DateFormat('EEE, MMM d').format(DateTime.now()).toUpperCase()}',
            style: AttendanceUi.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 14),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
          const SizedBox(height: 20),
          if (!status.isWeekend && status.canCheckIn)
            AttendanceUi.primaryButton(
              label: 'CHECK IN',
              icon: Icons.login,
              loading: _isMarking,
              height: 68,
              onPressed: () => _markAttendance('check_in'),
            ),
          if (!status.isWeekend && status.canCheckOut) ...[
            const SizedBox(height: 12),
            AttendanceUi.secondaryButton(
              label: 'CHECK OUT',
              icon: Icons.logout,
              loading: _isMarking,
              height: 68,
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
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _summary!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AttendanceUi.thickCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS MONTH',
            style: AttendanceUi.sectionTitle.copyWith(fontSize: 20),
          ),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: AttendanceUi.bodyMuted,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _miniStat('PRESENT', summary.present, Colors.green.shade700),
              _miniStat('ABSENT', summary.absent, Colors.red.shade700),
              _miniStat('PARTIAL', summary.partial, Colors.orange.shade800),
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
          const SizedBox(height: 8),
          Text(label, style: AttendanceUi.statLabel.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: AttendanceUi.thickCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.work_off_outlined, size: 72, color: Colors.black54),
              const SizedBox(height: 16),
              Text('No employer found', style: AttendanceUi.sectionTitle),
              const SizedBox(height: 10),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_list_screen.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen> {
  List<AttendanceEmployee> _employees = [];
  List<AttendanceRecord> _todayRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final employeesRes = await AttendanceRepo().getBusinessEmployees();
    final recordsRes = await AttendanceRepo().getBusinessRecords(date: today);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (employeesRes.success) {
        _employees = parseAttendanceList(
          employeesRes.data,
          AttendanceEmployee.fromJson,
        ).where((e) => e.isAccepted).toList();
      }
      if (recordsRes.success) {
        _todayRecords = parseAttendanceList(
          recordsRes.data,
          AttendanceRecord.fromJson,
        );
      }
    });
  }

  AttendanceRecord? _recordForEmployee(String employeeRefId) {
    for (final record in _todayRecords) {
      if (record.employeeRefId == employeeRefId) return record;
    }
    return null;
  }

  String _statusLabel(AttendanceRecord? record) {
    if (record == null || record.checkInTime == null) return 'ABSENT';
    if (record.checkOutTime == null) return 'IN OFFICE';
    return 'PRESENT';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return Colors.green.shade700;
      case 'IN OFFICE':
        return Colors.orange.shade800;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _todayRecords
        .where((r) => r.checkInTime != null && r.checkOutTime != null)
        .length;
    final checkedInCount = _todayRecords
        .where((r) => r.checkInTime != null && r.checkOutTime == null)
        .length;
    final absentCount = _employees.length -
        _todayRecords.where((r) => r.checkInTime != null).length;

    return Scaffold(
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar(
        'Attendance',
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, size: 24),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      _statCard('PRESENT', presentCount, Colors.green.shade700),
                      const SizedBox(width: 12),
                      _statCard('IN OFFICE', checkedInCount, Colors.orange.shade800),
                      const SizedBox(width: 12),
                      _statCard('ABSENT', absentCount, Colors.red.shade700),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AttendanceUi.sectionHeader("Today's Attendance"),
                  if (_employees.isEmpty)
                    _emptyState()
                  else
                    ..._employees.map((employee) {
                      final record = _recordForEmployee(employee.id);
                      final status = _statusLabel(record);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeSettingsScreen(
                                  employee: employee,
                                ),
                              ),
                            );
                            _load();
                          },
                          borderRadius:
                              BorderRadius.circular(AttendanceUi.radius),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: AttendanceUi.thickCard,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: WaUi.navPill,
                                  backgroundImage: employee
                                          .employee.profilePhoto.isNotEmpty
                                      ? NetworkImage(
                                          employee.employee.profilePhoto,
                                        )
                                      : null,
                                  child: employee.employee.profilePhoto.isEmpty
                                      ? Text(
                                          employee.employee.name.isNotEmpty
                                              ? employee.employee.name[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: WaUi.avatarInitial,
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
                                        employee.employee.displayName,
                                        style: AttendanceUi.cardTitle,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${employee.shiftStart} - ${employee.shiftEnd}',
                                        style: AttendanceUi.bodyMuted,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      status,
                                      style: AttendanceUi.statLabel.copyWith(
                                        color: _statusColor(status),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (record?.checkInTime != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('hh:mm a').format(
                                          record!.checkInTime!.toLocal(),
                                        ),
                                        style: AttendanceUi.bodyMuted.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
              );
              _load();
            },
            backgroundColor: WaUi.buttonDark,
            foregroundColor: Colors.white,
            elevation: 0,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
            icon: const Icon(Icons.person_add_alt_1, size: 22),
            label: Text('Manage Employees', style: AttendanceUi.buttonLabel),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: AttendanceUi.thickCard,
        child: Column(
          children: [
            Text('$count', style: AttendanceUi.statNumber.copyWith(color: color)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AttendanceUi.statLabel.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AttendanceUi.thickCard,
      child: Column(
        children: [
          const Icon(Icons.groups_outlined, size: 48, color: WaUi.promoIconFg),
          const SizedBox(height: 16),
          Text('No employees yet', style: AttendanceUi.sectionTitle),
          const SizedBox(height: 10),
          Text(
            'Scan a user QR code to add them as employee',
            textAlign: TextAlign.center,
            style: AttendanceUi.bodyMuted,
          ),
        ],
      ),
    );
  }
}

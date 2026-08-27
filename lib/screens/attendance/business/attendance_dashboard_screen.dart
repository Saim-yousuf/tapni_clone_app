import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_list_screen.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';

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

  String _statusKey(AttendanceRecord? record) {
    if (record == null || record.checkInTime == null) return 'absent';
    if (record.checkOutTime == null) return 'in_office';
    return 'present';
  }

  String _statusLabel(String statusKey) {
    switch (statusKey) {
      case 'present':
        return context.l10n.presentUpper;
      case 'in_office':
        return context.l10n.inOFFICE;
      default:
        return context.l10n.absentUpper;
    }
  }

  Color _statusColor(String statusKey) {
    switch (statusKey) {
      case 'present':
        return const Color(0xFF1B8A4A);
      case 'in_office':
        return const Color(0xFFC46A00);
      default:
        return const Color(0xFFC62828);
    }
  }

  Future<void> _openEmployees() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
    );
    _load();
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
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar(
        context.l10n.attendance,
        actions: [
          IconButton(
            tooltip: context.l10n.manageEmployees,
            icon: const Icon(Icons.people_outline_rounded),
            onPressed: _openEmployees,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : RefreshIndicator(
                    color: WaUi.accent,
                    backgroundColor: Colors.white,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        Row(
                          children: [
                            _StatCard(
                              label: context.l10n.presentUpper,
                              count: presentCount,
                              color: const Color(0xFF1B8A4A),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: context.l10n.inOFFICE,
                              count: checkedInCount,
                              color: const Color(0xFFC46A00),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: context.l10n.absentUpper,
                              count: absentCount,
                              color: const Color(0xFFC62828),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.todaysAttendance,
                          style: AttendanceUi.sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        if (_employees.isEmpty)
                          _EmptyState(onManage: _openEmployees)
                        else
                          ..._employees.map((employee) {
                            final record = _recordForEmployee(employee.id);
                            final statusKey = _statusKey(record);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _EmployeeRow(
                                employee: employee,
                                statusLabel: _statusLabel(statusKey),
                                statusColor: _statusColor(statusKey),
                                checkInTime: record?.checkInTime,
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
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
          Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: CustomAppButton(
                  width: double.infinity,
                  text: context.l10n.manageEmployees,
                  icon: Icons.person_add_alt_1_rounded,
                  backgroundColor: AttendanceUi.buttonDark,
                  onTap: _openEmployees,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: AttendanceUi.thickCard,
        child: Column(
          children: [
            Text(
              '$count',
              style: AttendanceUi.statNumber.copyWith(color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AttendanceUi.statLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final AttendanceEmployee employee;
  final String statusLabel;
  final Color statusColor;
  final DateTime? checkInTime;
  final VoidCallback onTap;

  const _EmployeeRow({
    required this.employee,
    required this.statusLabel,
    required this.statusColor,
    required this.checkInTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee.employee.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: AttendanceUi.tileBg,
      borderRadius: BorderRadius.circular(AttendanceUi.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AttendanceUi.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: employee.employee.profilePhoto.isNotEmpty
                    ? NetworkImage(employee.employee.profilePhoto)
                    : null,
                child: employee.employee.profilePhoto.isEmpty
                    ? Text(initial, style: WaUi.avatarInitial)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AttendanceUi.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
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
                  AttendanceUi.statusText(
                    label: statusLabel,
                    color: statusColor,
                  ),
                  if (checkInTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(checkInTime!.toLocal()),
                      style: AttendanceUi.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onManage;

  const _EmptyState({required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: WaUi.secondaryText.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noEmployeesYet,
            style: AttendanceUi.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.scanAUserQRCodeToAddThemAsEmployee,
            textAlign: TextAlign.center,
            style: AttendanceUi.bodyMuted,
          ),
        ],
      ),
    );
  }
}

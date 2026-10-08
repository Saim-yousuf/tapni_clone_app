import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/attendance_report_screen.dart';
import 'package:tapni_app/screens/attendance/business/employee_list_screen.dart';
import 'package:tapni_app/screens/attendance/business/scan_to_invite_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

const _teamSectionCardBg = Color(0xFFF5F5F5);
const _teamStatCardBg = Color(0xFFF2F2F7);

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen> {
  List<AttendanceEmployee> _employees = [];
  List<AttendanceRecord> _todayRecords = [];
  int _pendingInviteCount = 0;
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
        final all = parseAttendanceList(
          employeesRes.data,
          AttendanceEmployee.fromJson,
        );
        _pendingInviteCount =
            all.where((e) => e.isPendingInvitation).length;
        _employees = all.where((e) => e.isAccepted).toList();
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

  // Kept for attendance status mapping (report / future UI).
  // ignore: unused_element
  String _statusKey(AttendanceRecord? record) {
    if (record == null || record.checkInTime == null) return 'absent';
    if (record.checkOutTime == null) return 'in_office';
    return 'present';
  }

  // ignore: unused_element
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

  // ignore: unused_element
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

  List<AttendanceEmployee> get _presentEmployees {
    return _employees.where((employee) {
      final record = _recordForEmployee(employee.id);
      return record?.checkInTime != null;
    }).toList();
  }

  List<AttendanceEmployee> get _absentEmployees {
    return _employees.where((employee) {
      final record = _recordForEmployee(employee.id);
      return record == null || record.checkInTime == null;
    }).toList();
  }

  Future<void> _openEmployees() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
    );
    _load();
  }

  Future<void> _scanToAddMember() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanToInviteScreen()),
    );
    _load();
  }

  Future<void> _openEmployeeReport(AttendanceEmployee employee) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceReportScreen(
          employee: employee,
          isBusinessView: true,
        ),
      ),
    );
  }

  Future<void> _showEmployeeReportPicker() async {
    if (_employees.length == 1) {
      await _openEmployeeReport(_employees.first);
      return;
    }

    final picked = await showModalBottomSheet<AttendanceEmployee>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: context.l10n.attendanceReport,
                onBack: () => Navigator.pop(ctx),
              ),
              ..._employees.map(
                (employee) => ListTile(
                  leading: _EmployeeAvatar(employee: employee, radius: 22),
                  title: Text(
                    employee.employee.displayName,
                    style: WaUi.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '${employee.shiftStart} - ${employee.shiftEnd}',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, employee),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null && mounted) {
      await _openEmployeeReport(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentEmployees = _presentEmployees;
    final absentEmployees = _absentEmployees;
    final sendInviteCount =
        _pendingInviteCount > 0 ? _pendingInviteCount : 0;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Team',
              trailing: _employees.isEmpty
                  ? null
                  : CircleAssetButton(
                      asset: 'assets/images/png/file-icon.png',
                      iconSize: 18,
                      onTap: _showEmployeeReportPicker,
                    ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : RefreshIndicator(
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      onRefresh: _load,
                      child: _employees.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: _TeamEmptyState(
                                        onAdd: _openEmployees,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                BarqodyChrome.sidePad,
                                16,
                                BarqodyChrome.sidePad,
                                16,
                              ),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TeamStatCard(
                                        label: 'Active Members',
                                        count: _employees.length,
                                        iconAsset:
                                            'assets/images/png/account-icon.png',
                                        onTap: _openEmployees,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _TeamStatCard(
                                        label: 'Send Invite',
                                        count: sendInviteCount,
                                        iconAsset:
                                            'assets/images/png/email-icon-1.png',
                                        onTap: _openEmployees,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _MemberSectionCard(
                                  title: 'Present Members',
                                  count: presentEmployees.length,
                                  employees: presentEmployees,
                                  onViewAll: _openEmployees,
                                ),
                                const SizedBox(height: 12),
                                _MemberSectionCard(
                                  title: 'Absent Members',
                                  count: absentEmployees.length,
                                  employees: absentEmployees,
                                  onViewAll: _openEmployees,
                                ),
                              ],
                            ),
                    ),
            ),
            if (!_isLoading && _employees.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  4,
                  BarqodyChrome.sidePad,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: PillButton(
                          label: 'View Members',
                          filled: false,
                          onPressed: _openEmployees,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: PillButton(
                          label: 'Add Member',
                          onPressed: _scanToAddMember,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _TeamEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/png/leadership.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.groups_outlined,
              size: 80,
              color: BarqodyChrome.secondaryText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Build Your Team',
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: 22,
              weight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No team members have been added yet. Add employees to get your team started',
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 15,
              height: 1.45,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          const SizedBox(height: 32),
          PillButton(
            label: 'Add Team Member',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _TeamStatCard extends StatelessWidget {
  final String label;
  final int count;
  final String iconAsset;
  final VoidCallback? onTap;

  const _TeamStatCard({
    required this.label,
    required this.count,
    required this.iconAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _teamStatCardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1.1),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    iconAsset,
                    width: 18,
                    height: 18,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: WaUi.toolsTitleOf(
                    size: 28,
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BarqodyChrome.secondaryText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberSectionCard extends StatelessWidget {
  final String title;
  final int count;
  final List<AttendanceEmployee> employees;
  final VoidCallback onViewAll;

  const _MemberSectionCard({
    required this.title,
    required this.count,
    required this.employees,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final preview = employees.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _teamSectionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: WaUi.toolsTitleOf(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                '$count',
                style: WaUi.toolsTitleOf(
                  size: 16,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (preview.isEmpty)
                Text(
                  '—',
                  style: WaUi.body.copyWith(
                    color: BarqodyChrome.secondaryText,
                    fontSize: 15,
                  ),
                )
              else
                SizedBox(
                  height: 44,
                  width: 44 + (preview.length - 1) * 24.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < preview.length; i++)
                        Positioned(
                          left: i * 24.0,
                          child: _EmployeeAvatar(
                            employee: preview[i],
                            radius: 20,
                            border: true,
                          ),
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.seeAll,
                          style: WaUi.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/png/multiple-users.png',
                          width: 18,
                          height: 18,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.groups_outlined,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  final AttendanceEmployee employee;
  final double radius;
  final bool border;

  const _EmployeeAvatar({
    required this.employee,
    this.radius = 20,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee.employee.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: border
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: employee.employee.profilePhoto.isNotEmpty
            ? NetworkImage(employee.employee.profilePhoto)
            : null,
        child: employee.employee.profilePhoto.isEmpty
            ? Text(
                initial,
                style: WaUi.avatarInitial.copyWith(fontSize: radius * 0.85),
              )
            : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/attendance_report_screen.dart';
import 'package:tapni_app/screens/attendance/business/employee_list_screen.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/screens/attendance/business/scan_to_invite_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  static const routeName = 'attendance_dashboard';

  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

/// Team dashboard card fill (user-specified).
const _teamCardBg = Color(0xFFF3F4F6);
const _teamCardRadius = 18.0;

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
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanToInviteScreen()),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      EmployeeSettingsScreen.showResultSnack(context, result);
    }
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
    final m = AuthScale.of(context);
    final side = m.s(BarqodyChrome.sidePad);
    final presentEmployees = _presentEmployees;
    final absentEmployees = _absentEmployees;
    final sendInviteCount =
        _pendingInviteCount > 0 ? _pendingInviteCount : 0;
    // Pending invites count as team activity — don't keep the empty state
    // after Scan-to-invite succeeds (member is pending until they accept).
    final showDashboard =
        _employees.isNotEmpty || _pendingInviteCount > 0;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Screenshot: back + centered "Team" only (no trailing action).
            const BarqodyTitleBar(title: 'Team'),
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
                      child: !showDashboard
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
                                        onAdd: _scanToAddMember,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView(
                              padding: EdgeInsets.fromLTRB(
                                side,
                                0,
                                side,
                                m.v(16),
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
                                    SizedBox(width: m.s(12)),
                                    Expanded(
                                      child: _TeamStatCard(
                                        label: 'Send Invite',
                                        count: sendInviteCount,
                                        iconAsset:
                                            'assets/images/png/email-icon-1.png',
                                        onTap: _scanToAddMember,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: m.v(14)),
                                _MemberSectionCard(
                                  title: 'Present Members',
                                  subtitle: 'Currently active team members',
                                  count: presentEmployees.length,
                                  employees: presentEmployees,
                                  onViewAll: _openEmployees,
                                ),
                                SizedBox(height: m.v(12)),
                                _MemberSectionCard(
                                  title: 'Absent Members',
                                  subtitle: 'Currently absent team members',
                                  count: absentEmployees.length,
                                  employees: absentEmployees,
                                  onViewAll: _openEmployees,
                                ),
                              ],
                            ),
                    ),
            ),
            if (!_isLoading && showDashboard)
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    m.v(12),
                    side,
                    m.v(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'View Members',
                          filled: false,
                          onPressed: _openEmployees,
                        ),
                      ),
                      SizedBox(width: m.s(12)),
                      Expanded(
                        child: PillButton(
                          label: 'Add Member',
                          onPressed: _scanToAddMember,
                        ),
                      ),
                    ],
                  ),
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
    final m = AuthScale.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: m.s(32),
        vertical: m.v(48),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/png/leadership.png',
            width: m.s(160),
            height: m.s(160),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.groups_outlined,
              size: m.s(80),
              color: BarqodyChrome.secondaryText.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: m.v(28)),
          Text(
            'Build Your Team',
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: m.s(22),
              weight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          SizedBox(height: m.v(10)),
          Text(
            'No team members have been added yet. Add employees to get your team started',
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: m.s(15),
              height: 1.45,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          SizedBox(height: m.v(32)),
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
    final m = AuthScale.of(context);
    final iconBox = m.s(44);
    final iconSize = m.s(24);
    final radius = m.s(_teamCardRadius);

    return Material(
      color: _teamCardBg,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          // Shorter than square — compact stat tiles.
          aspectRatio: 1.35,
          child: Padding(
            padding: EdgeInsets.fromLTRB(m.s(14), m.s(12), m.s(12), m.s(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      iconAsset,
                      width: iconSize,
                      height: iconSize,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_outline,
                        size: iconSize,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: WaUi.toolsTitleOf(
                    size: m.s(28),
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
                SizedBox(height: m.v(2)),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.body.copyWith(
                    fontSize: m.s(12),
                    fontWeight: FontWeight.w500,
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
  final String subtitle;
  final int count;
  final List<AttendanceEmployee> employees;
  final VoidCallback onViewAll;

  const _MemberSectionCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.employees,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final preview = employees.take(3).toList();
    final radius = m.s(_teamCardRadius);
    final pad = m.s(14);
    final isEmpty = employees.isEmpty;
    final emptyLabel = title.toLowerCase().contains('absent')
        ? 'No one is absent'
        : 'No one is present';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: _teamCardBg,
        borderRadius: BorderRadius.circular(radius),
        border: isEmpty
            ? Border.all(
                color: Colors.black.withValues(alpha: 0.12),
                width: 1,
              )
            : null,
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
                    size: m.s(15),
                    weight: FontWeight.w700,
                    color: isEmpty
                        ? BarqodyChrome.secondaryText
                        : Colors.black,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                '$count',
                style: WaUi.toolsTitleOf(
                  size: m.s(15),
                  weight: FontWeight.w700,
                  color: isEmpty
                      ? BarqodyChrome.secondaryText
                      : Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: m.v(4)),
          Text(
            subtitle,
            style: WaUi.body.copyWith(
              fontSize: m.s(12),
              fontWeight: FontWeight.w400,
              color: BarqodyChrome.secondaryText,
              height: 1.3,
            ),
          ),
          SizedBox(height: m.v(isEmpty ? 14 : 16)),
          if (isEmpty)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: m.s(12),
                      vertical: m.v(14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(m.s(12)),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: m.s(20),
                          color: BarqodyChrome.secondaryText,
                        ),
                        SizedBox(width: m.s(10)),
                        Expanded(
                          child: Text(
                            emptyLabel,
                            style: WaUi.body.copyWith(
                              fontSize: m.s(13),
                              fontWeight: FontWeight.w600,
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: m.s(10)),
                _ViewAllItem(onTap: onViewAll),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final employee in preview)
                  Expanded(
                    child: Center(
                      child: _MemberAvatarItem(employee: employee),
                    ),
                  ),
                for (var i = preview.length; i < 3; i++)
                  const Expanded(child: SizedBox.shrink()),
                Expanded(
                  child: Center(child: _ViewAllItem(onTap: onViewAll)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MemberAvatarItem extends StatelessWidget {
  final AttendanceEmployee employee;

  const _MemberAvatarItem({required this.employee});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final fullName = employee.employee.displayName.trim();
    final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
    final radius = m.s(24);
    final nameW = m.s(58);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EmployeeAvatar(employee: employee, radius: radius),
        SizedBox(height: m.v(6)),
        SizedBox(
          width: nameW,
          child: Text(
            firstName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WaUi.body.copyWith(
              fontSize: m.s(11),
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewAllItem extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final box = m.s(48);
    final icon = m.s(20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(box / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: box,
              height: box,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/png/multiple-users.png',
                width: icon,
                height: icon,
                errorBuilder: (_, _, _) => Icon(
                  Icons.groups_outlined,
                  size: icon,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: m.v(8)),
            Text(
              'View All',
              style: WaUi.body.copyWith(
                fontSize: m.s(12),
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  final AttendanceEmployee employee;
  final double radius;

  const _EmployeeAvatar({
    required this.employee,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee.employee.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<AttendanceEmployee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await AttendanceRepo().getBusinessEmployees();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success) {
        _employees = parseAttendanceList(
          res.data,
          AttendanceEmployee.fromJson,
        );
      }
    });
  }

  Future<void> _scanToInvite() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    _load();
  }

  Future<void> _openSettings(AttendanceEmployee employee) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeSettingsScreen(employee: employee),
      ),
    );
    _load();
  }

  Future<void> _removeEmployee(AttendanceEmployee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
        ),
        title: Text(
          context.l10n.removeEmployee,
          style: AttendanceUi.sectionTitle,
        ),
        content: Text(
          context.l10n.removeEmployeeFromTeam(employee.employee.displayName),
          style: AttendanceUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.remove, style: AttendanceUi.buttonLabel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await AttendanceRepo().removeEmployee(employee.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          res.success
              ? context.l10n.employeeRemoved
              : (res.message ?? context.l10n.failedToRemove),
          style: WaUi.body,
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar(context.l10n.employees),
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
                    child: _employees.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_search_outlined,
                                        size: 48,
                                        color: WaUi.secondaryText
                                            .withValues(alpha: 0.45),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        context.l10n.noEmployeesAdded,
                                        style: AttendanceUi.sectionTitle,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.l10n
                                            .scanAnyUserOrBusinessQRToAddEmployee,
                                        textAlign: TextAlign.center,
                                        style: AttendanceUi.bodyMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _employees.length,
                            itemBuilder: (_, i) {
                              final employee = _employees[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _EmployeeTile(
                                  employee: employee,
                                  onTap: () => _openSettings(employee),
                                  onEdit: () => _openSettings(employee),
                                  onRemove: () => _removeEmployee(employee),
                                ),
                              );
                            },
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
                  text: context.l10n.scanToInvite,
                  icon: Icons.qr_code_scanner_rounded,
                  backgroundColor: AttendanceUi.buttonDark,
                  onTap: _scanToInvite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final AttendanceEmployee employee;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _EmployeeTile({
    required this.employee,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee.employee.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final username = employee.employee.username;

    return Material(
      color: AttendanceUi.tileBg,
      borderRadius: BorderRadius.circular(AttendanceUi.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AttendanceUi.radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
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
                    if (employee.isPendingInvitation) ...[
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.pendingACCEPTANCE,
                        style: WaUi.label.copyWith(
                          color: const Color(0xFFC46A00),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: AttendanceUi.bodyMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${employee.shiftStart} - ${employee.shiftEnd}',
                      style: AttendanceUi.bodyMuted,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: WaUi.secondaryText.withValues(alpha: 0.85),
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      context.l10n.editSettings,
                      style: AttendanceUi.body,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      context.l10n.remove,
                      style: AttendanceUi.body.copyWith(
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

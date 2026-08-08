import 'package:flutter/material.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
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

  Future<void> _removeEmployee(AttendanceEmployee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
        ),
        title: Text(context.l10n.removeEmployee, style: AttendanceUi.sectionTitle),
        content: Text(
          context.l10n.removeEmployeeFromTeam(employee.employee.displayName),
          style: AttendanceUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(100, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusPill),
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
        content: Text(
          res.success ? context.l10n.employeeRemoved : (res.message ?? context.l10n.failedToRemove),
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar(context.l10n.employees),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _employees.isEmpty
                  ? ListView(
                      padding: EdgeInsets.all(20),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(28),
                              decoration: AttendanceUi.thickCard,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_search_outlined,
                                      size: 48, color: WaUi.promoIconFg),
                                  SizedBox(height: 16),
                                  Text(
                                    context.l10n.noEmployeesAdded,
                                    style: AttendanceUi.sectionTitle,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    context.l10n.scanAnyUserOrBusinessQRToAddEmployee,
                                    textAlign: TextAlign.center,
                                    style: AttendanceUi.bodyMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _employees.length,
                      itemBuilder: (_, i) {
                        final employee = _employees[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            decoration: AttendanceUi.thickCard,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
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
                              title: Text(
                                employee.employee.displayName,
                                style: AttendanceUi.cardTitle,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (employee.isPendingInvitation)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        context.l10n.pendingACCEPTANCE,
                                        style: AttendanceUi.bodyMuted.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '@${employee.employee.username}\n'
                                    '${employee.shiftStart} - ${employee.shiftEnd}',
                                    style: AttendanceUi.bodyMuted.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, size: 28),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmployeeSettingsScreen(
                                          employee: employee,
                                        ),
                                      ),
                                    );
                                    _load();
                                  } else if (value == 'remove') {
                                    _removeEmployee(employee);
                                  }
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
                                      style: AttendanceUi.body,
                                    ),
                                  ),
                                ],
                              ),
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
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ScanScreen()),
              );
            },
            backgroundColor: WaUi.buttonDark,
            foregroundColor: Colors.white,
            elevation: 0,
            extendedPadding: EdgeInsets.symmetric(horizontal: 24),
            icon: Icon(Icons.qr_code_scanner, size: 22),
            label: Text(context.l10n.scanToInvite, style: AttendanceUi.buttonLabel),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

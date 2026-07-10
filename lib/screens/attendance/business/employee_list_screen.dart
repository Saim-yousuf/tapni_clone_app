import 'package:flutter/material.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

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
          borderRadius: BorderRadius.circular(AttendanceUi.radius),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text('Remove Employee', style: AttendanceUi.sectionTitle),
        content: Text(
          'Remove ${employee.employee.displayName} from your team?',
          style: AttendanceUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AttendanceUi.buttonLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: AttendanceUi.buttonLabel),
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
          res.success ? 'Employee removed' : (res.message ?? 'Failed to remove'),
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar('Employees'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : RefreshIndicator(
              onRefresh: _load,
              child: _employees.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: AttendanceUi.thickCard,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_search_outlined,
                                      size: 72, color: Colors.black54),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No employees added',
                                    style: AttendanceUi.sectionTitle,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Scan any user or business QR to add employee',
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
                                radius: 28,
                                backgroundColor: Colors.black,
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
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
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'PENDING ACCEPTANCE',
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
                                icon: const Icon(Icons.more_vert, size: 28),
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
                                      'Edit Settings',
                                      style: AttendanceUi.body,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text(
                                      'Remove',
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: Text('Scan to Invite', style: AttendanceUi.buttonLabel),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

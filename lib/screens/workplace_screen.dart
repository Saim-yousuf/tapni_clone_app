import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/attendance/employee/mark_attendance_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

class WorkplaceScreen extends StatefulWidget {
  const WorkplaceScreen({super.key});

  @override
  State<WorkplaceScreen> createState() => _WorkplaceScreenState();
}

class _WorkplaceScreenState extends State<WorkplaceScreen> {
  int _pendingInvitationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingInvitations();
  }

  Future<void> _loadPendingInvitations() async {
    final res = await AttendanceRepo().getMyInvitations();
    if (!mounted) return;
    if (res.success) {
      final invitations = parseAttendanceList(
        res.data,
        AttendanceEmployee.fromJson,
      );
      setState(() => _pendingInvitationCount = invitations.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(context.l10n.workplace, style: WaUi.title),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          WaToolsListTile(
            icon: Icons.mail_outline,
            title: context.l10n.employeeInvitations,
            subtitle: context.l10n.employeeInvitationsSubtitle,
            showBadge: _pendingInvitationCount > 0,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmployeeInvitationsScreen(),
                ),
              );
              _loadPendingInvitations();
            },
          ),
          WaToolsListTile(
            icon: Icons.fact_check_outlined,
            title: context.l10n.workplaceCheckIn,
            subtitle: context.l10n.workplaceCheckInSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MarkAttendanceScreen(),
                ),
              );
            },
          ),
          WaToolsListTile(
            icon: Icons.badge_outlined,
            title: context.l10n.companyEmployeeCard,
            subtitle: context.l10n.saveYourWorkIDCardToPhoneOrWallet,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmployeeBusinessCardsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

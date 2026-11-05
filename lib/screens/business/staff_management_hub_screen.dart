import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/attendance/business/attendance_dashboard_screen.dart';
import 'package:tapni_app/screens/booking/bookable_resources_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Groups team attendance + bookable specialists in one module.
class StaffManagementHubScreen extends StatelessWidget {
  const StaffManagementHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Staff Management'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const WaSectionHeader('Team'),
                  WaToolsListTile(
                    icon: Icons.groups_outlined,
                    title: context.l10n.teamAttendance,
                    subtitle: context
                        .l10n.inviteEmployeesSetShiftsAndTrackPresence,
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageRoute(
                          settings: const RouteSettings(
                            name: AttendanceDashboardScreen.routeName,
                          ),
                          builder: (_) => const AttendanceDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  const WaSectionHeader('Bookable staff'),
                  WaToolsListTile(
                    icon: Icons.badge_outlined,
                    title: 'Specialists',
                    subtitle:
                        'Staff who can be assigned to appointments and bookings',
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageRoute(
                          builder: (_) => const BookableResourcesScreen(
                            allowedTypes: ['staff'],
                            title: 'Specialists',
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      'General business settings stay in Business Profile. '
                      'Feature-specific team tools live here.',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                        height: 1.35,
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

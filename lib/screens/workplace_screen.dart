import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/attendance_report_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/attendance/employee/mark_attendance_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

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
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: context.l10n.workplace),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  20,
                  BarqodyChrome.sidePad,
                  24,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                  children: [
                    _WorkplaceHubCard(
                      iconAsset: 'assets/images/png/email-icon-1.png',
                      title: 'Invitations',
                      subtitle: 'Manage invites',
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
                    _WorkplaceHubCard(
                      iconAsset: 'assets/images/png/check-icon-1.png',
                      title: 'Check In',
                      subtitle: 'Mark attendance',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MarkAttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    _WorkplaceHubCard(
                      iconAsset: 'assets/images/png/file-icon.png',
                      title: 'Reports',
                      subtitle: 'View reports',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AttendanceReportScreen(),
                          ),
                        );
                      },
                    ),
                    _WorkplaceHubCard(
                      iconAsset: 'assets/images/png/card-icon.png',
                      title: 'Employee Card',
                      subtitle: 'View details',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const EmployeeBusinessCardsScreen(),
                          ),
                        );
                      },
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

class _WorkplaceHubCard extends StatelessWidget {
  static const Color _cardBg = Color(0xFFF5F6F7);

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showBadge;

  const _WorkplaceHubCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      iconAsset,
                      width: 20,
                      height: 20,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.circle_outlined,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 0,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.toolsTitleOf(
                  size: 15,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: BarqodyChrome.secondaryText,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

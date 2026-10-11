import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/attendance_report_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/attendance/employee/mark_attendance_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class WorkplaceScreen extends StatefulWidget {
  const WorkplaceScreen({super.key});

  @override
  State<WorkplaceScreen> createState() => _WorkplaceScreenState();
}

class _WorkplaceScreenState extends State<WorkplaceScreen> {
  /// Figma Workplace card fill.
  static const _cardBg = Color(0xFFF3F4F6);

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
    final m = AuthScale.of(context);
    final gap = m.s(14);
    final side = m.s(BarqodyChrome.sidePad);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: context.l10n.workplace),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(side, 0, side, m.v(24)),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  // Slightly wider than tall — compact hub tiles.
                  childAspectRatio: 1.12,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _WorkplaceHubCard(
                      cardBg: _cardBg,
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
                      cardBg: _cardBg,
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
                      cardBg: _cardBg,
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
                      cardBg: _cardBg,
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
  final Color cardBg;
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showBadge;

  const _WorkplaceHubCard({
    required this.cardBg,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final radius = m.s(18);
    final iconBox = m.s(48);
    final iconSize = m.s(24);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: m.s(10),
            vertical: m.v(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
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
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.circle_outlined,
                        size: iconSize,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: m.s(10),
                        height: m.s(10),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: m.v(12)),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.textStyle(
                  fontSize: m.s(15),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: m.v(8)),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.body.copyWith(
                  fontSize: m.s(14),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class EmployeeInvitationsScreen extends StatefulWidget {
  const EmployeeInvitationsScreen({super.key});

  @override
  State<EmployeeInvitationsScreen> createState() =>
      _EmployeeInvitationsScreenState();
}

class _EmployeeInvitationsScreenState extends State<EmployeeInvitationsScreen> {
  List<AttendanceEmployee> _invitations = [];
  bool _isLoading = true;
  String? _respondingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await AttendanceRepo().getMyInvitations();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success) {
        _invitations = parseAttendanceList(
          res.data,
          AttendanceEmployee.fromJson,
        );
      }
    });
  }

  Future<void> _respond(AttendanceEmployee invitation, bool accept) async {
    setState(() => _respondingId = invitation.id);
    final res = accept
        ? await AttendanceRepo().acceptInvitation(invitation.id)
        : await AttendanceRepo().declineInvitation(invitation.id);
    if (!mounted) return;
    setState(() => _respondingId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          res.success
              ? (accept
                  ? context.l10n
                      .youJoinedBusiness(invitation.business.displayName)
                  : context.l10n.invitationDeclined)
              : (res.message ?? context.l10n.somethingWentWrong),
          style: WaUi.body,
        ),
      ),
    );

    if (res.success) {
      Provider.of<LeadsProvider>(context, listen: false)
          .fetchEmployeeInvitationNotifications();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: context.l10n.invitations),
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
                      child: _invitations.isEmpty
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
                                        Image.asset(
                                          'assets/images/png/email-icon-1.png',
                                          width: 56,
                                          height: 56,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.mail_outline_rounded,
                                            size: 52,
                                            color: BarqodyChrome.secondaryText
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          context.l10n.noPendingInvitations,
                                          style: WaUi.toolsTitleOf(
                                            size: 18,
                                            weight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.l10n
                                              .whenABusinessInvitesYouToTheirTeamItWillAppearHere,
                                          textAlign: TextAlign.center,
                                          style: WaUi.body.copyWith(
                                            fontSize: 14,
                                            color: BarqodyChrome.secondaryText,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                              itemCount: _invitations.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final invitation = _invitations[i];
                                final isResponding =
                                    _respondingId == invitation.id;
                                final name = invitation.business.displayName;
                                final initial = name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?';

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: BarqodyChrome.fieldFill,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: Colors.white,
                                            backgroundImage: invitation.business
                                                    .profilePhoto.isNotEmpty
                                                ? NetworkImage(
                                                    invitation
                                                        .business.profilePhoto,
                                                  )
                                                : null,
                                            child: invitation.business
                                                    .profilePhoto.isEmpty
                                                ? Text(
                                                    initial,
                                                    style: WaUi.body.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: WaUi.body.copyWith(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  context.l10n
                                                      .invitedYouToJoinAsEmployee,
                                                  style: WaUi.body.copyWith(
                                                    fontSize: 13,
                                                    color: BarqodyChrome
                                                        .secondaryText,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  context.l10n.shiftLabel(
                                                    invitation.shiftStart,
                                                    invitation.shiftEnd,
                                                  ),
                                                  style: WaUi.body.copyWith(
                                                    fontSize: 12,
                                                    color: BarqodyChrome
                                                        .secondaryText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: WaUi.primaryButtonHeight,
                                              child: OutlinedButton(
                                                onPressed: isResponding
                                                    ? null
                                                    : () => _respond(
                                                          invitation,
                                                          false,
                                                        ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.black,
                                                  side: const BorderSide(
                                                    color: Colors.black,
                                                    width: 1.2,
                                                  ),
                                                  shape: const StadiumBorder(),
                                                ),
                                                child: Text(
                                                  context.l10n.decline,
                                                  style: WaUi.body.copyWith(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: PillButton(
                                              label: context.l10n.accept,
                                              enabled: !isResponding,
                                              onPressed: () =>
                                                  _respond(invitation, true),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

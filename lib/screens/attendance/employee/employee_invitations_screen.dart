import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
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
        content: Text(
          res.success
              ? (accept
                  ? 'You joined ${invitation.business.displayName}'
                  : context.l10n.invitationDeclined)
              : (res.message ?? context.l10n.somethingWentWrong),
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
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar(context.l10n.employeeInvitations),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _invitations.isEmpty
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
                                  Icon(Icons.mail_outline,
                                      size: 48, color: WaUi.promoIconFg),
                                  SizedBox(height: 16),
                                  Text(
                                    context.l10n.noPendingInvitations,
                                    style: AttendanceUi.sectionTitle,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    context.l10n.whenABusinessInvitesYouToTheirTeamItWillAppearHere,
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: _invitations.length,
                      itemBuilder: (_, i) {
                        final invitation = _invitations[i];
                        final isResponding = _respondingId == invitation.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: AttendanceUi.thickCard,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: WaUi.navPill,
                                      backgroundImage: invitation
                                              .business.profilePhoto.isNotEmpty
                                          ? NetworkImage(
                                              invitation.business.profilePhoto,
                                            )
                                          : null,
                                      child: invitation
                                              .business.profilePhoto.isEmpty
                                          ? Text(
                                              invitation.business.displayName
                                                      .isNotEmpty
                                                  ? invitation
                                                      .business.displayName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: WaUi.avatarInitial,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invitation.business.displayName,
                                            style: AttendanceUi.cardTitle,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            context.l10n.invitedYouToJoinAsEmployee,
                                            style: AttendanceUi.bodyMuted
                                                .copyWith(fontSize: 16),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Shift: ${invitation.shiftStart} - ${invitation.shiftEnd}',
                                            style: AttendanceUi.bodyMuted
                                                .copyWith(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AttendanceUi.secondaryButton(
                                        label: context.l10n.decline,
                                        icon: Icons.close,
                                        loading: isResponding,
                                        onPressed: isResponding
                                            ? null
                                            : () => _respond(invitation, false),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: AttendanceUi.primaryButton(
                                        label: context.l10n.accept,
                                        icon: Icons.check,
                                        loading: isResponding,
                                        onPressed: isResponding
                                            ? null
                                            : () => _respond(invitation, true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

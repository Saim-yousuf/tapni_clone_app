import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';

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
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar(context.l10n.employeeInvitations),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : RefreshIndicator(
              color: WaUi.accent,
              backgroundColor: Colors.white,
              onRefresh: _load,
              child: _invitations.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  size: 52,
                                  color: WaUi.secondaryText
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  context.l10n.noPendingInvitations,
                                  style: AttendanceUi.sectionTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n
                                      .whenABusinessInvitesYouToTheirTeamItWillAppearHere,
                                  textAlign: TextAlign.center,
                                  style: AttendanceUi.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _invitations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final invitation = _invitations[i];
                        final isResponding = _respondingId == invitation.id;
                        final name = invitation.business.displayName;
                        final initial =
                            name.isNotEmpty ? name[0].toUpperCase() : '?';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AttendanceUi.radius),
                            border: Border.all(color: WaUi.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AttendanceUi.tileBg,
                                    backgroundImage: invitation
                                            .business.profilePhoto.isNotEmpty
                                        ? NetworkImage(
                                            invitation.business.profilePhoto,
                                          )
                                        : null,
                                    child: invitation
                                            .business.profilePhoto.isEmpty
                                        ? Text(
                                            initial,
                                            style: WaUi.avatarInitial,
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
                                          style: AttendanceUi.cardTitle,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          context.l10n
                                              .invitedYouToJoinAsEmployee,
                                          style: AttendanceUi.bodyMuted,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          context.l10n.shiftLabel(
                                            invitation.shiftStart,
                                            invitation.shiftEnd,
                                          ),
                                          style: WaUi.caption
                                              .copyWith(fontSize: 12),
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
                                            : () =>
                                                _respond(invitation, false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: WaUi.primaryText,
                                          side: const BorderSide(
                                            color: WaUi.divider,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                              WaUi.radiusMd,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          context.l10n.decline,
                                          style: WaUi.bodyMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomAppButton(
                                      text: context.l10n.accept,
                                      icon: Icons.check_rounded,
                                      backgroundColor: WaUi.buttonDark,
                                      isLoading: isResponding,
                                      onTap: () =>
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
    );
  }
}

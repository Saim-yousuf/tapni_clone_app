import 'package:flutter/material.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

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
                  : 'Invitation declined')
              : (res.message ?? 'Something went wrong'),
        ),
      ),
    );

    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar('Employee Invitations'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : RefreshIndicator(
              onRefresh: _load,
              child: _invitations.isEmpty
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
                                  const Icon(Icons.mail_outline,
                                      size: 72, color: Colors.black54),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pending invitations',
                                    style: AttendanceUi.sectionTitle,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'When a business invites you to their team, it will appear here.',
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
                                      radius: 28,
                                      backgroundColor: Colors.black,
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
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invitation.business.displayName,
                                            style: AttendanceUi.cardTitle,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Invited you to join as employee',
                                            style: AttendanceUi.bodyMuted
                                                .copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
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
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AttendanceUi.secondaryButton(
                                        label: 'Decline',
                                        icon: Icons.close,
                                        loading: isResponding,
                                        onPressed: isResponding
                                            ? null
                                            : () => _respond(invitation, false),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AttendanceUi.primaryButton(
                                        label: 'Accept',
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

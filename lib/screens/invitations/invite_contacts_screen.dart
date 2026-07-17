import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:tapni_app/screens/invitations/invitation_nav.dart';

class InviteContactsScreen extends StatefulWidget {
  final InvitationDraft draft;

  const InviteContactsScreen({super.key, required this.draft});

  @override
  State<InviteContactsScreen> createState() => _InviteContactsScreenState();
}

class _DeviceContactRow {
  final String displayName;
  final String phone;
  final MatchedPhoneUser? matchedUser;
  final bool isRegistered;

  _DeviceContactRow({
    required this.displayName,
    required this.phone,
    this.matchedUser,
    this.isRegistered = false,
  });
}

class _InviteContactsScreenState extends State<InviteContactsScreen> {
  bool _loading = true;
  String? _error;
  List<_DeviceContactRow> _rows = [];
  final Set<String> _selectedUserIds = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Contacts permission is required to invite people.';
      });
      return;
    }

    try {
      final invitationProvider = context.read<InvitationProvider>();
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final phoneToName = <String, String>{};

      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = PhoneUtils.normalize(phone.number);
          if (!PhoneUtils.isValid(normalized)) continue;
          phoneToName.putIfAbsent(
            normalized,
            () => contact.displayName.trim().isEmpty
                ? normalized
                : contact.displayName.trim(),
          );
        }
      }

      final phones = phoneToName.keys.toList();
      PhoneMatchResult? match;
      if (phones.isNotEmpty) {
        match = await invitationProvider.matchPhones(phones);
      }

      final matchedByPhone = <String, MatchedPhoneUser>{};
      for (final m in match?.matched ?? const <MatchedPhoneUser>[]) {
        matchedByPhone[m.phone] = m;
      }

      final rows = <_DeviceContactRow>[];
      for (final entry in phoneToName.entries) {
        final matched = matchedByPhone[entry.key];
        rows.add(
          _DeviceContactRow(
            displayName: matched?.displayName ?? entry.value,
            phone: entry.key,
            matchedUser: matched,
            isRegistered: matched != null,
          ),
        );
      }

      rows.sort((a, b) {
        if (a.isRegistered != b.isRegistered) {
          return a.isRegistered ? -1 : 1;
        }
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load contacts: $e';
      });
    }
  }

  List<_DeviceContactRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      return r.displayName.toLowerCase().contains(q) ||
          r.phone.contains(q) ||
          (r.matchedUser?.username.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _send({required bool saveAsDraft}) async {
    if (!saveAsDraft && _selectedUserIds.isEmpty) return;
    final provider = context.read<InvitationProvider>();
    final draft = widget.draft;

    final invitation = await provider.sendInvitation(
      type: draft.type,
      title: draft.title,
      message: draft.message,
      venue: draft.venue,
      address: draft.address,
      eventAt: draft.eventAt,
      themeColor: draft.themeColor,
      coverImageBase64: draft.coverImageBase64,
      recipientIds: saveAsDraft ? const [] : _selectedUserIds.toList(),
      saveAsDraft: saveAsDraft,
      showFeedback: false,
      invitationId: draft.invitationId,
      context: context,
    );

    if (invitation != null && mounted) {
      final fromExistingDraft =
          draft.invitationId != null && draft.invitationId!.isNotEmpty;
      finishInvitationFlow(
        context,
        message: saveAsDraft
            ? 'Draft saved successfully'
            : 'Invitation sent successfully',
        // contacts + customize (+ create if new)
        screensToPop: fromExistingDraft ? 2 : 3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitationProvider>();
    final filtered = _filtered;
    final registeredCount =
        filtered.where((r) => r.isRegistered).length;

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Select contacts', style: WaUi.sectionHeader),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: WaUi.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$registeredCount on BarQody · ${_selectedUserIds.length} selected',
                  style: WaUi.caption,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: WaUi.body),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadContacts,
                                child: const Text('Try again'),
                              ),
                              TextButton(
                                onPressed: openAppSettings,
                                child: const Text('Open settings'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: WaUi.divider),
                        itemBuilder: (_, i) {
                          final row = filtered[i];
                          final selected = row.isRegistered &&
                              _selectedUserIds
                                  .contains(row.matchedUser!.userId);

                          return ListTile(
                            enabled: row.isRegistered,
                            onTap: row.isRegistered
                                ? () {
                                    final id = row.matchedUser!.userId;
                                    setState(() {
                                      if (_selectedUserIds.contains(id)) {
                                        _selectedUserIds.remove(id);
                                      } else {
                                        _selectedUserIds.add(id);
                                      }
                                    });
                                  }
                                : null,
                            leading: CircleAvatar(
                              backgroundColor: row.isRegistered
                                  ? WaUi.chipBg
                                  : WaUi.navPill,
                              foregroundColor: row.isRegistered
                                  ? WaUi.accent
                                  : WaUi.secondaryText,
                              backgroundImage: row.matchedUser
                                          ?.profilePhoto.isNotEmpty ==
                                      true
                                  ? NetworkImage(row.matchedUser!.profilePhoto)
                                  : null,
                              child: row.matchedUser?.profilePhoto.isNotEmpty ==
                                      true
                                  ? null
                                  : Text(
                                      row.displayName.isNotEmpty
                                          ? row.displayName[0].toUpperCase()
                                          : '?',
                                    ),
                            ),
                            title: Text(
                              row.displayName,
                              style: WaUi.body.copyWith(
                                color: row.isRegistered
                                    ? WaUi.primaryText
                                    : WaUi.secondaryText,
                              ),
                            ),
                            subtitle: Text(
                              row.isRegistered
                                  ? '@${row.matchedUser!.username} · On BarQody'
                                  : '${row.phone} · Not on BarQody',
                              style: WaUi.caption.copyWith(
                                color: row.isRegistered
                                    ? WaUi.accent
                                    : WaUi.secondaryText,
                              ),
                            ),
                            trailing: row.isRegistered
                                ? Checkbox(
                                    value: selected,
                                    activeColor: WaUi.accent,
                                    onChanged: (_) {
                                      final id = row.matchedUser!.userId;
                                      setState(() {
                                        if (_selectedUserIds.contains(id)) {
                                          _selectedUserIds.remove(id);
                                        } else {
                                          _selectedUserIds.add(id);
                                        }
                                      });
                                    },
                                  )
                                : const Icon(Icons.lock_outline,
                                    size: 18, color: WaUi.secondaryText),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: provider.isSending
                          ? null
                          : () => _send(saveAsDraft: true),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save draft (without sending)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WaUi.primaryText,
                        side: const BorderSide(color: WaUi.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isSending || _selectedUserIds.isEmpty
                          ? null
                          : () => _send(saveAsDraft: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WaUi.buttonDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: WaUi.navPill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: provider.isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Send invitation (${_selectedUserIds.length})',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

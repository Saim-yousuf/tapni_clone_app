import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/screens/invitations/invitation_nav.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteContactsScreen extends StatefulWidget {
  final InvitationDraft draft;

  const InviteContactsScreen({super.key, required this.draft});

  @override
  State<InviteContactsScreen> createState() => _InviteContactsScreenState();
}

class _ContactRow {
  final String displayName;
  final String phone;
  final String? userId;
  final String? username;
  final String? profilePhoto;
  final bool isRegistered;
  final bool isSavedContact;

  _ContactRow({
    required this.displayName,
    required this.phone,
    this.userId,
    this.username,
    this.profilePhoto,
    this.isRegistered = false,
    this.isSavedContact = false,
  });
}

class _InviteContactsScreenState extends State<InviteContactsScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _permissionHint;
  List<_ContactRow> _savedRows = [];
  List<_ContactRow> _deviceRows = [];
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _permissionHint = null;
    });

    try {
      final invitationProvider = context.read<InvitationProvider>();
      final leadsProvider = context.read<LeadsProvider>();

      // Ensure saved contacts (leads) are loaded
      if (leadsProvider.allLeads.isEmpty) {
        await leadsProvider.fetchLeads();
      }
      final leads = List<Lead>.from(leadsProvider.allLeads);

      // Device phone contacts (optional if permission denied)
      final phoneToName = <String, String>{};
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final contacts =
            await FlutterContacts.getContacts(withProperties: true);
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
      } else if (mounted) {
        _permissionHint =
            'Phone contacts need permission. Saved contacts still shown below.';
      }

      // Match phones for device + saved (without known user id)
      final phonesToMatch = <String>{
        ...phoneToName.keys,
        for (final lead in leads)
          if (lead.contactUser == null || lead.contactUser!.isEmpty)
            PhoneUtils.normalize(lead.displayPhone),
      }.where(PhoneUtils.isValid).toList();

      PhoneMatchResult? match;
      if (phonesToMatch.isNotEmpty) {
        match = await invitationProvider.matchPhones(phonesToMatch);
      }

      final matchedByPhone = <String, MatchedPhoneUser>{};
      for (final m in match?.matched ?? const <MatchedPhoneUser>[]) {
        matchedByPhone[m.phone] = m;
      }

      // Saved contacts (app contact list / leads)
      final savedRows = <_ContactRow>[];
      final savedPhones = <String>{};
      final savedUserIds = <String>{};

      for (final lead in leads) {
        final phone = PhoneUtils.normalize(lead.displayPhone);
        final scannedId = lead.contactUser?.trim() ?? '';
        final matched = PhoneUtils.isValid(phone) ? matchedByPhone[phone] : null;
        final userId = scannedId.isNotEmpty
            ? scannedId
            : (matched?.userId ?? '');
        final isRegistered = userId.isNotEmpty;

        if (PhoneUtils.isValid(phone)) savedPhones.add(phone);
        if (isRegistered) savedUserIds.add(userId);

        savedRows.add(
          _ContactRow(
            displayName: lead.displayName.trim().isNotEmpty
                ? lead.displayName.trim()
                : (PhoneUtils.isValid(phone) ? phone : 'Contact'),
            phone: PhoneUtils.isValid(phone) ? phone : lead.displayPhone,
            userId: isRegistered ? userId : null,
            username: lead.contactUserData?.username ?? matched?.username,
            profilePhoto:
                lead.displayProfilePhoto ?? matched?.profilePhoto,
            isRegistered: isRegistered,
            isSavedContact: true,
          ),
        );
      }

      savedRows.sort((a, b) {
        if (a.isRegistered != b.isRegistered) {
          return a.isRegistered ? -1 : 1;
        }
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });

      // Device contacts — skip phones / users already in saved list
      final deviceRows = <_ContactRow>[];
      for (final entry in phoneToName.entries) {
        if (savedPhones.contains(entry.key)) continue;
        final matched = matchedByPhone[entry.key];
        if (matched != null && savedUserIds.contains(matched.userId)) {
          continue;
        }
        deviceRows.add(
          _ContactRow(
            displayName: matched?.displayName ?? entry.value,
            phone: entry.key,
            userId: matched?.userId,
            username: matched?.username,
            profilePhoto: matched?.profilePhoto,
            isRegistered: matched != null,
            isSavedContact: false,
          ),
        );
      }

      deviceRows.sort((a, b) {
        if (a.isRegistered != b.isRegistered) {
          return a.isRegistered ? -1 : 1;
        }
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _savedRows = savedRows;
        _deviceRows = deviceRows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _permissionHint = 'Failed to load contacts: $e';
      });
    }
  }

  List<_ContactRow> _filter(List<_ContactRow> rows) {
    final q = _query;
    if (q.isEmpty) return rows;
    return rows.where((r) {
      return r.displayName.toLowerCase().contains(q) ||
          r.phone.contains(q) ||
          (r.username?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _toggleSelect(_ContactRow row) {
    if (!row.isRegistered || row.userId == null) return;
    final id = row.userId!;
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  Future<void> _inviteViaSms(_ContactRow contact) async {
    final message =
        "Hey, I'm using Barqody. Download it here: ${Constants.appDomain}";

    final phone = contact.phone.trim();
    final smsUri = phone.isNotEmpty
        ? Uri(
            scheme: 'sms',
            path: phone,
            queryParameters: {'body': message},
          )
        : Uri(
            scheme: 'sms',
            queryParameters: {'body': message},
          );

    try {
      if (await canLaunchUrl(smsUri)) {
        final launched = await launchUrl(smsUri);
        if (launched) return;
      }
    } catch (_) {}

    await Share.share(message);
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
      clearCoverImage: draft.clearCoverImage,
      design: draft.design?.toJson(),
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
        screensToPop: fromExistingDraft ? 2 : 3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LeadsProvider>();
    final provider = context.watch<InvitationProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.55);

    final saved = _filter(_savedRows);
    final onBarqody = _filter(
      _deviceRows.where((r) => r.isRegistered).toList(),
    );
    final inviteList = _filter(
      _deviceRows.where((r) => !r.isRegistered).toList(),
    );
    final selectedCount = _selectedUserIds.length;
    final isEmpty =
        saved.isEmpty && onBarqody.isEmpty && inviteList.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select contact',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedCount > 0)
              Text(
                '$selectedCount selected',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
          ],
        ),
        actions: [
          if (!_loading)
            TextButton(
              onPressed:
                  provider.isSending ? null : () => _send(saveAsDraft: true),
              child: Text(
                'Draft',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search name or number',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: muted),
                prefixIcon: Icon(Icons.search, color: muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 18, color: muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? onSurface.withValues(alpha: 0.08)
                    : const Color(0xFFF0F2F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
          ),
          if (_permissionHint != null && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _permissionHint!,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _query.isEmpty
                                  ? 'No contacts found'
                                  : 'No results',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                            ),
                            if (_permissionHint != null) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadContacts,
                                child: const Text('Try again'),
                              ),
                              TextButton(
                                onPressed: openAppSettings,
                                child: const Text('Open settings'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          if (saved.isNotEmpty) ...[
                            _SectionHeader(title: 'Contacts'),
                            ...saved.map((r) => _buildTile(r, theme)),
                          ],
                          if (onBarqody.isNotEmpty) ...[
                            _SectionHeader(title: 'On Barqody'),
                            ...onBarqody.map((r) => _buildTile(r, theme)),
                          ],
                          if (inviteList.isNotEmpty) ...[
                            _SectionHeader(title: 'Invite to Barqody'),
                            ...inviteList.map((r) => _buildTile(r, theme)),
                          ],
                        ],
                      ),
          ),
          if (!_loading)
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  top: BorderSide(
                    color: onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: provider.isSending || selectedCount == 0
                      ? null
                      : () => _send(saveAsDraft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: onPrimary,
                    disabledBackgroundColor:
                        onSurface.withValues(alpha: 0.12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: provider.isSending
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: onPrimary,
                          ),
                        )
                      : Text(
                          selectedCount == 0
                              ? 'Select contacts to send'
                              : 'Send invitation ($selectedCount)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(_ContactRow row, ThemeData theme) {
    if (row.isRegistered) return _buildRegisteredTile(row, theme);
    return _buildInviteTile(row, theme);
  }

  Widget _buildRegisteredTile(_ContactRow row, ThemeData theme) {
    final selected =
        row.userId != null && _selectedUserIds.contains(row.userId);
    final photo = row.profilePhoto ?? '';
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.55);
    final subtitle = (row.username != null && row.username!.isNotEmpty)
        ? '@${row.username}'
        : (row.phone.isNotEmpty ? row.phone : 'On Barqody');

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: InkWell(
        onTap: () => _toggleSelect(row),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: onSurface.withValues(alpha: 0.08),
                    backgroundImage:
                        photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isNotEmpty
                        ? null
                        : Text(
                            row.displayName.isNotEmpty
                                ? row.displayName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                  ),
                  if (selected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primary : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? primary
                        : onSurface.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 14, color: onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteTile(_ContactRow row, ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.55);
    final photo = row.profilePhoto ?? '';

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: InkWell(
        onTap: () => _inviteViaSms(row),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: onSurface.withValues(alpha: 0.08),
                backgroundImage:
                    photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isNotEmpty
                    ? null
                    : Text(
                        row.displayName.isNotEmpty
                            ? row.displayName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.phone.isNotEmpty ? row.phone : 'Not on Barqody',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _inviteViaSms(row),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Invite',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

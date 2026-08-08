import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsSearchScreen extends StatefulWidget {
  const ContactsSearchScreen({super.key});

  @override
  State<ContactsSearchScreen> createState() => _ContactsSearchScreenState();
}

class _DeviceContact {
  final String displayName;
  final String phone;
  final MatchedPhoneUser? matchedUser;

  const _DeviceContact({
    required this.displayName,
    required this.phone,
    this.matchedUser,
  });

  bool get isOnBarqody => matchedUser != null;
}

class _ContactsSearchScreenState extends State<ContactsSearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  bool _loadingDevice = true;
  String? _deviceError;
  List<_DeviceContact> _deviceContacts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
    _loadDeviceContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  Future<void> _loadDeviceContacts() async {
    setState(() {
      _loadingDevice = true;
      _deviceError = null;
    });

    final invitationProvider = context.read<InvitationProvider>();
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _loadingDevice = false;
        _deviceError = context.l10n.contactsPermissionRequired;
      });
      return;
    }

    try {
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

      final rows = <_DeviceContact>[];
      for (final entry in phoneToName.entries) {
        final matched = matchedByPhone[entry.key];
        rows.add(
          _DeviceContact(
            displayName: matched?.displayName ?? entry.value,
            phone: entry.key,
            matchedUser: matched,
          ),
        );
      }

      rows.sort((a, b) {
        if (a.isOnBarqody != b.isOnBarqody) {
          return a.isOnBarqody ? -1 : 1;
        }
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _deviceContacts = rows;
        _loadingDevice = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDevice = false;
        _deviceError = context.l10n.failedToLoadContacts;
      });
    }
  }

  List<Lead> get _filteredLeads {
    final leads = context.read<LeadsProvider>().leads;
    final q = _query;
    if (q.isEmpty) return List<Lead>.from(leads);
    return leads.where((lead) {
      return lead.displayName.toLowerCase().contains(q) ||
          lead.displayPhone.toLowerCase().contains(q) ||
          lead.displayEmail.toLowerCase().contains(q) ||
          lead.displayCompany.toLowerCase().contains(q);
    }).toList();
  }

  List<_DeviceContact> _filteredDevice({required bool onBarqody}) {
    final leadPhones = <String>{};
    for (final lead in context.read<LeadsProvider>().leads) {
      final phone = PhoneUtils.normalize(lead.displayPhone);
      if (PhoneUtils.isValid(phone)) leadPhones.add(phone);
    }

    final me = context.read<ProfileProvider>().profile;
    final myId = me.id?.trim() ?? '';
    final myUsername = me.username?.trim().toLowerCase() ?? '';
    final myPhone = PhoneUtils.normalize(me.phone);

    final q = _query;
    return _deviceContacts.where((c) {
      if (c.isOnBarqody != onBarqody) return false;
      if (leadPhones.contains(c.phone)) return false;

      // Don't list the signed-in user as a contact match.
      if (myPhone.isNotEmpty && c.phone == myPhone) return false;
      final matched = c.matchedUser;
      if (matched != null) {
        if (myId.isNotEmpty && matched.userId == myId) return false;
        if (myUsername.isNotEmpty &&
            matched.username.trim().toLowerCase() == myUsername) {
          return false;
        }
      }

      if (q.isEmpty) return true;
      return c.displayName.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          (c.matchedUser?.username.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _inviteContact(_DeviceContact contact) async {
    final profile = context.read<ProfileProvider>().profile;
    final username = profile.username?.trim() ?? '';
    final link = username.isNotEmpty
        ? '${Constants.appDomain}/$username'
        : Constants.appDomain;
    final message = context.l10n.heyJoinMeOnBarqody(contact.displayName, link);

    final smsUri = Uri(
      scheme: 'sms',
      path: contact.phone,
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

  void _openLead(Lead lead) {
    if (lead.contactUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(user: lead.contactUser),
        ),
      );
    }
  }

  void _openMatched(MatchedPhoneUser user) {
    if (user.username.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(username: user.username),
        ),
      );
    } else if (user.userId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(user: user.userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep leads list reactive for search filtering.
    context.watch<LeadsProvider>();
    final leads = _filteredLeads;
    final onBarqody = _filteredDevice(onBarqody: true);
    final inviteList = _filteredDevice(onBarqody: false);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: WaUi.primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        autofocus: true,
                        style: WaUi.body.copyWith(fontSize: 16, height: 1.2),
                        cursorColor: WaUi.accent,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: WaUi.searchBg,
                          hintText: context.l10n.searchNameOrNumber,
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF667781),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 6),
                            child: Icon(
                              Icons.search,
                              size: 22,
                              color: Color(0xFF667781),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 42,
                            minHeight: 44,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  color: const Color(0xFF667781),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocus.requestFocus();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingDevice
                  ? const Center(child: CircularProgressIndicator())
                  : _deviceError != null &&
                          leads.isEmpty &&
                          onBarqody.isEmpty &&
                          inviteList.isEmpty
                      ? _PermissionError(
                          message: _deviceError!,
                          onRetry: _loadDeviceContacts,
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            if (leads.isNotEmpty) ...[
                              _SectionHeader(title: context.l10n.contacts),
                              ...leads.map(_buildLeadTile),
                            ],
                            if (onBarqody.isNotEmpty) ...[
                              _SectionHeader(title: context.l10n.contactsOnBarqody),
                              ...onBarqody.map(_buildOnBarqodyTile),
                            ],
                            if (inviteList.isNotEmpty) ...[
                              _SectionHeader(title: context.l10n.inviteToBarqody),
                              ...inviteList.map(_buildInviteTile),
                            ],
                            if (!_loadingDevice &&
                                leads.isEmpty &&
                                onBarqody.isEmpty &&
                                inviteList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 40,
                                      color: WaUi.secondaryText
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _query.isEmpty
                                          ? context.l10n.noContactsFound
                                          : context.l10n.noResultsForQuery(_query),
                                      style: WaUi.title,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_deviceError != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _deviceError!,
                                        style: WaUi.caption,
                                        textAlign: TextAlign.center,
                                      ),
                                      TextButton(
                                        onPressed: _loadDeviceContacts,
                                        child: Text(context.l10n.tryAgain),
                                      ),
                                    ],
                                  ],
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

  Widget _buildLeadTile(Lead lead) {
    final name = lead.displayName;
    final photo = lead.displayProfilePhoto;
    final preview = lead.displayPhone.isNotEmpty
        ? lead.displayPhone
        : (lead.displayCompany.isNotEmpty
            ? lead.displayCompany
            : (lead.isScannedContact
                ? context.l10n.onBarqody
                : context.l10n.savedContact));

    return WaChatListTile(
      name: name,
      preview: preview,
      date: '',
      imageUrl: photo,
      initial: name,
      avatarColor: waAvatarColorFor(name),
      showDivider: false,
      onTap: () => _openLead(lead),
    );
  }

  Widget _buildOnBarqodyTile(_DeviceContact contact) {
    final user = contact.matchedUser!;
    final preview = user.username.isNotEmpty
        ? '@${user.username} · ${context.l10n.onBarqody}'
        : context.l10n.onBarqody;

    return WaChatListTile(
      name: contact.displayName,
      preview: preview,
      date: '',
      imageUrl: user.profilePhoto.isNotEmpty ? user.profilePhoto : null,
      initial: contact.displayName,
      avatarColor: waAvatarColorFor(contact.displayName),
      showDivider: false,
      onTap: () => _openMatched(user),
    );
  }

  Widget _buildInviteTile(_DeviceContact contact) {
    return Material(
      color: WaUi.toolsScaffold,
      child: InkWell(
        onTap: () => _inviteContact(contact),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: waAvatarColorFor(contact.displayName),
                child: Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: WaUi.avatarInitial,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: WaUi.chatName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contact.phone,
                      style: WaUi.chatPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _inviteContact(contact),
                style: TextButton.styleFrom(
                  foregroundColor: WaUi.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.invite,
                  style: WaUi.bodyMedium.copyWith(
                    color: WaUi.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: WaUi.bodyMedium.copyWith(
          color: WaUi.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PermissionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PermissionError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: WaUi.body),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: WaUi.buttonDark,
              ),
              child: Text(context.l10n.tryAgain),
            ),
            TextButton(
              onPressed: openAppSettings,
              child: Text(context.l10n.openSettings),
            ),
          ],
        ),
      ),
    );
  }
}

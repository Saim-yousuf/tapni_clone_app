import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/invitations/invite_contacts_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';

class InvitationDetailScreen extends StatefulWidget {
  final String invitationId;
  final EventInvitation? invitation;

  const InvitationDetailScreen({
    super.key,
    required this.invitationId,
    this.invitation,
  });

  @override
  State<InvitationDetailScreen> createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends State<InvitationDetailScreen> {
  final GlobalKey _cardKey = GlobalKey();
  EventInvitation? _invitation;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _invitation = widget.invitation;
    if (_invitation != null) {
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(silent: true));
    } else {
      _load();
    }
  }

  Future<void> _load({bool silent = false}) async {
    final id = widget.invitationId.trim();
    if (id.isEmpty) {
      if (!silent) {
        setState(() {
          _loading = false;
          _error = context.l10n.invitationNotFound;
        });
      }
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final inv = await context.read<InvitationProvider>().fetchById(id);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (inv != null) {
        _invitation = inv;
        _error = null;
      } else if (_invitation == null) {
        _error = context.l10n.invitationNotFound;
      }
    });
  }

  bool _isRecipient(EventInvitation inv, String userId) {
    if (userId.isEmpty) return false;
    return inv.recipients.any((r) => r.user.id == userId);
  }

  bool _isSender(EventInvitation inv, String userId) {
    return userId.isNotEmpty && inv.sender.id == userId;
  }

  Future<void> _inviteMore() async {
    final inv = _invitation;
    if (inv == null || inv.status != 'sent') return;

    final draft = InvitationDraft.fromInvitation(inv);
    final alreadyInvited = inv.recipients
        .map((r) => r.user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final updated = await Navigator.of(context).push<EventInvitation>(
      MaterialPageRoute(
        builder: (_) => InviteContactsScreen(
          draft: draft,
          addMoreMode: true,
          alreadyInvitedUserIds: alreadyInvited,
        ),
      ),
    );

    if (!mounted) return;
    if (updated != null) {
      setState(() => _invitation = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invitationSentSuccessfully),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      await _load(silent: true);
    }
  }

  Future<void> _downloadCard() async {
    if (_invitation == null || _downloading) return;

    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _DownloadFormatSheet(),
    );

    if (format == null || !mounted) return;

    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    final fileName = 'invitation_${_invitation!.title}';

    try {
      final ok = format == 'jpg'
          ? await BusinessCardExportHelper.saveJpg(_cardKey, fileName: fileName)
          : await BusinessCardExportHelper.savePng(_cardKey, fileName: fileName);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? context.l10n.cardSavedToGallery
                : context.l10n.couldNotSaveCheckGalleryPermission,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? null : Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.failedToDownloadInvitationCard),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _openSender(InvitationUserSummary sender) {
    if (sender.username.trim().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(username: sender.username.trim()),
        ),
      );
      return;
    }
    if (sender.id.trim().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(user: sender.id.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final userId = profile.id ?? '';
    final inv = _invitation;
    final isGuest =
        inv != null && _isRecipient(inv, userId) && !_isSender(inv, userId);
    final canInviteMore =
        inv != null && _isSender(inv, userId) && inv.status == 'sent';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: context.l10n.invitation,
              trailing: inv == null
                  ? const SizedBox(width: 40)
                  : Tooltip(
                      message: context.l10n.downloadCard,
                      child: CircleAssetButton(
                        asset: 'assets/images/png/download-icon.png',
                        iconSize: 18,
                        onTap: _downloading ? null : _downloadCard,
                        child: _downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : null,
                      ),
                    ),
            ),
            Expanded(
              child: _loading && inv == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : _error != null && inv == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error ?? context.l10n.notFound,
                                  style: WaUi.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _load(),
                                  child: Text(
                                    context.l10n.retry,
                                    style: WaUi.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: Colors.black,
                          backgroundColor: Colors.white,
                          onRefresh: () => _load(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                            children: [
                              _InvitationHeroCard(
                                cardKey: _cardKey,
                                invitation: inv!,
                                guestName: isGuest
                                    ? (profile.name.isNotEmpty
                                        ? profile.name
                                        : (profile.username ?? ''))
                                    : null,
                                guestEmail: isGuest && profile.email.isNotEmpty
                                    ? profile.email
                                    : null,
                              ),
                              const SizedBox(height: 22),
                              _SendBySection(
                                sender: inv.sender,
                                onTap: () => _openSender(inv.sender),
                              ),
                              if (!isGuest && inv.recipients.isNotEmpty) ...[
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Text(
                                      context.l10n
                                          .sentToCount(inv.recipients.length),
                                      style: WaUi.body.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (canInviteMore)
                                      GestureDetector(
                                        onTap: _inviteMore,
                                        child: Text(
                                          context.l10n.inviteMorePeople,
                                          style: WaUi.body.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.usersWhoReceivedInvitation,
                                  style: WaUi.body.copyWith(
                                    fontSize: 13,
                                    color: BarqodyChrome.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ...inv.recipients.map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _RecipientTile(recipient: r),
                                  ),
                                ),
                              ],
                              if (!isGuest &&
                                  inv.status == 'sent' &&
                                  inv.recipients.isEmpty) ...[
                                const SizedBox(height: 28),
                                Text(
                                  context.l10n.sentTo,
                                  style: WaUi.body.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BarqodyChrome.fieldFill,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.group_outlined,
                                        size: 32,
                                        color: BarqodyChrome.secondaryText
                                            .withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        context.l10n.noRecipientsOnInvitation,
                                        textAlign: TextAlign.center,
                                        style: WaUi.body.copyWith(
                                          fontSize: 13,
                                          color: BarqodyChrome.secondaryText,
                                        ),
                                      ),
                                      if (canInviteMore) ...[
                                        const SizedBox(height: 14),
                                        TextButton(
                                          onPressed: _inviteMore,
                                          child: Text(
                                            context.l10n.inviteMorePeople,
                                            style: WaUi.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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

class _InvitationHeroCard extends StatelessWidget {
  final GlobalKey cardKey;
  final EventInvitation invitation;
  final String? guestName;
  final String? guestEmail;

  const _InvitationHeroCard({
    required this.cardKey,
    required this.invitation,
    this.guestName,
    this.guestEmail,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: RepaintBoundary(
        key: cardKey,
        child: invitation.hasDesign && invitation.design != null
            ? InvitationDesignRenderer(
                design: invitation.design!,
                invitationId: invitation.id,
                shadows: const [],
              )
            : InvitationCardPreview.fromInvitation(
                invitation,
                guestName: guestName,
                guestEmail: guestEmail,
              ),
      ),
    );
  }
}

class _SendBySection extends StatelessWidget {
  final InvitationUserSummary sender;
  final VoidCallback onTap;

  const _SendBySection({
    required this.sender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = sender.businessName.trim().isNotEmpty
        ? sender.businessName.trim()
        : sender.displayName;
    final subtitle = sender.businessName.trim().isNotEmpty &&
            sender.name.trim().isNotEmpty &&
            sender.businessName.trim() != sender.name.trim()
        ? sender.name.trim()
        : (sender.username.trim().isNotEmpty
            ? '@${sender.username.trim()}'
            : (sender.businessName.trim().isNotEmpty
                ? sender.displayName
                : ''));
    final showBadge = sender.businessName.trim().isNotEmpty;
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send by',
          style: WaUi.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: BarqodyChrome.circleBtn,
                    backgroundImage: sender.profilePhoto.isNotEmpty
                        ? NetworkImage(sender.profilePhoto)
                        : null,
                    child: sender.profilePhoto.isEmpty
                        ? Text(
                            initial,
                            style: WaUi.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WaUi.body.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (showBadge) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: BarqodyChrome.star,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'assets/images/png/check-icon.png',
                                  width: 9,
                                  height: 9,
                                  color: Colors.white,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontSize: 13,
                              color: BarqodyChrome.secondaryText,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
      ],
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final InvitationRecipient recipient;

  const _RecipientTile({required this.recipient});

  @override
  Widget build(BuildContext context) {
    final name = recipient.name.isNotEmpty
        ? recipient.name
        : recipient.user.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              backgroundImage: recipient.user.profilePhoto.isNotEmpty
                  ? NetworkImage(recipient.user.profilePhoto)
                  : null,
              child: recipient.user.profilePhoto.isEmpty
                  ? Text(
                      initial,
                      style: WaUi.body.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (recipient.user.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${recipient.user.username}',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                  if (recipient.phone.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      recipient.phone,
                      style: WaUi.body.copyWith(
                        fontSize: 12,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(WaUi.radiusPill),
                  ),
                  child: Text(
                    context.l10n.sent,
                    style: WaUi.body.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (recipient.deliveredAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(
                      recipient.deliveredAt!.toLocal(),
                    ),
                    style: WaUi.body.copyWith(
                      fontSize: 11,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadFormatSheet extends StatelessWidget {
  const _DownloadFormatSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: context.l10n.downloadInvitationCard,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: BarqodyChrome.circleBtn,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/png/download-icon.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.download_rounded,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.downloadCardPngJpg,
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(
                  fontSize: 13,
                  color: BarqodyChrome.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DownloadFormatCard(
                      format: 'PNG',
                      subtitle: context.l10n.saveAsPng,
                      onTap: () => Navigator.pop(context, 'png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DownloadFormatCard(
                      format: 'JPG',
                      subtitle: context.l10n.saveAsJpg,
                      onTap: () => Navigator.pop(context, 'jpg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: WaUi.primaryButtonHeight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.l10n.cancel,
                    style: WaUi.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: BarqodyChrome.secondaryText,
                    ),
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

class _DownloadFormatCard extends StatelessWidget {
  final String format;
  final String subtitle;
  final VoidCallback onTap;

  const _DownloadFormatCard({
    required this.format,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BarqodyChrome.divider),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/png/download-icon.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                format,
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.body.copyWith(
                  fontSize: 12,
                  color: BarqodyChrome.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

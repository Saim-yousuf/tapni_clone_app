import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/invitations/invite_contacts_screen.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
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
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        title: Text(context.l10n.invitation),
        actions: [
          if (canInviteMore)
            IconButton(
              tooltip: context.l10n.inviteMorePeople,
              onPressed: _inviteMore,
              icon: const Icon(Icons.person_add_alt_1_rounded)),
          if (inv != null)
            IconButton(
              tooltip: context.l10n.downloadCard,
              onPressed: _downloading ? null : _downloadCard,
              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded)),
        ],
      ),
      body: _loading && inv == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _error != null && inv == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: WaUi.navPill,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: WaUi.secondaryText.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error ?? context.l10n.notFound,
                          style: WaUi.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _load(),
                          child: Text(context.l10n.retry, style: WaUi.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: WaUi.accent,
                  backgroundColor: WaUi.toolsScaffold,
                  onRefresh: () => _load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      _CardPreviewFrame(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: inv!.hasDesign && inv.design != null
                              ? InvitationDesignRenderer(
                                  design: inv.design!,
                                  invitationId: inv.id,
                                  shadows: const [],
                                )
                              : InvitationCardPreview.fromInvitation(
                                  inv,
                                  guestName: isGuest
                                      ? (profile.name.isNotEmpty
                                          ? profile.name
                                          : (profile.username ?? ''))
                                      : null,
                                  guestEmail:
                                      isGuest && profile.email.isNotEmpty
                                          ? profile.email
                                          : null,
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EventMetaChips(invitation: inv),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          if (canInviteMore) ...[
                            Expanded(
                              child: _PrimaryActionButton(
                                onPressed: _inviteMore,
                                icon: Icons.person_add_alt_1_rounded,
                                label: context.l10n.inviteMorePeople,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: _SecondaryActionButton(
                              onPressed: _downloading ? null : _downloadCard,
                              icon: Icons.download_rounded,
                              label: _downloading
                                  ? context.l10n.savingEllipsis
                                  : context.l10n.downloadCard,
                              loading: _downloading,
                            ),
                          ),
                        ],
                      ),
                      if (!isGuest && inv.recipients.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Text(
                              context.l10n.sentToCount(inv.recipients.length),
                              style: WaUi.sectionHeader,
                            ),
                            const Spacer(),
                            if (canInviteMore)
                              GestureDetector(
                                onTap: _inviteMore,
                                child: Text(
                                  context.l10n.inviteMorePeople,
                                  style: WaUi.bodyMedium.copyWith(
                                    color: WaUi.accent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.usersWhoReceivedInvitation,
                          style: WaUi.caption,
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
                        Text(context.l10n.sentTo, style: WaUi.sectionHeader),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7F8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 32,
                                color: WaUi.secondaryText.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.l10n.noRecipientsOnInvitation,
                                textAlign: TextAlign.center,
                                style: WaUi.caption,
                              ),
                              if (canInviteMore) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _inviteMore,
                                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                                  label: Text(
                                    context.l10n.inviteMorePeople,
                                    style: WaUi.bodyMedium,
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
    );
  }
}

class _CardPreviewFrame extends StatelessWidget {
  final Widget child;

  const _CardPreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

class _EventMetaChips extends StatelessWidget {
  final EventInvitation invitation;

  const _EventMetaChips({required this.invitation});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _MetaChip(
        icon: Icons.celebration_outlined,
        label: invitation.typeDisplay,
      ),
    ];

    if (invitation.eventAt != null) {
      chips.add(
        _MetaChip(
          icon: Icons.event_outlined,
          label: DateFormat('MMM d, yyyy').format(invitation.eventAt!.toLocal()),
        ),
      );
    }

    if (invitation.venue.trim().isNotEmpty) {
      chips.add(
        _MetaChip(
          icon: Icons.place_outlined,
          label: invitation.venue.trim(),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(WaUi.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WaUi.secondaryText),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.45,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.label.copyWith(
                color: WaUi.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _PrimaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WaUi.primaryButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: WaUi.buttonDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaUi.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: WaUi.promoButton.copyWith(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool loading;

  const _SecondaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WaUi.primaryButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: WaUi.primaryText,
          backgroundColor: const Color(0xFFF6F7F8),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaUi.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: WaUi.bodyMedium.copyWith(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
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
      color: const Color(0xFFF6F7F8),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: WaUi.chipBg,
              backgroundImage: recipient.user.profilePhoto.isNotEmpty
                  ? NetworkImage(recipient.user.profilePhoto)
                  : null,
              child: recipient.user.profilePhoto.isEmpty
                  ? Text(
                      initial,
                      style: WaUi.bodyMedium.copyWith(
                        color: WaUi.navGreen,
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
                  Text(name, style: WaUi.bodyMedium),
                  if (recipient.user.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${recipient.user.username}',
                      style: WaUi.caption.copyWith(fontSize: 13),
                    ),
                  ],
                  if (recipient.phone.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      recipient.phone,
                      style: WaUi.caption.copyWith(fontSize: 12),
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
                    color: WaUi.chipBg,
                    borderRadius: BorderRadius.circular(WaUi.radiusPill),
                  ),
                  child: Text(
                    context.l10n.sent,
                    style: WaUi.label.copyWith(
                      color: WaUi.navGreen,
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
                    style: WaUi.label.copyWith(fontSize: 11),
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
        color: WaUi.toolsScaffold,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WaUi.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  size: 28,
                  color: WaUi.buttonDark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.downloadInvitationCard,
                textAlign: TextAlign.center,
                style: WaUi.sectionHeader,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.downloadCardPngJpg,
                textAlign: TextAlign.center,
                style: WaUi.caption,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DownloadFormatCard(
                      format: 'PNG',
                      subtitle: context.l10n.saveAsPng,
                      icon: Icons.image_outlined,
                      accent: WaUi.navGreen,
                      onTap: () => Navigator.pop(context, 'png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DownloadFormatCard(
                      format: 'JPG',
                      subtitle: context.l10n.saveAsJpg,
                      icon: Icons.photo_outlined,
                      accent: WaUi.buttonDark,
                      onTap: () => Navigator.pop(context, 'jpg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: WaUi.secondaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    ),
                  ),
                  child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
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
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _DownloadFormatCard({
    required this.format,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F7F8),
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
                  color: WaUi.toolsScaffold,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WaUi.divider),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                format,
                style: WaUi.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

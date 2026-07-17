import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';

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
      // Refresh in background if we already have a cached invitation.
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
          _error = 'Invitation not found';
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
        _error = 'Invitation not found';
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

  Future<void> _downloadCard() async {
    if (_invitation == null || _downloading) return;

    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Download invitation card', style: WaUi.bodyMedium),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Save as PNG'),
                onTap: () => Navigator.pop(ctx, 'png'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('Save as JPG'),
                onTap: () => Navigator.pop(ctx, 'jpg'),
              ),
            ],
          ),
        ),
      ),
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
                ? 'Invitation card saved to gallery (${format.toUpperCase()})'
                : 'Could not save card. Check gallery permission.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? null : Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to download invitation card'),
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

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Invitation', style: WaUi.sectionHeader),
        actions: [
          if (inv != null)
            IconButton(
              tooltip: 'Download card',
              onPressed: _downloading ? null : _downloadCard,
              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
            ),
        ],
      ),
      body: _loading && inv == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && inv == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error ?? 'Not found', style: WaUi.body),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      RepaintBoundary(
                        key: _cardKey,
                        child: InvitationCardPreview.fromInvitation(
                          inv!,
                          guestName: isGuest
                              ? (profile.name.isNotEmpty
                                  ? profile.name
                                  : (profile.username ?? ''))
                              : null,
                          guestEmail: isGuest && profile.email.isNotEmpty
                              ? profile.email
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _downloading ? null : _downloadCard,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            _downloading
                                ? 'Saving...'
                                : 'Download card (PNG / JPG)',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WaUi.primaryText,
                            side: const BorderSide(color: WaUi.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // Sender (or anyone who isn't only a guest) sees who it was sent to
                      if (!isGuest && inv.recipients.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Sent to (${inv.recipients.length})',
                          style: WaUi.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Users who already received this invitation',
                          style: WaUi.caption,
                        ),
                        const SizedBox(height: 12),
                        ...inv.recipients.map((r) {
                          final name = r.name.isNotEmpty
                              ? r.name
                              : r.user.displayName;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: WaUi.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: WaUi.divider),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: WaUi.chipBg,
                                    backgroundImage:
                                        r.user.profilePhoto.isNotEmpty
                                            ? NetworkImage(r.user.profilePhoto)
                                            : null,
                                    child: r.user.profilePhoto.isEmpty
                                        ? Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
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
                                        Text(name, style: WaUi.bodyMedium),
                                        if (r.user.username.isNotEmpty)
                                          Text(
                                            '@${r.user.username}',
                                            style: WaUi.caption,
                                          ),
                                        if (r.phone.isNotEmpty)
                                          Text(r.phone, style: WaUi.caption),
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
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Sent',
                                          style: WaUi.caption.copyWith(
                                            color: WaUi.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (r.deliveredAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM d, h:mm a').format(
                                            r.deliveredAt!.toLocal(),
                                          ),
                                          style: WaUi.caption.copyWith(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (!isGuest &&
                          inv.status == 'sent' &&
                          inv.recipients.isEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Sent to', style: WaUi.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          'No recipients on this invitation.',
                          style: WaUi.caption,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

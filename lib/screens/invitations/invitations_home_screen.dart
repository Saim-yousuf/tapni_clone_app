import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/invitations/customize_invitation_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_detail_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_design_editor_screen.dart';
import 'package:tapni_app/screens/invitations/template_gallery_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';

class InvitationsHomeScreen extends StatefulWidget {
  const InvitationsHomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<InvitationsHomeScreen> createState() => _InvitationsHomeScreenState();
}

class _InvitationsHomeScreenState extends State<InvitationsHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvitationProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openMyCard(EventInvitation inv) {
    if (inv.status == 'draft') {
      final draft = InvitationDraft.fromInvitation(inv);
      if (inv.hasDesign && inv.design != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InvitationDesignEditorScreen(
              design: inv.design!,
              existingDraft: draft,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomizeInvitationScreen(
              draft: draft,
              fromDraftList: true,
            ),
          ),
        );
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationDetailScreen(
          invitationId: inv.id,
          invitation: inv,
        ),
      ),
    );
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TemplateGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitationProvider>();
    final myCards = provider.myCards;
    final receivedCount = provider.received.length;
    final sentCount = provider.sent.length;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        title: Text(context.l10n.invitations),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGallery,
        backgroundColor: WaUi.buttonDark,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusMd),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(context.l10n.create, style: WaUi.promoButton),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MyCardsSection(
            myCards: myCards,
            isLoading: provider.isLoading && myCards.isEmpty,
            onCreate: _openGallery,
            onOpen: _openMyCard,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, _) {
                return _ReceivedSentTabs(
                  position: _tabController.animation!.value,
                  receivedLabel: context.l10n.received,
                  sentLabel: context.l10n.sent,
                  receivedCount: receivedCount,
                  sentCount: sentCount,
                  onChanged: (i) {
                    if (_tabController.index == i &&
                        !_tabController.indexIsChanging) {
                      return;
                    }
                    HapticFeedback.selectionClick();
                    _tabController.animateTo(i);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InvitationList(
                  items: provider.received,
                  isLoading: provider.isLoading,
                  emptyTitle: context.l10n.noInvitationsYet,
                  emptySubtitle:
                      context.l10n.whenSomeoneInvitesYouItWillShowUpHere,
                  emptyIcon: Icons.inbox_outlined,
                  onRefresh: () => provider.fetchAll(),
                ),
                _InvitationList(
                  items: provider.sent,
                  isLoading: provider.isLoading,
                  emptyTitle: context.l10n.noSentInvitations,
                  emptySubtitle:
                      context.l10n.createInvitationSaveDraftOrSendHint,
                  emptyIcon: Icons.send_outlined,
                  onRefresh: () => provider.fetchAll(),
                  showRecipientCount: true,
                  onOpen: _openMyCard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyCardsSection extends StatelessWidget {
  final List<EventInvitation> myCards;
  final bool isLoading;
  final VoidCallback onCreate;
  final void Function(EventInvitation) onOpen;

  const _MyCardsSection({
    required this.myCards,
    required this.isLoading,
    required this.onCreate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: Row(
            children: [
              Text(context.l10n.myCards, style: WaUi.sectionHeader),
              const SizedBox(width: 8),
              if (myCards.isNotEmpty)
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WaUi.buttonDark,
                    borderRadius: BorderRadius.circular(WaUi.radiusPill),
                  ),
                  child: Text(
                    '${myCards.length}',
                    style: WaUi.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1,
                    ),
                  ),
                ),
              const Spacer(),
              if (myCards.isNotEmpty)
                GestureDetector(
                  onTap: onCreate,
                  child: Text(
                    context.l10n.create,
                    style: WaUi.bodyMedium.copyWith(color: WaUi.accent),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 196,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else if (myCards.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _EmptyMyCards(onCreate: onCreate),
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              itemCount: myCards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final inv = myCards[i];
                return _MyCardTile(
                  invitation: inv,
                  onTap: () => onOpen(inv),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ReceivedSentTabs extends StatelessWidget {
  final double position;
  final String receivedLabel;
  final String sentLabel;
  final int receivedCount;
  final int sentCount;
  final ValueChanged<int> onChanged;

  const _ReceivedSentTabs({
    required this.position,
    required this.receivedLabel,
    required this.sentLabel,
    required this.receivedCount,
    required this.sentCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = position.clamp(0.0, 1.0);
    final selected = t < 0.5 ? 0 : 1;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  t,
                )!,
                child: SizedBox(
                  width: tabWidth,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SegTab(
                      selected: selected == 0,
                      icon: Icons.inbox_rounded,
                      label: receivedLabel,
                      count: receivedCount,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  Expanded(
                    child: _SegTab(
                      selected: selected == 1,
                      icon: Icons.send_rounded,
                      label: sentLabel,
                      count: sentCount,
                      onTap: () => onChanged(1),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _SegTab({
    required this.selected,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            letterSpacing: selected ? -0.2 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMyCards extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyMyCards({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.navPill.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(WaUi.radiusLg),
      child: InkWell(
        onTap: onCreate,
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: WaUi.toolsScaffold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: WaUi.buttonDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.noCardsYet, style: WaUi.bodyMedium),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.designAnInvitationItWillAppearHere,
                      style: WaUi.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: WaUi.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyCardTile extends StatelessWidget {
  final EventInvitation invitation;
  final VoidCallback onTap;

  const _MyCardTile({required this.invitation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDraft = invitation.status == 'draft';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _InvitationThumb(invitation: invitation),
                      ),
                    ),
                  ),
                  if (isDraft)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: WaUi.buttonDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.l10n.draft,
                          style: WaUi.label.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              invitation.title.isEmpty
                  ? context.l10n.untitled
                  : invitation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.bodyMedium.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 1),
            Text(
              invitation.typeDisplay,
              style: WaUi.label.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationThumb extends StatelessWidget {
  final EventInvitation invitation;

  const _InvitationThumb({required this.invitation});

  @override
  Widget build(BuildContext context) {
    if (invitation.hasDesign && invitation.design != null) {
      return InvitationDesignRenderer(
        design: invitation.design!,
        invitationId: invitation.id,
        shadows: const [],
        border: Border.all(color: WaUi.divider),
      );
    }

    return ColoredBox(
      color: invitationColorFromHex(invitation.themeColor).withValues(alpha: 0.08),
      child: AspectRatio(
        aspectRatio: 0.7,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 280,
            child: InvitationCardPreview(
              type: invitation.type,
              title: invitation.title,
              message: invitation.message,
              venue: invitation.venue,
              address: invitation.address,
              eventAt: invitation.eventAt,
              themeColor: invitation.themeColor,
              coverImageUrl:
                  invitation.coverImage.isEmpty ? null : invitation.coverImage,
              invitationId: invitation.id,
              isPreview: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitationList extends StatelessWidget {
  final List<EventInvitation> items;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;
  final bool showRecipientCount;
  final void Function(EventInvitation)? onOpen;

  const _InvitationList({
    required this.items,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.onRefresh,
    this.showRecipientCount = false,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    return RefreshIndicator(
      color: WaUi.accent,
      backgroundColor: WaUi.toolsScaffold,
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 36),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: WaUi.navPill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          emptyIcon,
                          size: 34,
                          color: WaUi.secondaryText.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        emptyTitle,
                        textAlign: TextAlign.center,
                        style: WaUi.sectionHeader,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: WaUi.caption,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final inv = items[i];
                return _InvitationRow(
                  invitation: inv,
                  showRecipientCount: showRecipientCount,
                  onTap: () {
                    if (onOpen != null) {
                      onOpen!(inv);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvitationDetailScreen(
                          invitationId: inv.id,
                          invitation: inv,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  final EventInvitation invitation;
  final bool showRecipientCount;
  final VoidCallback onTap;

  const _InvitationRow({
    required this.invitation,
    required this.showRecipientCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = showRecipientCount
        ? invitation.status == 'draft'
            ? '${invitation.typeDisplay} · ${context.l10n.draft}'
            : _sentToLabel(context, invitation)
        : '${invitation.sender.displayName} · ${invitation.typeDisplay}';

    final dateLabel = invitation.eventAt != null
        ? DateFormat('MMM d, yyyy').format(invitation.eventAt!.toLocal())
        : null;

    return Material(
      color: const Color(0xFFF6F7F8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 72,
                  child: _InvitationThumb(invitation: invitation),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.title.isEmpty
                          ? context.l10n.untitled
                          : invitation.title,
                      style: WaUi.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: WaUi.caption.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateLabel != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 14,
                            color: WaUi.secondaryText.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateLabel,
                            style: WaUi.label.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: WaUi.secondaryText.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sentToLabel(BuildContext context, EventInvitation inv) {
    if (inv.recipients.isEmpty) {
      return '${inv.typeDisplay} · No recipients';
    }
    final names = inv.recipients
        .map((r) => r.name.isNotEmpty ? r.name : r.user.displayName)
        .where((n) => n.trim().isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return '${inv.typeDisplay} · ${inv.recipients.length} sent';
    }
    if (names.length == 1) {
      return '${inv.typeDisplay} · Sent to ${names.first}';
    }
    if (names.length == 2) {
      return '${inv.typeDisplay} · Sent to ${names[0]}, ${names[1]}';
    }
    return '${inv.typeDisplay} · Sent to ${names[0]}, ${names[1]} +${names.length - 2}';
  }
}

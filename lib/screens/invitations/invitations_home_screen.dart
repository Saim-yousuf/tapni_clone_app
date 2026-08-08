import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitationProvider>();
    final myCards = provider.myCards;

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(context.l10n.invitations, style: WaUi.sectionHeader),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TemplateGalleryScreen()),
          );
        },
        backgroundColor: WaUi.buttonDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.create),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── My cards (created by me) ─────────────────────────────
          Container(
            color: WaUi.surface,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(context.l10n.myCards, style: WaUi.sectionHeader),
                      const Spacer(),
                      if (myCards.isNotEmpty)
                        Text(
                          '${myCards.length}',
                          style: WaUi.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (provider.isLoading && myCards.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (myCards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyMyCards(
                      onCreate: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TemplateGalleryScreen(),
                          ),
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: myCards.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final inv = myCards[i];
                        return _MyCardTile(
                          invitation: inv,
                          onTap: () => _openMyCard(inv),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── Received / Sent tabs ─────────────────────────────────
          Material(
            color: WaUi.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: WaUi.primaryText,
              unselectedLabelColor: WaUi.secondaryText,
              indicatorColor: WaUi.accent,
              tabs: [
                Tab(text: context.l10n.received),
                Tab(text: context.l10n.sent),
              ],
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
                  onRefresh: () => provider.fetchAll(),
                ),
                _InvitationList(
                  items: provider.sent,
                  isLoading: provider.isLoading,
                  emptyTitle: context.l10n.noSentInvitations,
                  emptySubtitle:
                      context.l10n.createInvitationSaveDraftOrSendHint,
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

class _EmptyMyCards extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyMyCards({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: WaUi.scaffold,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaUi.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.style_outlined, size: 36, color: WaUi.promoIconFg),
          const SizedBox(height: 10),
          Text(context.l10n.noCardsYet, style: WaUi.bodyMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.designAnInvitationItWillAppearHere,
            textAlign: TextAlign.center,
            style: WaUi.caption,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.l10n.createCard),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: invitation.hasDesign && invitation.design != null
                    ? InvitationDesignRenderer(
                        design: invitation.design!,
                        invitationId: invitation.id,
                        shadows: const [],
                        border: Border.all(color: WaUi.divider),
                      )
                    : AspectRatio(
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
                              coverImageUrl: invitation.coverImage.isEmpty
                                  ? null
                                  : invitation.coverImage,
                              invitationId: invitation.id,
                              isPreview: true,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              invitation.title.isEmpty
                  ? context.l10n.untitled
                  : invitation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: WaUi.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              invitation.status == 'draft'
                  ? context.l10n.draft
                  : invitation.typeDisplay,
              style: TextStyle(
                fontSize: 11,
                color: invitation.status == 'draft'
                    ? WaUi.accent
                    : WaUi.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
  final Future<void> Function() onRefresh;
  final bool showRecipientCount;
  final void Function(EventInvitation)? onOpen;

  const _InvitationList({
    required this.items,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    this.showRecipientCount = false,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                Icon(Icons.mail_outline, size: 48, color: WaUi.promoIconFg),
                const SizedBox(height: 16),
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
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final inv = items[i];
                final color = invitationColorFromHex(inv.themeColor);
                return Material(
                  color: WaUi.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.celebration_outlined,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inv.title,
                                        style: WaUi.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (inv.status == 'draft') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: WaUi.navPill,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          context.l10n.draft,
                                          style: WaUi.caption.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  showRecipientCount
                                      ? inv.status == 'draft'
                                          ? '${inv.typeDisplay} · ${context.l10n.draft}'
                                          : _sentToLabel(inv)
                                      : '${inv.sender.displayName} · ${inv.typeDisplay}',
                                  style: WaUi.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: WaUi.secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _sentToLabel(EventInvitation inv) {
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

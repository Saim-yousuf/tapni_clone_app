import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/invitations/customize_invitation_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_detail_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_design_editor_screen.dart';
import 'package:tapni_app/screens/invitations/template_gallery_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
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
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
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

  void _openReceived(EventInvitation inv) {
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

  void _selectTab(int index) {
    if (_tabController.index == index && !_tabController.indexIsChanging) {
      return;
    }
    HapticFeedback.selectionClick();
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitationProvider>();
    final received = provider.received;
    final sent = provider.sent.where((e) => e.status != 'draft').toList();
    final drafts = provider.sent.where((e) => e.status == 'draft').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: context.l10n.invitation,
              trailing: Tooltip(
                message: context.l10n.create,
                child: CircleAssetButton(
                  asset: 'assets/images/png/plus-icon.png',
                  iconSize: 16,
                  onTap: _openGallery,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) {
                  return _SegmentedTabs(
                    position: _tabController.animation!.value,
                    labels: [
                      context.l10n.received,
                      context.l10n.sent,
                      context.l10n.draft,
                    ],
                    onChanged: _selectTab,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InvitationGrid(
                    items: received,
                    isLoading: provider.isLoading,
                    emptyTitle: context.l10n.noInvitationsYet,
                    emptySubtitle:
                        context.l10n.whenSomeoneInvitesYouItWillShowUpHere,
                    onRefresh: provider.fetchAll,
                    onOpen: _openReceived,
                  ),
                  _InvitationGrid(
                    items: sent,
                    isLoading: provider.isLoading,
                    emptyTitle: context.l10n.noSentInvitations,
                    emptySubtitle:
                        context.l10n.createInvitationSaveDraftOrSendHint,
                    onRefresh: provider.fetchAll,
                    onOpen: _openMyCard,
                  ),
                  _InvitationGrid(
                    items: drafts,
                    isLoading: provider.isLoading,
                    emptyTitle: context.l10n.noCardsYet,
                    emptySubtitle:
                        context.l10n.designAnInvitationItWillAppearHere,
                    onRefresh: provider.fetchAll,
                    onOpen: _openMyCard,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final double position;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.position,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final max = (labels.length - 1).toDouble();
    final t = position.clamp(0.0, max);
    final selected = t.round().clamp(0, labels.length - 1);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              Positioned(
                left: t * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontSize: 15,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: i == selected
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
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

class _InvitationGrid extends StatelessWidget {
  final List<EventInvitation> items;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;
  final void Function(EventInvitation) onOpen;

  const _InvitationGrid({
    required this.items,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 36),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
                Text(
                  emptyTitle,
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: BarqodyChrome.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final inv = items[i];
                return _InviteTile(
                  invitation: inv,
                  onTap: () => onOpen(inv),
                );
              },
            ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final EventInvitation invitation;
  final VoidCallback onTap;

  const _InviteTile({required this.invitation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final username = invitation.sender.username.trim();
    final handle = username.isNotEmpty
        ? '@$username'
        : (invitation.sender.displayName.trim().isNotEmpty
            ? invitation.sender.displayName.trim()
            : invitation.title);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _InvitationThumb(invitation: invitation),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: WaUi.body.copyWith(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              children: [
                const TextSpan(text: 'Send by '),
                TextSpan(
                  text: handle,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
      return ColoredBox(
        color: const Color(0xFFF4F4F6),
        child: InvitationDesignRenderer(
          design: invitation.design!,
          invitationId: invitation.id,
          shadows: const [],
        ),
      );
    }

    return ColoredBox(
      color: invitationColorFromHex(invitation.themeColor).withValues(alpha: 0.08),
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
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
    );
  }
}

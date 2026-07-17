import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/invitations/create_invitation_screen.dart';
import 'package:tapni_app/screens/invitations/customize_invitation_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_detail_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitationProvider>();

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Invitations', style: WaUi.sectionHeader),
        bottom: TabBar(
          controller: _tabController,
          labelColor: WaUi.primaryText,
          unselectedLabelColor: WaUi.secondaryText,
          indicatorColor: WaUi.accent,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateInvitationScreen()),
          );
        },
        backgroundColor: WaUi.buttonDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InvitationList(
            items: provider.received,
            isLoading: provider.isLoading,
            emptyTitle: 'No invitations yet',
            emptySubtitle: 'When someone invites you, it will show up here.',
            onRefresh: () => provider.fetchReceived(),
          ),
          _InvitationList(
            items: provider.sent,
            isLoading: provider.isLoading,
            emptyTitle: 'No sent invitations',
            emptySubtitle:
                'Create an invitation, save as draft, or send to contacts.',
            onRefresh: () => provider.fetchSent(),
            showRecipientCount: true,
          ),
        ],
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

  const _InvitationList({
    required this.items,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    this.showRecipientCount = false,
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Icon(Icons.mail_outline, size: 48, color: WaUi.promoIconFg),
                const SizedBox(height: 16),
                Text(emptyTitle,
                    textAlign: TextAlign.center, style: WaUi.sectionHeader),
                const SizedBox(height: 8),
                Text(emptySubtitle,
                    textAlign: TextAlign.center, style: WaUi.caption),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final inv = items[i];
                final color = invitationColorFromHex(inv.themeColor);
                return Material(
                  color: WaUi.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (inv.status == 'draft') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomizeInvitationScreen(
                              draft: InvitationDraft.fromInvitation(inv),
                              fromDraftList: true,
                            ),
                          ),
                        );
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
                            child: Icon(Icons.celebration_outlined,
                                color: color),
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
                                          'Draft',
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
                                          ? '${inv.typeDisplay} · Draft'
                                          : _sentToLabel(inv)
                                      : '${inv.sender.displayName} · ${inv.typeDisplay}',
                                  style: WaUi.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: WaUi.secondaryText),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/release_features.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/curved_bottom_nav.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/go_bussiness_button.dart';
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/links_widget.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/widgets/profile_empty_state.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class SocialLinksScreen extends StatelessWidget {
  final bool isTab;
  const SocialLinksScreen({super.key, this.isTab = false});

  static const _linkVector = 'assets/images/png/link.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final currentLinks = profileProvider.profile.socialLinks
        .where(ReleaseFeatures.isPersonalLinkVisible)
        .toList();
    final waitingForProfile =
        !profileProvider.hasLoadedProfile && profileProvider.isLoading;
    // Tab mode: clear the scooped nav bar + floating FAB so Add Link stays tappable.
    final addLinkBottom = isTab
        ? CurvedBottomNav.contentClearance(context) +
            CurvedBottomNav.fabOverhang() +
            8
        : 24.0;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaChatsHeader(
              title: context.l10n.links,
              leading: isTab
                  ? null
                  : CircleBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
              actions:  [
                NotificationIconButton(),
                GoBussinessButton(),
              ],
            ),
            Expanded(
              child: waitingForProfile
                  ? const _LinksListShimmer()
                  : currentLinks.isEmpty
                      ? Center(
                          child: ProfileEmptyState(
                            imageAsset: _linkVector,
                            title: context.l10n.appsEmpty,
                            subtitle: context.l10n.appsEmptySubtitle,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: currentLinks.length,
                          itemBuilder: (context, index) {
                            final link = currentLinks[index];
                            return _buildLinkTile(
                              context,
                              link,
                              profileProvider,
                              isDark,
                            );
                          },
                        ),
            ),
            Material(
              color: WaUi.toolsScaffold,
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(16, 8, 16, addLinkBottom.toDouble()),
                child: CustomAppButton(
                  width: double.infinity,
                  text: context.l10n.addLink2,
                  icon: Icons.add,
                  backgroundColor: AppTheme.primaryBlack,
                  onTap: () {
                    LinkSheet().showAddLinkBottomSheet(
                      context,
                      profileProvider,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinkPlatformIcon(
              link: link,
              size: 44,
              fit: BoxFit.contain,
            ),
          ),
          title: Text(
            link.platformName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: link.isActive,
                activeColor: Colors.black,
                onChanged: (_) => provider.toggleLinkActive(link.id),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
          onTap: () =>
              LinkSheet().showExistingLinkBottomSheet(context, link, provider),
        ),
      ),
    );
  }
}

class _LinksListShimmer extends StatelessWidget {
  const _LinksListShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: 6,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const ShimmerBox(width: 44, height: 44, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerBox(
                      width: 100.0 + (index % 3) * 24,
                      height: 15,
                      borderRadius: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ShimmerBox(width: 40, height: 24, borderRadius: 12),
                  const SizedBox(width: 8),
                  const ShimmerBox(width: 18, height: 18, borderRadius: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

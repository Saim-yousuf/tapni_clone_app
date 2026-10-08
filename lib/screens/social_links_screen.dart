import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/curved_bottom_nav.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/go_bussiness_button.dart';
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/links_widget.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class SocialLinksScreen extends StatelessWidget {
  final bool isTab;
  const SocialLinksScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final currentLinks = profileProvider.profile.socialLinks;
    // Clear the floating center FAB when shown inside MainShell.
    final addLinkBottom = isTab ? CurvedBottomNav.fabOverhang() + 8 : 24;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.links
        ),
        automaticallyImplyLeading: !isTab,
        actions: [
          NotificationIconButton(),
          GoBussinessButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentLinks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF222222)
                                  : WaUi.navPill,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.link_rounded,
                              size: 40,
                              color: WaUi.secondaryText.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.noLinksAddedYetNTapAddLinkToGetStarted,
                            textAlign: TextAlign.center,
                            style: WaUi.sectionHeader.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : WaUi.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, addLinkBottom.toDouble()),
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
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

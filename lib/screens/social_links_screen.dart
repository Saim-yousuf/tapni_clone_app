import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/go_bussiness_button.dart';
import 'package:tapni_app/widgets/links_widget.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.links,
          style: WaUi.toolsTitle.copyWith(fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: !isTab,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        context.l10n.noLinksAddedYetNTapAddLinkToGetStarted,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
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
              // Clear MainShell center-docked profile FAB (~80px).
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
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
            child: link.logoUrl?.isNotEmpty == true
                ? Image.network(
                    link.logoUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _linkPlaceholder(),
                  )
                : Image.asset(
                    _getPlatformAsset(link.platform),
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => _linkPlaceholder(),
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

  Widget _linkPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.link, size: 20),
    );
  }

  String _getPlatformAsset(SocialPlatform platform) {
    return SocialLink.getAssetPath(platform);
  }

  String _getPlatformName(SocialPlatform platform) {
    return SocialLink.getPlatformName(platform);
  }
}

class _LinkSettingsSheet extends StatefulWidget {
  final SocialPlatform platform;
  final TextEditingController labelController;
  final TextEditingController usernameController;
  final bool isDark;
  final bool isNew;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  _LinkSettingsSheet({
    required this.platform,
    required this.labelController,
    required this.usernameController,
    required this.isDark,
    required this.isNew,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_LinkSettingsSheet> createState() => _LinkSettingsSheetState();
}

class _LinkSettingsSheetState extends State<_LinkSettingsSheet> {
  bool _showLink = true;

  String _getPlatformAsset(SocialPlatform platform) {
    return SocialLink.getAssetPath(platform);
  }

  String _getUsernameHint(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.whatsApp:
        return context.l10n.enterYourPhoneNumber;
      // case SocialPlatform.website:
      //   return context.l10n.enterYourWebsiteURL;
      default:
        return context.l10n.enterYourPlatformUsername(
          _getPlatformNameStr(platform),
        );
    }
  }

  String _getPlatformNameStr(SocialPlatform platform) {
    return SocialLink.getPlatformName(platform);
  }

  @override
  Widget build(BuildContext context) {
    final fieldColor = widget.isDark
        ? const Color(0xFF222222)
        : const Color(0xFFF5F5F5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          margin: EdgeInsets.only(top: 12, bottom: 16),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Text(context.l10n.linkSettings2,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Label row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      _getPlatformAsset(widget.platform),
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.link),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: widget.labelController,
                          decoration: WaUi.fieldDecoration(
                            hintText: context.l10n.label,
                            radius: 10,
                          ),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            context.l10n.setTextUnderTheLinkIcon,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Username field
              TextField(
                controller: widget.usernameController,
                decoration: WaUi.fieldDecoration(radius: 10),
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  _getUsernameHint(widget.platform),
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              SizedBox(height: 16),

              // Show link toggle
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: WaUi.fieldBox.copyWith(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.showLink,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch.adaptive(
                      value: _showLink,
                      activeColor: Colors.black,
                      onChanged: (val) => setState(() => _showLink = val),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  context.l10n.whenTurnedOffThisLinkWontBeShownOnYourProfile,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              SizedBox(height: 24),

              // Bottom actions
              Row(
                children: [
                  if (widget.onDelete != null)
                    Container(
                      decoration: BoxDecoration(
                        color: fieldColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline_rounded),
                        onPressed: widget.onDelete,
                      ),
                    ),
                  if (widget.onDelete != null) SizedBox(width: 12),
                  Expanded(
                    child: WaPrimaryButton(
                      label: widget.isNew
                          ? context.l10n.add
                          : context.l10n.save,
                      onPressed: widget.onSave,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

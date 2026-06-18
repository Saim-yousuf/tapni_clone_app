import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/go_bussiness_button.dart';
import 'package:tapni_app/widgets/links_widget.dart';

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
        title: Row(
          children: [
            Text('Links'),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {},
            ),
          ],
        ),
        centerTitle: false,
        automaticallyImplyLeading: !isTab,
        actions: [GoBussinessButton()],
      ),
      body: Stack(
        children: [
          currentLinks.isEmpty
              ? Center(
                  child: Text(
                    'No links added yet.\nTap "Add link" to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 110.0, left: 15, right: 15),
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: CustomAppButton(
                width: double.infinity,
                text: 'Add link',
                icon: Icons.add,
                backgroundColor: AppTheme.primaryBlack,
                onTap: () {
                  LinkSheet().showAddLinkBottomSheet(context, profileProvider);
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

  const _LinkSettingsSheet({
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
        return 'Enter your phone number';
      // case SocialPlatform.website:
      //   return 'Enter your website URL';
      default:
        return 'Enter your ${_getPlatformNameStr(platform)} username';
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
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const Text(
          'Link settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

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
                        child: const Icon(Icons.link),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: widget.labelController,
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Label',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Set text under the link icon',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Username field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: widget.usernameController,
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  _getUsernameHint(widget.platform),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // Show link toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Show link',
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
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  "When turned off this link won't be shown on your profile",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

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
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: widget.onDelete,
                      ),
                    ),
                  if (widget.onDelete != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.isNew ? 'Add' : 'Save',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

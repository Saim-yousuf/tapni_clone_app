import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';

class SocialLinksScreen extends StatelessWidget {
  final bool isTab;
  const SocialLinksScreen({Key? key, this.isTab = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final currentLinks = profileProvider.profile.socialLinks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Links',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        automaticallyImplyLeading: !isTab,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () {}),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Text('Go', style: TextStyle(color: Colors.white, fontSize: 12)),
                SizedBox(width: 4),
                Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              child: GestureDetector(
                onTap: () {
                  _showAddLinkBottomSheet(context, profileProvider);
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add link',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.add, color: Colors.white),
                    ],
                  ),
                ),
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
            child: Image.asset(
              _getPlatformAsset(link.platform),
              width: 44,
              height: 44,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link, size: 20),
              ),
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
          onTap: () => _showEditBottomSheet(context, link, provider, isDark),
        ),
      ),
    );
  }

  // ─── ADD LINK BOTTOM SHEET ──────────────────────────────────────────────────
  void _showAddLinkBottomSheet(BuildContext context, ProfileProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      // {
      //   'title': 'Featured',
      //   'platforms': [SocialPlatform.website],
      // },
      {
        'title': 'Social media',
        'platforms': [
          SocialPlatform.instagram,
          // SocialPlatform.facebook,
          // SocialPlatform.youTube,
          SocialPlatform.linkedIn,
        ],
      },
      {
        'title': 'Contact',
        'platforms': [SocialPlatform.whatsApp],
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Add Link',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Grid content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: categories.map((cat) {
                      final platforms =
                          cat['platforms'] as List<SocialPlatform>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              cat['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.8,
                                ),
                            itemCount: platforms.length,
                            itemBuilder: (context, index) {
                              final platform = platforms[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showNewLinkBottomSheet(
                                    context,
                                    platform,
                                    provider,
                                  );
                                },
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        _getPlatformAsset(platform),
                                        width: 64,
                                        height: 64,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(Icons.link),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _getPlatformName(platform),
                                      style: const TextStyle(fontSize: 11),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── NEW LINK BOTTOM SHEET (after selecting platform) ───────────────────────
  void _showNewLinkBottomSheet(
    BuildContext context,
    SocialPlatform platform,
    ProfileProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usernameController = TextEditingController();
    final labelController = TextEditingController(
      text: _getPlatformName(platform),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _LinkSettingsSheet(
            platform: platform,
            labelController: labelController,
            usernameController: usernameController,
            isDark: isDark,
            isNew: true,
            onSave: () {
              if (usernameController.text.trim().isNotEmpty) {
                provider.addSocialLink(
                  platform,
                  usernameController.text.trim(),
                  true,
                );
                Navigator.pop(ctx);
              }
            },
            onDelete: null,
          ),
        );
      },
    );
  }

  // ─── EDIT BOTTOM SHEET ───────────────────────────────────────────────────────
  void _showEditBottomSheet(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
    bool isDark,
  ) {
    final usernameController = TextEditingController(text: link.value);
    final labelController = TextEditingController(text: link.platformName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _LinkSettingsSheet(
            platform: link.platform,
            labelController: labelController,
            usernameController: usernameController,
            isDark: isDark,
            isNew: false,
            onSave: () {
              if (usernameController.text.trim().isNotEmpty) {
                provider.updateSocialLink(
                  link.id,
                  usernameController.text.trim(),
                  link.isActive,
                );
                Navigator.pop(ctx);
              }
            },
            onDelete: () {
              provider.deleteSocialLink(link.id);
              Navigator.pop(ctx);
            },
          ),
        );
      },
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

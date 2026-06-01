import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';

class SocialLinksScreen extends StatelessWidget {
  final bool isTab;
  const SocialLinksScreen({Key? key, this.isTab = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final currentLinks = profileProvider.profile.socialLinks;

    // Separate platforms into "Added" and "Available to Add"
    final addedPlatforms = currentLinks.map((l) => l.platform).toSet();
    final availablePlatforms = SocialPlatform.values.where((p) => !addedPlatforms.contains(p)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Social Links'),
        automaticallyImplyLeading: !isTab,
        leading: isTab ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Instructions
            Text(
              'Connected Socials',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Turn links on or off to control what you share.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
              ),
            ),
            const SizedBox(height: 20),

            // Active / Added Links list
            if (currentLinks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Text(
                  'No social links added yet. Add some below!',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...currentLinks.map((link) {
                return _buildAddedLinkCard(context, link, profileProvider, isDark);
              }).toList(),

            const SizedBox(height: 32),
            
            // Available to Add Section
            if (availablePlatforms.isNotEmpty) ...[
              Text(
                'Available to Add',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: availablePlatforms.length,
                itemBuilder: (context, index) {
                  final platform = availablePlatforms[index];
                  return _buildAvailablePlatformCard(context, platform, profileProvider, isDark);
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedLinkCard(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
    bool isDark,
  ) {
    Color brandColor;
    IconData iconData;

    switch (link.platform) {
      case SocialPlatform.whatsApp:
        brandColor = const Color(0xFF25D366);
        iconData = Icons.chat_bubble_outline;
        break;
      case SocialPlatform.linkedIn:
        brandColor = const Color(0xFF0077B5);
        iconData = Icons.business_outlined;
        break;
      case SocialPlatform.instagram:
        brandColor = const Color(0xFFE1306C);
        iconData = Icons.camera_alt_outlined;
        break;
      case SocialPlatform.facebook:
        brandColor = const Color(0xFF1877F2);
        iconData = Icons.facebook_outlined;
        break;
      case SocialPlatform.youTube:
        brandColor = const Color(0xFFFF0000);
        iconData = Icons.play_arrow_outlined;
        break;
      case SocialPlatform.website:
        brandColor = AppTheme.accentGold;
        iconData = Icons.language_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Brand Icon Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(link.isActive ? 0.9 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconData, 
                  color: link.isActive ? Colors.white : brandColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Link details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.platformName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    link.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Actions: Edit, Delete, Toggle Active
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? Colors.white60 : Colors.black54),
              onPressed: () => _showEditLinkDialog(context, link, provider),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              onPressed: () => provider.deleteSocialLink(link.id),
            ),
            Switch.adaptive(
              value: link.isActive,
              activeColor: AppTheme.accentGold,
              onChanged: (_) => provider.toggleLinkActive(link.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePlatformCard(
    BuildContext context,
    SocialPlatform platform,
    ProfileProvider provider,
    bool isDark,
  ) {
    String name;
    IconData icon;
    Color brandColor;

    switch (platform) {
      case SocialPlatform.whatsApp:
        name = 'WhatsApp';
        icon = Icons.chat_bubble_outline;
        brandColor = const Color(0xFF25D366);
        break;
      case SocialPlatform.linkedIn:
        name = 'LinkedIn';
        icon = Icons.business_outlined;
        brandColor = const Color(0xFF0077B5);
        break;
      case SocialPlatform.instagram:
        name = 'Instagram';
        icon = Icons.camera_alt_outlined;
        brandColor = const Color(0xFFE1306C);
        break;
      case SocialPlatform.facebook:
        name = 'Facebook';
        icon = Icons.facebook_outlined;
        brandColor = const Color(0xFF1877F2);
        break;
      case SocialPlatform.youTube:
        name = 'YouTube';
        icon = Icons.play_arrow_outlined;
        brandColor = const Color(0xFFFF0000);
        break;
      case SocialPlatform.website:
        name = 'Website';
        icon = Icons.language_outlined;
        brandColor = AppTheme.accentGold;
        break;
    }

    return InkWell(
      onTap: () => _showAddLinkDialog(context, platform, provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDarkBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.greyBorderDark : AppTheme.greyBorderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: brandColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    '+ Add',
                    style: TextStyle(
                      color: AppTheme.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLinkDialog(
    BuildContext context,
    SocialPlatform platform,
    ProfileProvider provider,
  ) {
    final controller = TextEditingController();
    final linkTemplate = SocialLink(id: '', platform: platform, value: '');
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add ${linkTemplate.platformName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your ${linkTemplate.label}:',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: platform == SocialPlatform.website 
                      ? 'www.mywebsite.com' 
                      : platform == SocialPlatform.whatsApp
                          ? '+15551234567'
                          : 'username',
                  prefixText: platform == SocialPlatform.website || platform == SocialPlatform.whatsApp
                      ? null 
                      : linkTemplate.baseUrlPrefix,
                  prefixStyle: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  provider.addSocialLink(platform, controller.text.trim());
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditLinkDialog(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
  ) {
    final controller = TextEditingController(text: link.value);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit ${link.platformName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your ${link.label}:',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: link.platform == SocialPlatform.website || link.platform == SocialPlatform.whatsApp
                      ? null 
                      : link.baseUrlPrefix,
                  prefixStyle: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  provider.updateSocialLink(link.id, controller.text.trim(), link.isActive);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

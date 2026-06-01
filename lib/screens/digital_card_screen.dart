import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/edit_profile_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/screens/qr_code_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/social_icon_button.dart';

class DigitalCardScreen extends StatelessWidget {
  const DigitalCardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text('tapni.com/${profile.name.replaceAll(' ', '').toLowerCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrCodeScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Glassmorphic Card Container representing the Business Card itself
            GlassCard(
              blur: 20,
              borderOpacity: 0.12,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Logo/NFC Symbol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.contactless, color: AppTheme.accentGold, size: 28),
                      Text(
                        'tapni PRO',
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Photo Initial
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0] : 'S',
                        style: const TextStyle(
                          color: AppTheme.secondaryWhite,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Name and Designation
                  Text(
                    profile.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.designation,
                    style: TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    profile.company,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Bio
                  Text(
                    profile.bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 12),
                  
                  // Quick Actions Bar (Phone, Email, Web)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.phone_outlined,
                        label: 'Call',
                        onTap: () => _copyToClipboard(context, profile.phone, 'Phone number'),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        onTap: () => _copyToClipboard(context, profile.email, 'Email address'),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.language_outlined,
                        label: 'Website',
                        onTap: () => _copyToClipboard(context, profile.website, 'Website URL'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Edit Shortcuts Area
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SocialLinksScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text('Social Links'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Active Social Links List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Connected Accounts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Check if there are any active links
            profile.socialLinks.where((l) => l.isActive).isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.link_off, size: 36, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'No active links connected yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Social Links" above to add and activate profiles.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: profile.socialLinks.where((l) => l.isActive).length,
                    itemBuilder: (context, index) {
                      final activeLinks = profile.socialLinks.where((l) => l.isActive).toList();
                      final link = activeLinks[index];
                      return SocialIconButton(
                        socialLink: link,
                        showLabel: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening mock link: ${link.fullUrl}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard: $text'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

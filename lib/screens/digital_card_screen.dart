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
import 'package:tapni_app/widgets/templates_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class DigitalCardScreen extends StatelessWidget {
  DigitalCardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    final currentTemplate = profileProvider.currentTemplate;

    return Scaffold(
      appBar: AppBar(
        title: Text('tapni.com/${profile.name.replaceAll(' ', '').toLowerCase()}'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined),
            tooltip: context.l10n.chooseTemplate,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const TemplatesSheet(),
              );
            },
          ),
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
            // Colored and themed Card Container representing the Business Card itself based on selected template
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: currentTemplate.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: currentTemplate.backgroundColor == Colors.white
                    ? Border.all(color: Colors.black.withOpacity(0.08), width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Logo/NFC Symbol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.contactless,
                        color: currentTemplate.brandingColor.withOpacity(0.8),
                        size: 28,
                      ),
                      Row(
                        children: [
                          Text(
                            currentTemplate.isPro ? 'tapni PRO' : context.l10n.tapni,
                            style: TextStyle(
                              color: currentTemplate.brandingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (currentTemplate.isPro) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentTemplate.textColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                context.l10n.pro,
                                style: TextStyle(
                                  color: currentTemplate.backgroundColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 7,
                                ),
                              ),
                            )
                          ]
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Profile Photo Initial
                  // Profile Photo Initial
                  profile.profilePhotoUrl != null &&
                          profile.profilePhotoUrl!.trim().isNotEmpty
                      ? Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: currentTemplate.textColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(profile.profilePhotoUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: currentTemplate.isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                              style: TextStyle(
                                color: currentTemplate.textColor,
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
                      color: currentTemplate.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.designation,
                    style: TextStyle(
                      color: currentTemplate.brandingColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    profile.company,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: currentTemplate.labelColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Bio
                  Text(
                    profile.bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: currentTemplate.textColor.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Divider(color: currentTemplate.textColor.withOpacity(0.15)),
                  SizedBox(height: 12),
                  
                  // Quick Actions Bar (Phone, Email, Web)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.phone_outlined,
                        label: context.l10n.call,
                        textColor: currentTemplate.textColor,
                        labelColor: currentTemplate.labelColor,
                        onTap: () => _copyToClipboard(context, profile.phone, context.l10n.phoneNumber2),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.email_outlined,
                        label: context.l10n.email,
                        textColor: currentTemplate.textColor,
                        labelColor: currentTemplate.labelColor,
                        onTap: () => _copyToClipboard(context, profile.email, context.l10n.emailAddress2),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.language_outlined,
                        label: context.l10n.website,
                        textColor: currentTemplate.textColor,
                        labelColor: currentTemplate.labelColor,
                        onTap: () => _copyToClipboard(context, profile.website, context.l10n.websiteURL),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // Edit Shortcuts Area
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditProfileScreen()),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, size: 18),
                    label: Text(context.l10n.editDetails),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SocialLinksScreen()),
                      );
                    },
                    icon: Icon(Icons.add_link_rounded, size: 18),
                    label: Text(context.l10n.socialLinks),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Active Social Links List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.connectedAccounts,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Check if there are any active links
            profile.socialLinks.where((l) => l.isActive).isEmpty
                ? Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.link_off, size: 36, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(context.l10n.noActiveLinksConnectedYet,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          context.l10n.tapSocialLinksAboveToAddAndActivateProfiles,
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
                              content: Text(
                                context.l10n.openingMockLink(link.fullUrl),
                              ),
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
    required Color textColor,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: textColor.withOpacity(0.85),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
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
        content: Text(context.l10n.copiedTypeToClipboard(type)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/login_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/qr_code_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/settings_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out of Barqody?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();

                // Clear all data from providers
                Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                ).clearData();
                Provider.of<LeadsProvider>(context, listen: false).clearData();
                Provider.of<SubscriptionProvider>(
                  context,
                  listen: false,
                ).clearData();

                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profile = Provider.of<ProfileProvider>(context).profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child:
                        profile.profilePhotoUrl != null &&
                            profile.profilePhotoUrl!.trim().isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              profile.profilePhotoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0] : '?',
                              style: const TextStyle(
                                color: AppTheme.secondaryWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          profile.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.textGreyDark
                                : AppTheme.textGreyLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      SettingWidgets.showSettingSheet(context);
                    },
                    icon: Icon(Icons.settings),
                    iconSize: 30,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!profile.isPro)
              InkWell(
                onTap: () {
                  SubcriptionSheet.show(context);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppTheme.primaryBlack,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Try Business",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.secondaryWhite,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryWhite,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pro',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            // Settings Categories
            // _buildSectionHeader('Preferences'),
            // _buildToggleItem(
            //   context,
            //   icon: Icons.dark_mode_outlined,
            //   title: 'Dark Mode Theme',
            //   subtitle: 'Sleek premium background',
            //   value: isDark,
            //   onChanged: (_) {
            //     Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            //   },
            // ),
            // const SizedBox(height: 16),
            _buildSectionHeader('Profile Configuration'),
            _buildSettingsItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Edit Information',
              subtitle: 'Change name, profile photo, and bio',
              onTap: () {
                final profileProvider = Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                );
                profileProvider.setEditingProfile(true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MainShell(currentPage: "My Card"),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.add_link_rounded,
              title: 'Manage Social Handles',
              subtitle: 'Activate and link external channels',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SocialLinksScreen()),
                );
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.qr_code_rounded,
              title: 'Generate Card QR',
              subtitle: 'Share digital business card link',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const QrCodeScreen()));
              },
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('Security & Support'),
            _buildSettingsItem(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Help Center',
              subtitle: 'Faq and documentation',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help Center is disabled in this UI demo.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.feedback_outlined,
              title: 'Submit App Feedback',
              subtitle: 'Report a bug or suggest features',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Thank you! Feedback submissions are mock only.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            // Logout Button
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.redAccent.withOpacity(0.08),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Sign out of this session',
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.redAccent,
                size: 14,
              ),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 40),

            // Version info footer
            const Center(
              child: Text(
                'barqody v1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppTheme.accentGold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.015),
        leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87,size: 35,),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: isDark ? Colors.white30 : Colors.black38,
          size: 12,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.015),
        leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        trailing: Switch.adaptive(
          value: value,
          activeColor: AppTheme.accentGold,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

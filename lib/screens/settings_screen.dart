import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/attendance/business/attendance_dashboard_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_business_cards_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/attendance/employee/mark_attendance_screen.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/screens/linked_devices/account_switcher_sheet.dart';
import 'package:tapni_app/screens/linked_devices/linked_devices_screen.dart';
import 'package:tapni_app/screens/login_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_list_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_loyalty_home_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/qr_code_screen.dart';
import 'package:tapni_app/screens/set_username_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/settings_widget.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _promoDismissed = false;
  int _pendingInvitationCount = 0;
  bool _updatingVisibility = false;

  @override
  void initState() {
    super.initState();
    _loadPendingInvitations();
  }

  Future<void> _loadPendingInvitations() async {
    final res = await AttendanceRepo().getMyInvitations();
    if (!mounted) return;
    if (res.success) {
      final invitations = parseAttendanceList(
        res.data,
        AttendanceEmployee.fromJson,
      );
      setState(() => _pendingInvitationCount = invitations.length);
    }
  }

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasOthers = authProvider.hasMultipleAccounts;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaUi.radiusLg),
          ),
          title: Text('Log Out', style: WaUi.title),
          content: Text(
            hasOthers
                ? 'Log out of this account only? Other accounts will stay on this phone.'
                : 'Are you sure you want to log out of Barqody?',
            style: WaUi.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: WaUi.bodyMedium),
            ),
            if (hasOthers)
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _performLogout(context, logoutAll: true);
                },
                child: Text(
                  'Log out all',
                  style: WaUi.bodyMedium.copyWith(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _performLogout(context, logoutAll: false);
              },
              child: Text(
                hasOthers ? 'This account' : 'Log Out',
                style: WaUi.bodyMedium.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(
    BuildContext context, {
    required bool logoutAll,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<ProfileProvider>(context, listen: false).clearData();
    Provider.of<LeadsProvider>(context, listen: false).clearData();
    Provider.of<SubscriptionProvider>(context, listen: false).clearData();

    final switched = await authProvider.logout(logoutAll: logoutAll);
    if (!context.mounted) return;

    if (switched && !logoutAll) {
      final subProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subProvider.checkSubscriptionStatus();
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      await profileProvider.fetchProfile();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  int _catalogOrderBadge(LeadsProvider leadsProvider) {
    return leadsProvider.notifications
        .where((n) => n['type'] == 'catalog_order' && n['isRead'] == false)
        .length;
  }

  Future<void> _toggleProfileVisibility(bool isPublic) async {
    if (_updatingVisibility) return;
    setState(() => _updatingVisibility = true);

    final response = await Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).updateProfileVisibility(isPublic: isPublic, context: context);

    if (!mounted) return;
    setState(() => _updatingVisibility = false);

    if (!response.success) {
      final errorMessage = (response.message ?? '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.isNotEmpty
                ? errorMessage
                : 'Could not update profile visibility',
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WaUi.primaryText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final orderBadge = _catalogOrderBadge(leadsProvider);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            WaToolsHeader(
              title: 'Tools',
              actions: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined, size: 24),
                  color: WaUi.primaryText,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrCodeScreen()),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 24, color: WaUi.primaryText),
                  color: WaUi.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'account':
                        SettingWidgets.showSettingSheet(context);
                        break;
                      case 'notifications':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'account',
                      child: Text('Account settings', style: WaUi.body),
                    ),
                    PopupMenuItem(
                      value: 'notifications',
                      child: Text('Notifications', style: WaUi.body),
                    ),
                  ],
                ),
              ],
            ),

            if (!profile.isPro && !_promoDismissed) ...[
              const WaSectionHeader('For you'),
              WaForYouCard(
                title: 'Try Business Pro.',
                description:
                    'Unlock customer orders, team attendance, loyalty programs, and more for your business.',
                buttonLabel: 'Try Business Pro',
                onTap: () => SubcriptionSheet.show(context),
                onDismiss: () => setState(() => _promoDismissed = true),
              ),
            ],

            const WaSectionHeader('Your profile'),
            WaToolsListTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Change your name, photo, and bio',
              onTap: () {
                final profileProvider = Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                );
                profileProvider.setEditingProfile(true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MainShell(currentPage: 'My Card'),
                  ),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.alternate_email,
              title: 'Username',
              subtitle: profile.username != null && profile.username!.isNotEmpty
                  ? '@${profile.username}'
                  : 'Set your unique profile username',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SetUsernameScreen()),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.link,
              title: 'Social Links',
              subtitle: 'Add Instagram, WhatsApp, website and more',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SocialLinksScreen()),
                );
              },
            ),
            WaToolsListTile(
              icon: profile.isPublic
                  ? Icons.public_outlined
                  : Icons.lock_outline,
              title: 'Public profile',
              subtitle: profile.isPublic
                  ? 'Anyone can find and view your profile'
                  : 'Hidden from search — others can\'t discover you',
              trailing: _updatingVisibility
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch.adaptive(
                      value: profile.isPublic,
                      activeColor: WaUi.accent,
                      onChanged: _toggleProfileVisibility,
                    ),
            ),
            WaToolsListTile(
              icon: Icons.qr_code_2_outlined,
              title: 'Share My QR Code',
              subtitle: 'Let others scan your digital business card',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrCodeScreen()),
                );
              },
            ),

            const WaSectionHeader('Shopping & rewards'),
            WaToolsListTile(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              subtitle: 'Track orders you placed from shops',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrdersListScreen(isBusinessView: false),
                  ),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.card_giftcard_outlined,
              title: 'My Reward Cards',
              subtitle: 'View stamps and points from loyalty programs',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerLoyaltyHomeScreen(),
                  ),
                );
              },
            ),

            const WaSectionHeader('Workplace'),
            WaToolsListTile(
              icon: Icons.mail_outline,
              title: 'Employee Invitations',
              subtitle: 'Accept or decline team invitations from businesses',
              showBadge: _pendingInvitationCount > 0,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmployeeInvitationsScreen(),
                  ),
                );
                _loadPendingInvitations();
              },
            ),
            WaToolsListTile(
              icon: Icons.fact_check_outlined,
              title: 'Workplace Check-In',
              subtitle: 'Clock in and out at your job with location',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MarkAttendanceScreen(),
                  ),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.badge_outlined,
              title: 'Company Employee Card',
              subtitle: 'Save your work ID card to phone or wallet',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmployeeBusinessCardsScreen(),
                  ),
                );
              },
            ),

            if (profile.isPro) ...[
              const WaSectionHeader('Grow your business'),
              WaToolsListTile(
                icon: Icons.storefront_outlined,
                title: 'Customer Orders',
                subtitle: 'View and update orders from your customers',
                showBadge: orderBadge > 0,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrdersListScreen(isBusinessView: true),
                    ),
                  );
                },
              ),
              WaToolsListTile(
                icon: Icons.groups_outlined,
                title: 'Team Attendance',
                subtitle: 'Invite employees, set shifts and track presence',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AttendanceDashboardScreen(),
                    ),
                  );
                },
              ),
              WaToolsListTile(
                icon: Icons.stars_outlined,
                title: 'Loyalty Programs',
                subtitle: 'Create stamp or points rewards for customers',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LoyaltyProgramListScreen(),
                    ),
                  );
                },
              ),
            ],

            const WaSectionHeader('Accounts & devices'),
            WaToolsListTile(
              icon: Icons.devices_outlined,
              title: 'Linked devices',
              subtitle: 'Link another phone like WhatsApp',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LinkedDevicesScreen(),
                  ),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.switch_account_outlined,
              title: 'Accounts',
              subtitle: Provider.of<AuthProvider>(context).hasMultipleAccounts
                  ? 'Switch between ${Provider.of<AuthProvider>(context).accounts.length} accounts'
                  : 'Add or switch accounts',
              onTap: () => AccountSwitcherSheet.show(context),
            ),

            const WaSectionHeader('Help & account'),
            WaToolsListTile(
              icon: Icons.help_outline,
              title: 'Help & FAQs',
              subtitle: 'Answers to common questions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Help Center is disabled in this UI demo.',
                      style: WaUi.body.copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: WaUi.primaryText,
                  ),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Report a bug or suggest a new feature',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Thank you! Feedback submissions are mock only.',
                      style: WaUi.body.copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: WaUi.primaryText,
                  ),
                );
              },
            ),
            WaToolsListTile(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out of this session',
              titleColor: Colors.redAccent,
              onTap: () => _handleLogout(context),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text('barqody v1.0.0', style: WaUi.label),
            ),
          ],
        ),
      ),
    );
  }
}

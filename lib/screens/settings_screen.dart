import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/screens/linked_devices/account_switcher_sheet.dart';
import 'package:tapni_app/screens/linked_devices/linked_devices_screen.dart';
import 'package:tapni_app/l10n/app_languages.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/screens/app_language_screen.dart';
import 'package:tapni_app/screens/business_suite_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_guide_sheet.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/help/help_center_screen.dart';
import 'package:tapni_app/screens/invitations/invitations_home_screen.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_loyalty_home_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/qr_code_screen.dart';
import 'package:tapni_app/screens/qr_code_sheet.dart';
import 'package:tapni_app/screens/set_username_screen.dart';
import 'package:tapni_app/screens/workplace_screen.dart';
import 'package:tapni_app/screens/caller_id_setup_screen.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/feedback_dialog.dart';
import 'package:tapni_app/widgets/logout_confirm_dialog.dart';
import 'package:tapni_app/widgets/settings_widget.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

    await LogoutConfirmDialog.show(
      context,
      hasOtherAccounts: hasOthers,
      onLogoutThis: () => _performLogout(context, logoutAll: false),
      onLogoutAll: hasOthers
          ? () => _performLogout(context, logoutAll: true)
          : null,
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
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
      (route) => false,
    );
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
                : context.l10n.couldNotUpdateProfileVisibility,
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
    final localeProvider = Provider.of<LocaleProvider>(context);
    final unreadCount = leadsProvider.unreadNotificationsCount;
    final languageSubtitle = localeProvider.isSystemLanguage
        ? context.l10n.phoneLanguage
        : (localeProvider.selectedLanguage?.displayName ??
              AppLanguages.findByCode('en')!.displayName);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        bottom: false,
        child: Padding(
           padding: const EdgeInsets.only(bottom: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaToolsHeader(
                title: context.l10n.tools,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera_outlined, size: 24),
                    color: WaUi.primaryText,
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => QrCodeScreen()));
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 24,
                      color: WaUi.primaryText,
                    ),
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
                              builder: (_) => NotificationsScreen(),
                            ),
                          );
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'account',
                        child: Text(
                          context.l10n.accountSettings,
                          style: WaUi.body,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'notifications',
                        child: Text(context.l10n.notifications, style: WaUi.body),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const SizedBox(height: 8),
                    _BusinessSuiteCard(
                      showBadge: profile.isPro &&
                          leadsProvider.notifications.any(
                            (n) =>
                                n['type'] == 'catalog_order' &&
                                n['isRead'] == false,
                          ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BusinessSuiteScreen(),
                          ),
                        );
                      },
                    ),
                    WaSectionHeader(context.l10n.yourProfile),
                    WaToolsListTile(
                      icon: Icons.person_outline,
                      title: context.l10n.editProfile,
                      subtitle: context.l10n.editProfileSubtitle,
                      onTap: () {
                        final profileProvider = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );
                        profileProvider.setEditingProfile(true);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => MainShell(currentPage: 'My Card'),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.person_search_outlined,
                      title: context.l10n.findUser2,
                      subtitle: context.l10n.findPeopleOnBarQody,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FindUserScreen(isTab: false),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.alternate_email,
                      title: context.l10n.username,
                      subtitle:
                          profile.username != null && profile.username!.isNotEmpty
                          ? '@${profile.username}'
                          : context.l10n.setUsernameSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SetUsernameScreen()),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: profile.isPublic
                          ? Icons.public_outlined
                          : Icons.lock_outline,
                      title: context.l10n.publicProfile,
                      subtitle: profile.isPublic
                          ? context.l10n.publicProfileOn
                          : context.l10n.publicProfileOff,
                      trailing: _updatingVisibility
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: Padding(
                                padding: EdgeInsets.all(2),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Switch.adaptive(
                              value: profile.isPublic,
                              activeTrackColor: WaUi.buttonDark,
                              activeThumbColor: Colors.white,
                              onChanged: _toggleProfileVisibility,
                            ),
                    ),
                    WaToolsListTile(
                      icon: Icons.qr_code_2_outlined,
                      title: context.l10n.shareQr,
                      subtitle: context.l10n.shareQrSubtitle,
                      onTap: () => SharingProfileSheet.show(context),
                    ),
                    if (CallerIdService.isFeatureEnabled)
                      WaToolsListTile(
                        icon: Icons.call_outlined,
                        title: context.l10n.callerIdTitle,
                        subtitle: context.l10n.callerIdSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CallerIdSetupScreen(),
                            ),
                          );
                        },
                      ),
                    WaToolsListTile(
                      icon: Icons.mark_email_unread_outlined,
                      title: context.l10n.invitations,
                      subtitle: context.l10n.invitationsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const InvitationsHomeScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.notifications_outlined,
                      title: context.l10n.notifications,
                      subtitle: unreadCount > 0
                          ? context.l10n.unreadCountLabel(unreadCount)
                          : context.l10n.noNewNotificationsAtThisTime,
                      showBadge: unreadCount > 0,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
          
                    WaSectionHeader(context.l10n.shoppingRewards),
                    WaToolsListTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Customer guide',
                      subtitle:
                          'How to browse, order, track, and claim stamp rewards',
                      onTap: () => showCustomerAppGuide(context),
                    ),
                    WaToolsListTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders & Bookings',
                      subtitle: 'Orders, appointments, and stays in one place',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrdersListScreen(isBusinessView: false),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.card_giftcard_outlined,
                      title: context.l10n.myRewardCards,
                      subtitle: context.l10n.myRewardCardsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerLoyaltyHomeScreen(),
                          ),
                        );
                      },
                    ),
          
                    WaSectionHeader(context.l10n.workplace),
                    WaToolsListTile(
                      icon: Icons.work_outline,
                      title: context.l10n.workplace,
                      subtitle:
                          '${context.l10n.employeeInvitations}, ${context.l10n.workplaceCheckIn}, ${context.l10n.companyEmployeeCard}',
                      showBadge: _pendingInvitationCount > 0,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WorkplaceScreen(),
                          ),
                        );
                        _loadPendingInvitations();
                      },
                    ),
          
                    WaSectionHeader(context.l10n.accountsAndDevices),
                    WaToolsListTile(
                      icon: Icons.devices_outlined,
                      title: context.l10n.linkedDevices,
                      subtitle: context.l10n.linkedDevicesSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LinkedDevicesScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.switch_account_outlined,
                      title: context.l10n.accounts,
                      subtitle:
                          Provider.of<AuthProvider>(context).hasMultipleAccounts
                          ? context.l10n.accountsSwitchSubtitle(
                              Provider.of<AuthProvider>(context).accounts.length,
                            )
                          : context.l10n.accountsSubtitle,
                      onTap: () => AccountSwitcherSheet.show(context),
                    ),
          
                    WaSectionHeader(context.l10n.helpAndAccount),
                    WaToolsListTile(
                      icon: Icons.language,
                      title: context.l10n.appLanguage,
                      subtitle: languageSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AppLanguageScreen()),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.help_outline,
                      title: context.l10n.helpFaqs,
                      subtitle: context.l10n.helpFaqsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.feedback_outlined,
                      title: context.l10n.sendFeedback,
                      subtitle: context.l10n.sendFeedbackSubtitle,
                      onTap: () {
                        FeedbackDialog.show(
                          context,
                          onSubmitted: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n
                                      .thankYouFeedbackSubmissionsAreMockOnly,
                                  style: WaUi.body.copyWith(color: Colors.white),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: WaUi.primaryText,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.logout,
                      title: context.l10n.logOut,
                      subtitle: context.l10n.logOutSubtitle,
                      titleColor: Colors.redAccent,
                      onTap: () => _handleLogout(context),
                    ),
          
                    SizedBox(height: 24),
                    Center(
                      child: Text(context.l10n.barqodyV100, style: WaUi.bodyMedium),
                    ),
                    SizedBox(height: 70),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessSuiteCard extends StatelessWidget {
  final bool showBadge;
  final VoidCallback onTap;

  const _BusinessSuiteCard({
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.business_center_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Suite',
                        style: WaUi.listTitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Orders, bookings, team, loyalty, ads & more',
                        style: WaUi.listSubtitle.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showBadge)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

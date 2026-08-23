import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/attendance/business/attendance_dashboard_screen.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/screens/linked_devices/account_switcher_sheet.dart';
import 'package:tapni_app/screens/linked_devices/linked_devices_screen.dart';
import 'package:tapni_app/l10n/app_languages.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/screens/app_language_screen.dart';
import 'package:tapni_app/screens/business_profile_screen.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/help/help_center_screen.dart';
import 'package:tapni_app/screens/invitations/invitations_home_screen.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_list_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_loyalty_home_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/qr_code_screen.dart';
import 'package:tapni_app/screens/qr_code_sheet.dart';
import 'package:tapni_app/screens/set_username_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/screens/workplace_screen.dart';
import 'package:tapni_app/screens/caller_id_setup_screen.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
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
          title: Text(ctx.l10n.logOut, style: WaUi.title),
          content: Text(
            hasOthers
                ? context
                      .l10n
                      .logOutOfThisAccountOnlyOtherAccountsWillStayOnThisPhone
                : context.l10n.areYouSureYouWantToLogOutOfBarqody,
            style: WaUi.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n.cancel, style: WaUi.bodyMedium),
            ),
            if (hasOthers)
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _performLogout(context, logoutAll: true);
                },
                child: Text(
                  context.l10n.logOutAll,
                  style: WaUi.bodyMedium.copyWith(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _performLogout(context, logoutAll: false);
              },
              child: Text(
                hasOthers ? context.l10n.thisAccount : context.l10n.logOut,
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
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
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
    final orderBadge = _catalogOrderBadge(leadsProvider);
    final unreadCount = leadsProvider.unreadNotificationsCount;
    final languageSubtitle = localeProvider.isSystemLanguage
        ? context.l10n.phoneLanguage
        : (localeProvider.selectedLanguage?.displayName ??
              AppLanguages.findByCode('en')!.displayName);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        bottom: false,
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
                  if (!profile.isPro && !_promoDismissed) ...[
                    WaSectionHeader(context.l10n.forYou),
                    WaForYouCard(
                      title: context.l10n.tryBusinessPro2,
                      description: context.l10n.unlockBusinessProDescription,
                      buttonLabel: context.l10n.tryBusinessPro,
                      onTap: () => SubcriptionSheet.show(context),
                      onDismiss: () => setState(() => _promoDismissed = true),
                    ),
                  ],

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
                  Builder(
                    builder: (context) {
                      final completeness = BusinessCompleteness.fromProfile(
                        profile,
                      );
                      return WaToolsListTile(
                        icon: Icons.storefront_outlined,
                        title: 'Business Profile',
                        subtitle: profile.isPro
                            ? completeness.progressLabel
                            : 'Name, industry, and public location',
                        onTap: () {
                          if (!profile.isPro) {
                            SubcriptionSheet.show(context);
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BusinessProfileScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  WaToolsListTile(
                    icon: Icons.link_outlined,
                    title: context.l10n.links,
                    subtitle: context.l10n.socialLinksSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SocialLinksScreen(isTab: false),
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
                            activeColor: WaUi.accent,
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
                    icon: Icons.receipt_long_outlined,
                    title: context.l10n.myOrders,
                    subtitle: context.l10n.myOrdersSubtitle,
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

                  if (profile.isPro) ...[
                    WaSectionHeader(context.l10n.growYourBusiness),
                    WaToolsListTile(
                      icon: Icons.storefront_outlined,
                      title: context.l10n.customerOrders,
                      subtitle:
                          context.l10n.viewAndUpdateOrdersFromYourCustomers,
                      showBadge: orderBadge > 0,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrdersListScreen(isBusinessView: true),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.groups_outlined,
                      title: context.l10n.teamAttendance,
                      subtitle:
                          context.l10n.inviteEmployeesSetShiftsAndTrackPresence,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttendanceDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.stars_outlined,
                      title: context.l10n.loyaltyPrograms,
                      subtitle:
                          context.l10n.createStampOrPointsRewardsForCustomers,
                      onTap: () async {
                        final ok = await ensureBusinessProfileComplete(context);
                        if (!ok || !context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoyaltyProgramListScreen(),
                          ),
                        );
                      },
                    ),
                  ],

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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.thankYouFeedbackSubmissionsAreMockOnly,
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
    );
  }
}

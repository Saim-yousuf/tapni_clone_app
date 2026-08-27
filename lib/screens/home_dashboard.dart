import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/qr_code_sheet.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/models/activity.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/stat_card.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final profile = profileProvider.profile;
    final subscription = subscriptionProvider.currentSubscription;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      profile.profilePhotoUrl != null &&
                              profile.profilePhotoUrl!.trim().isNotEmpty
                          ? Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                                image: DecorationImage(
                                  image: NetworkImage(profile.profilePhotoUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Center(
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    color: AppTheme.secondaryWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.hello,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.textGreyDark
                                  : AppTheme.textGreyLight,
                            ),
                          ),
                          Text(
                            profile.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Notification Bell Icon with Badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (leadsProvider.unreadNotificationsCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${leadsProvider.unreadNotificationsCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Expired Plan Alert
              if (subscription?.isExpired == true) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(isDark ? 0.2 : 0.08),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.planExpired,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              context.l10n.yourSubscriptionHasEndedTapTheInfoIconForDetails,
                              style: TextStyle(fontSize: 12, color: Colors.red.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text(context.l10n.planExpired),
                                ],
                              ),
                              content: Text(
                                '${context.l10n.yourPROSubscriptionHasExpired}\n\n'
                                '• ${context.l10n.premiumFeaturesAreCurrentlyDisabled}\n'
                                '• ${context.l10n.proLinksAreHiddenFromYourPublicProfile}\n'
                                '• ${context.l10n.yourBusinessDetailsAndDataAreSafe}\n\n'
                                '${context.l10n.renewYourSubscriptionToRestoreFullAccessToYourPremiumFeaturesAndData}',
                                style: TextStyle(height: 1.4),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(context.l10n.close),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => ProUpgradeSheet(),
                                    );
                                  },
                                  child: Text(context.l10n.renewPlan),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Digital Card Quick Summary Card
              GestureDetector(
                onTap: () {
                  final slug = profile.name.replaceAll(' ', '').toLowerCase();
                  SharingProfileSheet.show(context);
                },
                child: GlassCard(
                  customBgColor: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02),
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(context.l10n.activeCARD,
                                style: TextStyle(
                                  color: AppTheme.accentGold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              profile.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${profile.designation} at ${profile.company}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.textGreyDark
                                    : AppTheme.textGreyLight,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 16,
                                  color: AppTheme.accentGold,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  context.l10n.tapToShareQRCode,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Mock Card Graphic Accent
                      Container(
                        width: 70,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGold.withOpacity(0.15),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.contactless,
                            color: AppTheme.secondaryWhite,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!profileProvider.isProUser) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const ProUpgradeSheet(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Color(0xFF2C1E14), const Color(0xFF16100B)]
                            : [
                                const Color(0xFFFFF7F0),
                                const Color(0xFFFFF0E5),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Color(0xFF4C3625)
                            : Color(0xFFFFD1B3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF9500).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFF9500),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.upgradeToTapniPRO,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                context.l10n.customizeYourProfileUnlockPROTemplatesAndGetUnlimitedLeads,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _QuickOrderCard(
                      icon: Icons.receipt_long_rounded,
                      title: context.l10n.myOrders,
                      subtitle: context.l10n.trackYourOrders,
                      iconBg: const Color(0xFFCBE7F5),
                      iconColor: const Color(0xFF3B82A0),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrdersListScreen(isBusinessView: false),
                          ),
                        );
                      },
                    ),
                  ),
                  if (profileProvider.isProUser) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickOrderCard(
                        icon: Icons.storefront_rounded,
                        title: context.l10n.customerOrders,
                        subtitle: context.l10n.incomingOrders,
                        iconBg: const Color(0xFFD8F0CB),
                        iconColor: const Color(0xFF4A7C3F),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrdersListScreen(isBusinessView: true),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 28),

              // Stats Grid
              Text(
                context.l10n.performanceOverview,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
                children: [
                  StatCard(
                    title: context.l10n.views,
                    value: '${profile.viewsCount}',
                    trend: '+12%',
                    icon: Icons.visibility_outlined,
                    onTap: () {
                      profileProvider.incrementViews();
                    },
                  ),
                  StatCard(
                    title: context.l10n.qrScans,
                    value: '${profile.scansCount}',
                    trend: '+8%',
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: () {
                      profileProvider.incrementScans();
                    },
                  ),
                  StatCard(
                    title: context.l10n.contacts,
                    value: '${leadsProvider.leads.length}',
                    trend: '+24%',
                    icon: Icons.person_add_alt_1_outlined,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.recentActivity,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.seeAllActivityIsMockedNewActivitiesWillAppearAsLeadsAreAdded,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(context.l10n.seeAll,
                      style: TextStyle(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Activity Feed List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadsProvider.activities.take(4).length,
                itemBuilder: (context, index) {
                  final activity = leadsProvider.activities[index];
                  IconData icon;
                  Color color;

                  switch (activity.type) {
                    case ActivityType.view:
                      icon = Icons.visibility_outlined;
                      color = Colors.blue;
                      break;
                    case ActivityType.scan:
                      icon = Icons.qr_code_scanner_rounded;
                      color = AppTheme.accentGold;
                      break;
                    case ActivityType.lead:
                      icon = Icons.person_add_alt_1_rounded;
                      color = Colors.green;
                      break;
                    case ActivityType.share:
                      icon = Icons.share_outlined;
                      color = Colors.purple;
                      break;
                    case ActivityType.system:
                      icon = Icons.settings_suggest_rounded;
                      color = Colors.grey;
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isDark ? 0.15 : 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activity.description,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.textGreyDark
                                        : AppTheme.textGreyLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTime(activity.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white30 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _QuickOrderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickOrderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.18) : iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.listTitle.copyWith(
                  color: isDark ? Colors.white : WaUi.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WaUi.caption.copyWith(
                  color: isDark ? Colors.white60 : WaUi.secondaryText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

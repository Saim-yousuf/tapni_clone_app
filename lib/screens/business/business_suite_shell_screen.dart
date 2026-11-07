import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_feature_repo.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/banner_ads/banner_ads_plans_screen.dart';
import 'package:tapni_app/screens/booking/bookable_resources_screen.dart';
import 'package:tapni_app/screens/booking/booking_calendar_screen.dart';
import 'package:tapni_app/screens/business/business_earnings_wallet_screen.dart';
import 'package:tapni_app/screens/business/business_features_screen.dart';
import 'package:tapni_app/screens/business/business_setup_checklist_screen.dart';
import 'package:tapni_app/screens/business/staff_management_hub_screen.dart';
import 'package:tapni_app/screens/business_profile_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_settings_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_hub_screen.dart';
import 'package:tapni_app/screens/offers/business_offers_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/pos/pos_connection_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/business_feature_hub.dart';
import 'package:tapni_app/utils/business_features.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Business Suite home — 4 tabs: Earnings · Transactions · Orders · Features.
class BusinessSuiteShellScreen extends StatefulWidget {
  const BusinessSuiteShellScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<BusinessSuiteShellScreen> createState() =>
      _BusinessSuiteShellScreenState();
}

class _BusinessSuiteShellScreenState extends State<BusinessSuiteShellScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 3);
  }

  void _goTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
  }

  int _orderBadge(LeadsProvider leads) {
    return leads.notifications
        .where((n) => n['type'] == 'catalog_order' && n['isRead'] == false)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final leads = context.watch<LeadsProvider>();
    final badge = _orderBadge(leads);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            const BusinessEarningsWalletScreen(
              embedded: true,
              section: BusinessEarningsSection.dashboard,
            ),
            const BusinessEarningsWalletScreen(
              embedded: true,
              section: BusinessEarningsSection.transactions,
            ),
            const OrdersListScreen(
              isBusinessView: true,
              embedded: true,
            ),
            _SuiteFeaturesTab(
              onOpenEarnings: () => _goTab(0),
              onOpenTransactions: () => _goTab(1),
              onOpenOrders: () => _goTab(2),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SuiteBottomNav(
        index: _tab,
        ordersBadge: badge,
        onSelect: _goTab,
      ),
    );
  }
}

class _SuiteBottomNav extends StatelessWidget {
  const _SuiteBottomNav({
    required this.index,
    required this.ordersBadge,
    required this.onSelect,
  });

  final int index;
  final int ordersBadge;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE8E8E4), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _SuiteNavItem(
                  label: 'Earnings',
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights,
                  selected: index == 0,
                  onTap: () => onSelect(0),
                ),
                _SuiteNavItem(
                  label: 'Transactions',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  selected: index == 1,
                  onTap: () => onSelect(1),
                ),
                _SuiteNavItem(
                  label: 'Orders',
                  icon: Icons.shopping_bag_outlined,
                  selectedIcon: Icons.shopping_bag,
                  selected: index == 2,
                  badge: ordersBadge,
                  onTap: () => onSelect(2),
                ),
                _SuiteNavItem(
                  label: 'Features',
                  icon: Icons.apps_outlined,
                  selectedIcon: Icons.apps,
                  selected: index == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuiteNavItem extends StatelessWidget {
  const _SuiteNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : BarqodyChrome.secondaryText;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? selectedIcon : icon, size: 24, color: color),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        textAlign: TextAlign.center,
                        style: WaUi.label.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.caption.copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuiteFeaturesTab extends StatelessWidget {
  const _SuiteFeaturesTab({
    required this.onOpenEarnings,
    required this.onOpenTransactions,
    required this.onOpenOrders,
  });

  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenTransactions;
  final VoidCallback onOpenOrders;

  BusinessFeatureAccess _access(dynamic profile) {
    return BusinessFeatureAccess.fromProfile(
      businessType: profile.businessType as String?,
      businessCategory: profile.businessCategory as String?,
      enabledFeatures: (profile.enabledFeatures as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      featuresInitialized: profile.featuresInitialized as bool? ?? false,
    );
  }

  Future<void> _openMyWebsite(
    BuildContext context, {
    required String websiteType,
    String? businessType,
  }) async {
    final repo = BusinessWebsiteRepo();
    final res = await repo.getMine(websiteType: websiteType);
    if (!context.mounted) return;
    final website = res.success ? repo.parseWebsite(res.data) : null;
    if (website != null) {
      Navigator.of(context).push(
        AppPageRoute(
          builder: (_) =>
              BusinessWebsiteSettingsScreen(initialWebsite: website),
        ),
      );
      return;
    }
    final explicit = normalizeBusinessType(businessType);
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => BusinessWebsiteSetupScreen(
          websiteType: websiteType,
          businessType: explicit.isEmpty ? null : explicit,
        ),
      ),
    );
  }

  Future<bool> _ensureFeatureReady(
    BuildContext context,
    BusinessFeatureAccess access,
    String? featureKey, {
    required bool isPro,
  }) async {
    if (featureKey == null || featureKey.isEmpty) return true;
    if (access.isLocked(featureKey) ||
        (['loyalty', 'offers', 'ads', 'pos'].contains(featureKey) &&
            !isPro &&
            !access.isEnabled(featureKey))) {
      SubcriptionSheet.show(context);
      return false;
    }
    if (access.isEnabled(featureKey)) return true;
    final res = await BusinessFeatureRepo().activate(featureKey);
    if (!context.mounted) return false;
    if (!res.success) {
      final msg = res.message?.trim() ?? '';
      if (msg.toLowerCase().contains('subscription')) {
        SubcriptionSheet.show(context);
        return false;
      }
      showSnackBar(
        context,
        msg.isNotEmpty ? msg : 'Could not enable this feature',
        isError: true,
      );
      return false;
    }
    await context.read<ProfileProvider>().fetchProfile();
    return context.mounted;
  }

  Future<void> _openHubItem(
    BuildContext context, {
    required FeatureHubItem item,
    required BusinessFeatureAccess access,
    required dynamic profile,
    required String websiteType,
  }) async {
    if (!profile.isPro) {
      SubcriptionSheet.show(context);
      return;
    }

    if (item.id == 'earnings') {
      onOpenEarnings();
      return;
    }
    if (item.id == 'orders') {
      onOpenOrders();
      return;
    }

    final ready = await _ensureFeatureReady(
      context,
      access,
      item.featureKey,
      isPro: profile.isPro as bool,
    );
    if (!ready || !context.mounted) return;

    switch (item.id) {
      case 'website':
        await _openMyWebsite(
          context,
          websiteType: websiteType,
          businessType: profile.businessType as String?,
        );
        return;
      case 'calendar':
        final id = (profile.id as String?) ?? '';
        Navigator.of(context).push(
          AppPageRoute(
            builder: (_) => BookingCalendarScreen(
              businessId: id.isEmpty ? null : id,
              title: 'Business calendar',
            ),
          ),
        );
        return;
      case 'rooms':
        Navigator.of(context).push(
          AppPageRoute(
            builder: (_) => const BookableResourcesScreen(
              allowedTypes: ['room'],
              title: 'Rooms',
            ),
          ),
        );
        return;
      case 'staff':
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const StaffManagementHubScreen()),
        );
        return;
      case 'loyalty':
        final ok = await ensureBusinessProfileComplete(context);
        if (!ok || !context.mounted) return;
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const LoyaltyHubScreen()),
        );
        return;
      case 'offers':
        final ok = await ensureBusinessProfileComplete(context);
        if (!ok || !context.mounted) return;
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const BusinessOffersScreen()),
        );
        return;
      case 'ads':
        final ok = await ensureBusinessProfileComplete(context);
        if (!ok || !context.mounted) return;
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const BannerAdsPlansScreen()),
        );
        return;
      case 'pos':
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const PosConnectionScreen()),
        );
        return;
      case 'features':
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const BusinessFeaturesScreen()),
        );
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final access = _access(profile);
    final websiteType = websiteTypeForBusinessType(access.businessType);
    final completeness = BusinessCompleteness.fromProfile(profile);
    final allItems = [
      ...frequentHubItems(access.businessType),
      ...moreHubItems(access.businessType),
    ];
    // De-dupe by id while keeping order.
    final seen = <String>{};
    final items = <FeatureHubItem>[];
    for (final item in allItems) {
      if (seen.add(item.id)) items.add(item);
    }

    return ColoredBox(
      color: WaUi.toolsScaffold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BarqodyTitleBar(
            title: 'Features',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (!profile.isPro) ...[
                  WaSectionHeader(context.l10n.forYou),
                  WaForYouCard(
                    title: context.l10n.tryBusinessPro2,
                    description: context.l10n.unlockBusinessProDescription,
                    buttonLabel: context.l10n.tryBusinessPro,
                    onTap: () => SubcriptionSheet.show(context),
                  ),
                ],
                const WaSectionHeader('Business setup'),
                WaToolsListTile(
                  icon: Icons.checklist_outlined,
                  title: 'Setup Checklist',
                  subtitle:
                      '${businessTypeLabel(access.businessType)} · guided setup',
                  onTap: () {
                    if (!profile.isPro) {
                      SubcriptionSheet.show(context);
                      return;
                    }
                    Navigator.of(context).push(
                      AppPageRoute(
                        builder: (_) => const BusinessSetupChecklistScreen(),
                      ),
                    );
                  },
                ),
                WaToolsListTile(
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
                      AppPageRoute(
                        builder: (_) => const BusinessProfileScreen(),
                      ),
                    );
                  },
                ),
                WaToolsListTile(
                  icon: Icons.tune_outlined,
                  title: 'Feature settings',
                  subtitle: 'Turn optional modules on or off',
                  onTap: () {
                    if (!profile.isPro) {
                      SubcriptionSheet.show(context);
                      return;
                    }
                    Navigator.of(context).push(
                      AppPageRoute(
                        builder: (_) => const BusinessFeaturesScreen(),
                      ),
                    );
                  },
                ),
                WaToolsListTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transactions',
                  subtitle: 'Payments and refunds ledger',
                  onTap: () {
                    if (!profile.isPro) {
                      SubcriptionSheet.show(context);
                      return;
                    }
                    onOpenTransactions();
                  },
                ),
                const WaSectionHeader('All features'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Everything available for '
                    '${businessTypeLabel(access.businessType)}.',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                      height: 1.35,
                    ),
                  ),
                ),
                ...items.map(
                  (item) => WaToolsListTile(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.recommended
                        ? '${item.subtitle}\nRecommended for your type'
                        : item.subtitle,
                    onTap: () => _openHubItem(
                      context,
                      item: item,
                      access: access,
                      profile: profile,
                      websiteType: websiteType,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

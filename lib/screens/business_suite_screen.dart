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
import 'package:tapni_app/screens/business/business_feature_more_screen.dart';
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
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/business_feature_hub.dart';
import 'package:tapni_app/utils/business_features.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Modular Feature Hub — frequent tools first, More Features for the rest.
/// Business type orders recommendations; it does not block access.
class BusinessSuiteScreen extends StatelessWidget {
  const BusinessSuiteScreen({super.key});

  int _catalogOrderBadge(LeadsProvider leadsProvider) {
    return leadsProvider.notifications
        .where((n) => n['type'] == 'catalog_order' && n['isRead'] == false)
        .length;
  }

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
        MaterialPageRoute(
          builder: (_) =>
              BusinessWebsiteSettingsScreen(initialWebsite: website),
        ),
      );
      return;
    }
    final explicit = normalizeBusinessType(businessType);
    Navigator.of(context).push(
      MaterialPageRoute(
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
    // Open access: activate optional feature on first use (no type block).
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
    required int orderBadge,
  }) async {
    if (!profile.isPro) {
      SubcriptionSheet.show(context);
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
      case 'orders':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OrdersListScreen(isBusinessView: true),
          ),
        );
        return;
      case 'website':
        await _openMyWebsite(
          context,
          websiteType: websiteType,
          businessType: profile.businessType as String?,
        );
        return;
      case 'earnings':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BusinessEarningsWalletScreen(),
          ),
        );
        return;
      case 'calendar':
        final id = (profile.id as String?) ?? '';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingCalendarScreen(
              businessId: id.isEmpty ? null : id,
              title: 'Business calendar',
            ),
          ),
        );
        return;
      case 'rooms':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BookableResourcesScreen(
              allowedTypes: ['room'],
              title: 'Rooms',
            ),
          ),
        );
        return;
      case 'staff':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const StaffManagementHubScreen(),
          ),
        );
        return;
      case 'loyalty':
        final ok = await ensureBusinessProfileComplete(context);
        if (!ok || !context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoyaltyHubScreen()),
        );
        return;
      case 'offers':
        final ok = await ensureBusinessProfileComplete(context);
        if (!ok || !context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BusinessOffersScreen()),
        );
        return;
      case 'ads':
        final ok = await ensureBusinessProfileComplete(context);
        if (!ok || !context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BannerAdsPlansScreen()),
        );
        return;
      case 'pos':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PosConnectionScreen()),
        );
        return;
      case 'features':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BusinessFeaturesScreen(),
          ),
        );
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final orderBadge = _catalogOrderBadge(leadsProvider);
    final completeness = BusinessCompleteness.fromProfile(profile);
    final access = _access(profile);
    final websiteType = websiteTypeForBusinessType(access.businessType);
    final frequent = frequentHubItems(access.businessType);
    final moreCount = moreHubItems(access.businessType).length;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Business Suite'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
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
                  WaSectionHeader('Business setup'),
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
                        MaterialPageRoute(
                          builder: (_) =>
                              const BusinessSetupChecklistScreen(),
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
                        MaterialPageRoute(
                          builder: (_) => const BusinessProfileScreen(),
                        ),
                      );
                    },
                  ),
                  WaSectionHeader('Frequently used'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Ordered for ${businessTypeLabel(access.businessType)}. '
                      'Every module stays available under More Features.',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ),
                  ...frequent.map(
                    (item) => WaToolsListTile(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      showBadge: item.id == 'orders' && orderBadge > 0,
                      onTap: () => _openHubItem(
                        context,
                        item: item,
                        access: access,
                        profile: profile,
                        websiteType: websiteType,
                        orderBadge: orderBadge,
                      ),
                    ),
                  ),
                  WaSectionHeader('More'),
                  WaToolsListTile(
                    icon: Icons.apps_outlined,
                    title: 'More Features',
                    subtitle: '$moreCount modules · loyalty, offers, staff, ads…',
                    onTap: () {
                      if (!profile.isPro) {
                        SubcriptionSheet.show(context);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BusinessFeatureMoreScreen(
                            businessType: access.businessType,
                            onOpenItem: (item) => _openHubItem(
                              context,
                              item: item,
                              access: access,
                              profile: profile,
                              websiteType: websiteType,
                              orderBadge: orderBadge,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

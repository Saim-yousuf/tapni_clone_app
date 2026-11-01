import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/attendance/business/attendance_dashboard_screen.dart';
import 'package:tapni_app/screens/banner_ads/banner_ads_plans_screen.dart';
import 'package:tapni_app/screens/booking/bookable_resources_screen.dart';
import 'package:tapni_app/screens/booking/booking_calendar_screen.dart';
import 'package:tapni_app/screens/business_profile_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_guide_sheet.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_hub_screen.dart';
import 'package:tapni_app/screens/offers/business_offers_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/screens/pos/pos_connection_screen.dart';
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Business-only tools hub. Customer tools stay on the main Tools screen.
class BusinessSuiteScreen extends StatelessWidget {
  const BusinessSuiteScreen({super.key});

  int _catalogOrderBadge(LeadsProvider leadsProvider) {
    return leadsProvider.notifications
        .where((n) => n['type'] == 'catalog_order' && n['isRead'] == false)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final orderBadge = _catalogOrderBadge(leadsProvider);
    final completeness = BusinessCompleteness.fromProfile(profile);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: 'Business Suite'),
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
                  WaSectionHeader(context.l10n.businessDetails),
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
                  if (profile.isPro) ...[
                    WaSectionHeader(context.l10n.growYourBusiness),
                    WaToolsListTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Guides',
                      subtitle:
                          'Business guide (your site) + Customer guide (ordering & rewards)',
                      onTap: () => showBusinessWebsiteSetupGuide(context),
                    ),
                    WaToolsListTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders & Bookings',
                      subtitle:
                          'Orders, appointments, and stays from customers',
                      showBadge: orderBadge > 0,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const OrdersListScreen(isBusinessView: true),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.groups_outlined,
                      title: context.l10n.teamAttendance,
                      subtitle: context
                          .l10n.inviteEmployeesSetShiftsAndTrackPresence,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            settings: const RouteSettings(
                              name: AttendanceDashboardScreen.routeName,
                            ),
                            builder: (_) => const AttendanceDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.event_available_outlined,
                      title: 'Booking calendar',
                      subtitle:
                          'Busy times only — appointments, stays & tables',
                      onTap: () {
                        final id = profile.id ?? '';
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingCalendarScreen(
                              businessId: id.isEmpty ? null : id,
                              title: 'Business calendar',
                            ),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.meeting_room_outlined,
                      title: 'Rooms & tables',
                      subtitle:
                          'Hotel rooms, restaurant tables & bookable assets',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BookableResourcesScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.point_of_sale_outlined,
                      title: 'POS connect',
                      subtitle:
                          'Push Barqody orders to Foodics / kitchen POS',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PosConnectionScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.stars_outlined,
                      title: context.l10n.loyaltyPrograms,
                      subtitle: context
                          .l10n.createStampOrPointsRewardsForCustomers,
                      onTap: () async {
                        final ok =
                            await ensureBusinessProfileComplete(context);
                        if (!ok || !context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoyaltyHubScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Offers & Coupons',
                      subtitle:
                          'Create discounts customers can apply at checkout',
                      onTap: () async {
                        final ok =
                            await ensureBusinessProfileComplete(context);
                        if (!ok || !context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BusinessOffersScreen(),
                          ),
                        );
                      },
                    ),
                    WaToolsListTile(
                      icon: Icons.campaign_outlined,
                      title: 'Banner Ads',
                      subtitle:
                          'Promote your business on the Explore carousel',
                      onTap: () async {
                        final ok =
                            await ensureBusinessProfileComplete(context);
                        if (!ok || !context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BannerAdsPlansScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

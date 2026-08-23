import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/business_card.dart';
import 'package:tapni_app/widgets/curved_bottom_nav.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool showBackButton;
  const AnalyticsScreen({super.key, this.showBackButton = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  int _totalProfileViews = 0;
  int _totalCardScans = 0;
  List<dynamic> _profileViews = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final response = await AuthRepo().getAnalytics();
      if (!mounted) return;
      if (response.success && response.data != null) {
        final analytics = response.data['analytics'];
        setState(() {
          _totalProfileViews = analytics['totalProfileViews'] ?? 0;
          _totalCardScans = analytics['totalCardScans'] ?? 0;
          _profileViews = analytics['profileViews'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat(context.l10n.mmmDYyyyHMmA).format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final bottomPad = CurvedBottomNav.fabOverhang() + 16;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.l10n.analyticsDashboard,
          style: WaUi.toolsTitle,
        ),
        titleTextStyle: WaUi.toolsTitle,
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: widget.showBackButton,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: WaUi.buttonDark,
        actions: [NotificationIconButton()],
      ),
      body: !profile.isPro
          ? BusinessOnlyCard()
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: WaUi.buttonDark),
                )
              : RefreshIndicator(
                  color: WaUi.buttonDark,
                  onRefresh: _fetchAnalytics,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.remove_red_eye_outlined,
                              label: context.l10n.profileViews,
                              value: '$_totalProfileViews',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.qr_code_2_rounded,
                              label: context.l10n.qrScans,
                              value: '$_totalCardScans',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.l10n.profileViewers,
                        style: WaUi.sectionHeader,
                      ),
                      const SizedBox(height: 12),
                      if (_profileViews.isEmpty)
                        const _ViewersEmptyState()
                      else
                        ...List.generate(_profileViews.length, (index) {
                          final view = _profileViews[index];
                          final isGuest = view['isGuest'] ?? true;
                          final viewer = view['viewerId'];
                          final timestamp = view['timestamp'] != null
                              ? _formatDate(view['timestamp'])
                              : '';

                          var title = context.l10n.guestUser;
                          var subtitle = timestamp;

                          if (!isGuest && viewer != null) {
                            title =
                                viewer['name'] ?? context.l10n.unknownUser;
                            if (viewer['username'] != null) {
                              subtitle =
                                  '@${viewer['username']} • $timestamp';
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ViewerTile(
                              title: title,
                              subtitle: subtitle,
                              isGuest: isGuest,
                              photoUrl: viewer?['profilePhoto'] as String?,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: WaUi.searchBg,
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
        border: Border.all(color: WaUi.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WaUi.divider),
            ),
            child: Icon(icon, size: 22, color: WaUi.buttonDark),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: WaUi.caption.copyWith(
              color: WaUi.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WaUi.toolsTitleOf(
              size: 28,
              weight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isGuest;
  final String? photoUrl;

  const _ViewerTile({
    required this.title,
    required this.subtitle,
    required this.isGuest,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: WaUi.searchBg,
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: WaUi.navPill,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child: hasPhoto
                ? null
                : Icon(
                    isGuest ? Icons.person_outline_rounded : Icons.person,
                    color: WaUi.secondaryText,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WaUi.listTitle),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: WaUi.caption.copyWith(fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(WaUi.radiusPill),
              border: Border.all(color: WaUi.chipBorder),
            ),
            child: Text(
              isGuest ? context.l10n.guest : context.l10n.user,
              style: WaUi.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WaUi.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewersEmptyState extends StatelessWidget {
  const _ViewersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: WaUi.searchBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insights_outlined,
              size: 36,
              color: WaUi.secondaryText.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.noOneHasViewedYourProfileYet,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(color: WaUi.secondaryText, height: 1.4),
          ),
        ],
      ),
    );
  }
}

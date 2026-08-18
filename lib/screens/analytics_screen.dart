import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/business_card.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/repository/auth_repo.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

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
      final repo = AuthRepo();
      final response = await repo.getAnalytics();
      if (response.success && response.data != null) {
        final analytics = response.data['analytics'];
        if (mounted) {
          setState(() {
            _totalProfileViews = analytics['totalProfileViews'] ?? 0;
            _totalCardScans = analytics['totalCardScans'] ?? 0;
            _profileViews = analytics['profileViews'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // format date
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat(context.l10n.mmmDYyyyHMmA).format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildViewerAvatar(dynamic viewer) {
    if (viewer == null ||
        viewer['profilePhoto'] == null ||
        viewer['profilePhoto'].isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }
    return CircleAvatar(backgroundImage: NetworkImage(viewer['profilePhoto']));
  }

  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profile = Provider.of<ProfileProvider>(context).profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.analyticsDashboard),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [NotificationIconButton()],
      ),
      body: !profile.isPro
          ? BusinessOnlyCard()
          : _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview stats
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.remove_red_eye_rounded,
                                  color: AppTheme.accentGold,
                                  size: 28,
                                ),
                                SizedBox(height: 12),
                                Text(context.l10n.profileViews,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$_totalProfileViews',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: GlassCard(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                                SizedBox(height: 12),
                                Text(context.l10n.qrScans,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$_totalCardScans',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),

                    Text(
                      context.l10n.profileViewers,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    if (_profileViews.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            context.l10n.noOneHasViewedYourProfileYet,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _profileViews.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final view = _profileViews[index];
                          final isGuest = view['isGuest'] ?? true;
                          final viewer = view['viewerId'];
                          final timestamp = view['timestamp'] != null
                              ? _formatDate(view['timestamp'])
                              : '';

                          String title = context.l10n.guestUser;
                          String subtitle = timestamp;

                          if (!isGuest && viewer != null) {
                            title = viewer['name'] ?? context.l10n.unknownUser;
                            if (viewer['username'] != null) {
                              subtitle = '@${viewer['username']} • $timestamp';
                            }
                          }

                          return GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _buildViewerAvatar(viewer),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isGuest)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(context.l10n.guest,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(context.l10n.user,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

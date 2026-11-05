import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/connectivity_provider.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/profile_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/services/contacts_sync_service.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/services/device_session_guard.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/release_features.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/curved_bottom_nav.dart';
import 'package:tapni_app/widgets/profile_photo_avatar.dart';

class MainShell extends StatefulWidget {
  final String? currentPage;
  const MainShell({super.key, this.currentPage});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Links = SocialLinksScreen (replaces Explore for personal-card release).
  /// Analytics sits before Settings. CurvedBottomNav requires exactly 4 items.
  static const _navPages = ['Links', 'Contacts', 'Analytics', 'Settings'];

  /// IndexedStack order: nav tabs (0–3) + My Card (4).
  static const _profileStackIndex = 4;

  late String _currentPage;
  int _navIndex = 0;
  bool _contactsPromptShown = false;
  int _lastReconnectTick = 0;
  late final PageController _pageController;
  /// Bumped whenever My Card becomes the active page so sheet enter replays.
  int _profileSheetEnterNonce = 0;

  bool get _onProfile => _currentPage == 'My Card';

  int get _stackIndex => _onProfile ? _profileStackIndex : _navIndex;

  @override
  void initState() {
    super.initState();
    final requested = widget.currentPage;
    if (requested == 'Explore') {
      // Legacy callers still pass Explore; map to Links for this release.
      _currentPage = ReleaseFeatures.canOpenExplore ? 'Explore' : 'Links';
    } else if (requested == 'Find') {
      _currentPage = 'Links';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const FindUserScreen(isTab: false)),
        );
      });
    } else {
      _currentPage = requested ?? 'My Card';
    }
    final index = _navPages.indexOf(_currentPage);
    _navIndex = index >= 0 ? index : 0;
    _pageController = PageController(initialPage: _stackIndex);
    DeviceSessionGuard.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // First landing on My Card — trigger sheet enter after shell is visible.
      if (_onProfile) {
        setState(() => _profileSheetEnterNonce++);
      }
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      profileProvider.refreshLocalProfile();
      if (!profileProvider.hasLoadedProfile && !profileProvider.isLoading) {
        unawaited(profileProvider.fetchProfile());
      }
      _loadCatalogNotifications();
      await _maybePromptContactsSync();
      await CallerIdService.ensureDefaultEnabled();
    });
  }

  Future<void> _maybePromptContactsSync() async {
    if (!ContactsSyncService.isFeatureEnabled) return;
    if (!mounted || _contactsPromptShown) return;
    final userId =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).activeAccount?.userId ??
        '';
    if (userId.isEmpty || ContactsSyncService.wasPrompted(userId)) return;
    _contactsPromptShown = true;
    await Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const ContactsSyncScreen()));
  }

  void _loadCatalogNotifications() {
    if (!mounted) return;
    if (!ReleaseFeatures.canUseShopping && !ReleaseFeatures.canShowBusinessSuite) {
      return;
    }
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);
    leadsProvider.refreshNotifications(
      isBusinessUser: profileProvider.isProUser,
    );
  }

  Widget _wrapTab(Widget child, {required bool coverUnderStatusBar}) {
    return _KeepAliveTab(
      child: SafeArea(
        top: !coverUnderStatusBar,
        bottom: false,
        child: child,
      ),
    );
  }

  void _animateToPage(int page) {
    if (!_pageController.hasClients) return;
    if ((_pageController.page ?? _pageController.initialPage).round() == page) {
      return;
    }
    unawaited(
      _pageController.animateToPage(
        page,
        duration: AppMotion.tab,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _switchTab(String page) {
    Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    ).resetBannerForRoute();
    final index = _navPages.indexOf(page);
    setState(() {
      _currentPage = page;
      if (index >= 0) _navIndex = index;
    });
    if (index >= 0) _animateToPage(index);
    Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).setEditingProfile(false);
  }

  void _goToProfile() {
    Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    ).resetBannerForRoute();
    setState(() {
      _currentPage = 'My Card';
      _profileSheetEnterNonce++;
    });
    _animateToPage(_profileStackIndex);
    Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).setEditingProfile(false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCenterButtonTap() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    if (profileProvider.isEditingProfile) {
      profileProvider.triggerSave();
      return;
    }
    if (_onProfile) {
      Navigator.of(
        context,
      ).push(AppPageRoute(builder: (_) => const ScanScreen()));
      return;
    }
    _goToProfile();
  }

  CurvedNavItem _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final highlight = !_onProfile;
    return CurvedNavItem(
      icon: icon,
      selectedIcon: highlight ? selectedIcon : icon,
      label: label,
      selectedColor: highlight ? selectedColor : unselectedColor,
      unselectedColor: unselectedColor,
    );
  }

  Widget _buildCenterFab({
    required bool isEditing,
    required Color fabBg,
    required Color fabFg,
    required String name,
    required String? photoUrl,
  }) {
    const fabSize = 74.0;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    Widget child;
    if (isEditing) {
      child = Icon(
        Icons.check_rounded,
        key: const ValueKey('fab-edit'),
        size: fabSize * 0.45,
        color: fabFg,
      );
    } else if (_onProfile) {
      child = Icon(
        Icons.qr_code_scanner_rounded,
        key: const ValueKey('fab-scan'),
        size: fabSize * 0.45,
        color: fabFg,
      );
    } else if (hasPhoto) {
      child = SizedBox.expand(
        key: ValueKey('fab-photo-$photoUrl'),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          errorWidget: (_, _, _) => _fabInitials(name, fabFg),
          placeholder: (_, _) => const ColoredBox(color: Color(0xFF2C2C2E)),
        ),
      );
    } else {
      child = KeyedSubtree(
        key: const ValueKey('fab-avatar'),
        child: BarqodyProfilePhoto.placeholder(),
      );
    }

    return CurvedNavCenterButton(
      onPressed: _onCenterButtonTap,
      size: fabSize,
      backgroundColor: fabBg,
      foregroundColor: fabFg,
      child: child,
    );
  }

  Widget _fabInitials(String name, Color color) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Center(
        child: Icon(
          Icons.person_rounded,
          size: 34,
          color: color,
        ),
      );
    }
    return Center(
      child: Text(
        trimmed[0].toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _fabDisplayName({
    required String profileName,
    required String profileEmail,
    String? profileUsername,
    String? accountName,
    String? accountUsername,
    String? accountEmail,
  }) {
    for (final candidate in [
      profileName,
      accountName ?? '',
      profileUsername ?? '',
      accountUsername ?? '',
    ]) {
      final trimmed = candidate.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    final email = profileEmail.trim().isNotEmpty
        ? profileEmail.trim()
        : (accountEmail?.trim() ?? '');
    if (email.isNotEmpty) return email.split('@').first;
    return '';
  }

  String? _fabPhotoUrl(String? profilePhoto, String? accountPhoto) {
    final fromProfile = profilePhoto?.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    final fromAccount = accountPhoto?.trim() ?? '';
    return fromAccount.isNotEmpty ? fromAccount : null;
  }

  Future<void> _refreshAfterReconnect() async {
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final leadsProvider = Provider.of<LeadsProvider>(
      context,
      listen: false,
    );
    await Future.wait([
      profileProvider.fetchProfile(),
      profileProvider.fetchLinkCatalog(),
      leadsProvider.fetchLeads(),
      leadsProvider.fetchCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final reconnectTick =
        context.select<ConnectivityProvider, int>((c) => c.reconnectTick);
    if (reconnectTick != _lastReconnectTick) {
      _lastReconnectTick = reconnectTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshAfterReconnect());
      });
    }

    // Primitive selects — shell chrome rebuilds only when FAB-relevant data changes.
    final isEditing =
        context.select<ProfileProvider, bool>((p) => p.isEditingProfile);
    final profileName =
        context.select<ProfileProvider, String>((p) => p.profile.name);
    final profilePhoto = context.select<ProfileProvider, String?>(
      (p) => p.profile.profilePhotoUrl,
    );
    final profileEmail =
        context.select<ProfileProvider, String>((p) => p.profile.email);
    final profileUsername = context.select<ProfileProvider, String?>(
      (p) => p.profile.username,
    );
    final accountName =
        context.select<AuthProvider, String?>((a) => a.activeAccount?.name);
    final accountPhoto = context.select<AuthProvider, String?>(
      (a) => a.activeAccount?.profilePhoto,
    );
    final accountUsername = context.select<AuthProvider, String?>(
      (a) => a.activeAccount?.username,
    );
    final accountEmail =
        context.select<AuthProvider, String?>((a) => a.activeAccount?.email);

    final fabName = _fabDisplayName(
      profileName: profileName,
      profileEmail: profileEmail,
      profileUsername: profileUsername,
      accountName: accountName,
      accountUsername: accountUsername,
      accountEmail: accountEmail,
    );
    final fabPhoto = _fabPhotoUrl(profilePhoto, accountPhoto);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = const Color(0xFF8E8E93);
    final barColor = isDark ? Colors.black : Colors.white;
    final fabBg = isDark ? Colors.white : Colors.black;
    final fabFg = isDark ? Colors.black : Colors.white;
    final l10n = context.l10n;

    // My Card (view + edit): cover draws under the status bar.
    final coverUnderStatusBar = _onProfile;
    final systemUi = AppTheme.systemUiFor(Theme.of(context).brightness);
    final overlayStyle = coverUnderStatusBar
        ? systemUi.copyWith(statusBarColor: Colors.transparent)
        : systemUi;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: _onProfile && !isEditing,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (isEditing) {
            final profileProvider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            profileProvider.setEditingProfile(false);
            profileProvider.onSaveTriggered = null;
            return;
          }
          if (_onProfile) return;
          _goToProfile();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: WaUi.toolsScaffold,
          body: Stack(
            children: [
              Positioned.fill(
                // Visible horizontal slide between tabs (PageView).
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  allowImplicitScrolling: true,
                  children: [
                    _wrapTab(
                      const SocialLinksScreen(isTab: true),
                      coverUnderStatusBar: false,
                    ),
                    _wrapTab(
                      const LeadsScreen(),
                      coverUnderStatusBar: false,
                    ),
                    _wrapTab(
                      const AnalyticsScreen(),
                      coverUnderStatusBar: false,
                    ),
                    _wrapTab(
                      const SettingsScreen(),
                      coverUnderStatusBar: false,
                    ),
                    _wrapTab(
                      ProfileScreen(
                        sheetEnterNonce: _profileSheetEnterNonce,
                      ),
                      coverUnderStatusBar: true,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: CurvedBottomNav(
                  backgroundColor: barColor,
                  currentIndex: _navIndex,
                  onTap: (index) {
                    if (index < 0 || index >= _navPages.length) return;
                    _switchTab(_navPages[index]);
                  },
                  items: [
                    _navItem(
                      icon: Icons.link_outlined,
                      selectedIcon: Icons.link_rounded,
                      label: l10n.links,
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                    ),
                    _navItem(
                      icon: Icons.people_outline,
                      selectedIcon: Icons.people,
                      label: l10n.contacts,
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                    ),
                    _navItem(
                      icon: Icons.insights_outlined,
                      selectedIcon: Icons.insights,
                      label: 'Analytics',
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                    ),
                    _navItem(
                      icon: Icons.storefront_outlined,
                      selectedIcon: Icons.storefront,
                      label: l10n.tools,
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                    ),
                  ],
                  centerButton: _buildCenterFab(
                    isEditing: isEditing,
                    fabBg: fabBg,
                    fabFg: fabFg,
                    name: fabName,
                    photoUrl: fabPhoto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps each PageView tab alive so switching doesn't reload content.
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

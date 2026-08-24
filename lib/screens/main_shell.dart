import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/explore_screen.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/profile_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/services/contacts_sync_service.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/services/device_session_guard.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/curved_bottom_nav.dart';

class MainShell extends StatefulWidget {
  final String? currentPage;
  const MainShell({super.key, this.currentPage});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Explore = marketplace home. Analytics restored on 4th nav slot (before Settings).
  static const _navPages = ['Explore', 'Contacts', 'Analytics', 'Settings'];

  late String _currentPage;
  int _navIndex = 0;
  bool _contactsPromptShown = false;

  bool get _onProfile => _currentPage == 'My Card';

  @override
  void initState() {
    super.initState();
    final requested = widget.currentPage;
    if (requested == 'Links') {
      _currentPage = 'Explore';
    } else if (requested == 'Find') {
      _currentPage = 'Explore';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FindUserScreen(isTab: false),
          ),
        );
      });
    } else {
      _currentPage = requested ?? 'My Card';
    }
    final index = _navPages.indexOf(_currentPage);
    _navIndex = index >= 0 ? index : 0;
    DeviceSessionGuard.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCatalogNotifications();
      await _maybePromptContactsSync();
      await CallerIdService.ensureDefaultEnabled();
    });
  }

  Future<void> _maybePromptContactsSync() async {
    if (!ContactsSyncService.isFeatureEnabled) return;
    if (!mounted || _contactsPromptShown) return;
    final userId =
        Provider.of<AuthProvider>(context, listen: false).activeAccount?.userId ??
            '';
    if (userId.isEmpty || ContactsSyncService.wasPrompted(userId)) return;
    _contactsPromptShown = true;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContactsSyncScreen()),
    );
  }

  void _loadCatalogNotifications() {
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);
    leadsProvider.refreshNotifications(
      isBusinessUser: profileProvider.isProUser,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentPage) {
      case 'Explore':
        return const ExploreScreen();
      case 'My Card':
        return const ProfileScreen();
      case 'Contacts':
        return const LeadsScreen();
      case 'Analytics':
        return const AnalyticsScreen();
      case 'Settings':
        return const SettingsScreen();
      default:
        return const ExploreScreen();
    }
  }

  void _switchTab(String page) {
    setState(() {
      _currentPage = page;
      final index = _navPages.indexOf(page);
      if (index >= 0) _navIndex = index;
    });
    Provider.of<ProfileProvider>(context, listen: false).setEditingProfile(false);
  }

  void _goToProfile() {
    setState(() => _currentPage = 'My Card');
    Provider.of<ProfileProvider>(context, listen: false).setEditingProfile(false);
  }

  void _onCenterButtonTap() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.isEditingProfile) {
      profileProvider.triggerSave();
      return;
    }
    if (_onProfile) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
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
        key: const ValueKey('fab-photo'),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => _fabInitials(name, fabFg),
          loadingBuilder: (context, image, progress) {
            if (progress == null) return image;
            return _fabInitials(name, fabFg);
          },
        ),
      );
    } else {
      child = KeyedSubtree(
        key: const ValueKey('fab-initials'),
        child: _fabInitials(name, fabFg),
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
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: color,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final isEditing = profileProvider.isEditingProfile;
    final profile = profileProvider.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = const Color(0xFF8E8E93);
    final barColor = isDark ? Colors.black : Colors.white;
    final fabBg = isDark ? Colors.white : Colors.black;
    final fabFg = isDark ? Colors.black : Colors.white;
    final l10n = context.l10n;
    final navClearance = CurvedBottomNav.contentClearance(context);

    return PopScope(
      canPop: _onProfile,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _onProfile) return;
        _goToProfile();
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: WaUi.toolsScaffold,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              // Keep every tab's content above the curved bar + center button.
              padding: EdgeInsets.only(bottom: navClearance),
              child: SafeArea(
                bottom: false,
                child: _buildCurrentScreen(),
              ),
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
                  icon: Icons.travel_explore_outlined,
                  selectedIcon: Icons.travel_explore_rounded,
                  label: l10n.explore,
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
                name: profile.name,
                photoUrl: profile.profilePhotoUrl,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

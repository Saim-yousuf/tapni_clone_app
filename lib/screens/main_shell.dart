import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/profile_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/screens/caller_id_setup_screen.dart';
import 'package:tapni_app/services/contacts_sync_service.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/services/device_session_guard.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class MainShell extends StatefulWidget {
  final String? _currentPage;
  const MainShell({Key? key, this._currentPage}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _navPages = ['Links', 'Contacts', 'Explore', 'Settings'];

  String? _currentPage;
  int _navIndex = 0;
  bool _contactsPromptShown = false;
  @override
  void initState() {
    _currentPage = widget._currentPage ?? 'My Card';
    super.initState();
    DeviceSessionGuard.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCatalogNotifications();
      await _maybePromptContactsSync();
      await CallerIdService.ensureDefaultEnabled();
      await _maybePromptCallerId();
    });
  }

  Future<void> _maybePromptContactsSync() async {
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

  Future<void> _maybePromptCallerId() async {
    if (!mounted || !CallerIdService.isSupported) return;
    if (!CallerIdService.isEnabled) return;
    if (CallerIdService.wasPermissionPrompted) return;
    if (await CallerIdService.hasAllPermissions()) {
      await CallerIdService.syncNative();
      return;
    }
    await CallerIdService.markPermissionPrompted();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallerIdSetupScreen()),
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
      case 'Links':
        return const SocialLinksScreen(isTab: true);
        // return const HomeDashboard();

      case 'My Card':
        return const ProfileScreen();
      case 'Contacts':
        return const LeadsScreen();
      case 'Explore':
        return const AnalyticsScreen();
      case 'Settings':
        return const SettingsScreen();
      default:
        return const SocialLinksScreen(isTab: true);
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

  void _onCenterButtonTap() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.isEditingProfile) {
      profileProvider.triggerSave();
      return;
    }
    if (_currentPage == 'My Card') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
      return;
    }
    setState(() => _currentPage = 'My Card');
  }

  Widget _buildCenterFab({
    required bool isEditing,
    required Color fabBg,
    required Color fabFg,
    required String name,
    required String? photoUrl,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    Widget child;
    if (isEditing) {
      child = Icon(Icons.check_rounded, size: 38, color: fabFg);
    } else if (_currentPage == 'My Card') {
      child = Icon(Icons.qr_code_scanner_rounded, size: 38, color: fabFg);
    } else if (hasPhoto) {
      child = SizedBox.expand(
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) => _fabInitials(name, fabFg),
          loadingBuilder: (context, image, progress) {
            if (progress == null) return image;
            return _fabInitials(name, fabFg);
          },
        ),
      );
    } else {
      child = _fabInitials(name, fabFg);
    }

    return SizedBox(
      width: 80,
      height: 80,
      child: FloatingActionButton(
        heroTag: 'tapni_main_fab',
        onPressed: _onCenterButtonTap,
        elevation: 6,
        highlightElevation: 8,
        backgroundColor: fabBg,
        foregroundColor: fabFg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _fabInitials(String name, Color color) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: color,
          fontSize: 34,
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
    final l10n = context.l10n;
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = const Color(0xFF8E8E93);
    final barColor = isDark ? Colors.black : Colors.white;
    final fabBg = isDark ? Colors.white : Colors.black;
    final fabFg = isDark ? Colors.black : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        bottom: false,
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: StylishBottomBar(
        option: AnimatedBarOptions(
          iconStyle: IconStyle.Default,
          barAnimation: BarAnimation.fade,
          opacity: 0.12,
        ),
        items: [
          BottomBarItem(
            icon: const Icon(Icons.link_outlined),
            selectedIcon: const Icon(Icons.link),
            selectedColor: selectedColor,
            unSelectedColor: unselectedColor,
            title: Text(l10n.links),
          ),
          BottomBarItem(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            selectedColor: selectedColor,
            unSelectedColor: unselectedColor,
            title: Text(l10n.contacts),
          ),
          BottomBarItem(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            selectedColor: selectedColor,
            unSelectedColor: unselectedColor,
            title: Text(l10n.explore),
          ),
          BottomBarItem(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            selectedColor: selectedColor,
            unSelectedColor: unselectedColor,
            title: Text(l10n.tools),
          ),
        ],
        backgroundColor: barColor,
        elevation: 8,
        currentIndex: _navIndex,
        hasNotch: true,
        fabLocation: StylishBarFabLocation.center,
        notchStyle: NotchStyle.circle,
        onTap: (index) {
          if (index < 0 || index >= _navPages.length) return;
          _switchTab(_navPages[index]);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: _buildCenterFab(
        isEditing: isEditing,
        fabBg: fabBg,
        fabFg: fabFg,
        name: profile.name,
        photoUrl: profile.profilePhotoUrl,
      ),
    );
  }
}

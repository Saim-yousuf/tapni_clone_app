import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/profile_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class MainShell extends StatefulWidget {
  final String? _currentPage;
  const MainShell({Key? key, this._currentPage}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String? _currentPage;
  @override
  void initState() {
    _currentPage = widget._currentPage ?? 'My Card';
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalogNotifications());
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
    setState(() => _currentPage = page);
    Provider.of<ProfileProvider>(context, listen: false).setEditingProfile(false);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final isEditing = profileProvider.isEditingProfile;
    final profile = profileProvider.profile;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        bottom: false,
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: WaUi.navBarBg,
            border: Border(top: BorderSide(color: WaUi.divider, width: 0.5)),
          ),
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                WaBottomNavItem(
                  icon: Icons.link_outlined,
                  selectedIcon: Icons.link,
                  label: context.l10n.links,
                  selected: _currentPage == 'Links',
                  onTap: () => _switchTab('Links'),
                ),
                WaBottomNavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: context.l10n.contacts,
                  selected: _currentPage == 'Contacts',
                  onTap: () => _switchTab('Contacts'),
                ),
                SizedBox(width: 72),
                WaBottomNavItem(
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights,
                  label: context.l10n.explore,
                  selected: _currentPage == 'Explore',
                  onTap: () => _switchTab('Explore'),
                ),
                WaBottomNavItem(
                  icon: Icons.storefront_outlined,
                  selectedIcon: Icons.storefront,
                  label: context.l10n.tools,
                  selected: _currentPage == 'Settings',
                  showDot: leadsProvider.unreadNotificationsCount > 0,
                  onTap: () => _switchTab('Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: isEditing
            ? ClipOval(
                child: InkWell(
                  onTap: () {
                    profileProvider.triggerSave();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlack,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : _currentPage == "My Card"
            ? ClipOval(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlack,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : profile.profilePhotoUrl == null ||
                  profile.profilePhotoUrl!.isEmpty
            ? ClipOval(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentPage = 'My Card';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlack,
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : ClipOval(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentPage = 'My Card';
                    });
                  },
                  child: Image.network(
                    profile.profilePhotoUrl ?? "",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlack,
                      ),
                      child: Center(
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    loadingBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlack,
                      ),
                      child: Center(
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),

      // floatingActionButton: InkWell(
      //   onTap: () {
      //     if (isEditing) {
      //       profileProvider.triggerSave();
      //     } else {
      //       if (_currentPage != 'My Card') {
      //         profileProvider.setEditingProfile(true);
      //       }
      //       setState(() {
      //         _currentPage = 'My Card';
      //       });
      //     }
      //   },
      //   child: Container(
      //     width: 80,
      //     height: 80,
      //     decoration: BoxDecoration(shape: BoxShape.circle),
      //     child: isEditing
      //         ? Container(
      //             decoration: BoxDecoration(
      //               shape: BoxShape.circle,
      //               color: AppTheme.primaryBlack,
      //             ),
      //             child: const Icon(Icons.check, size: 40, color: Colors.white),
      //           )
      //         : _currentPage != 'My Card'
      //         ? profile.profilePhotoUrl == null ||
      //                   profile.profilePhotoUrl!.isEmpty
      //               ? Container(
      //                   decoration: BoxDecoration(
      //                     shape: BoxShape.circle,
      //                     color: AppTheme.primaryBlack,
      //                   ),
      //                   child: const Icon(
      //                     Icons.ios_share,
      //                     size: 40,
      //                     color: Colors.white,
      //                   ),
      //                 )
      // : ClipOval(
      //     child: Image.network(
      //       profile.profilePhotoUrl ?? "",
      //       fit: BoxFit.cover,
      //     ),
      //   )
      //         : ClipOval(
      //             child:
      //                 // Container(
      //                 //   decoration: BoxDecoration(
      //                 //     shape: BoxShape.circle,
      //                 //     color: AppTheme.primaryBlack,
      //                 //   ),
      //                 //   child: Center(
      //                 //     child: Text(
      //                 //       profile.name.isNotEmpty
      //                 //           ? profile.name[0].toUpperCase()
      //                 //           : '?',
      //                 //       style: TextStyle(
      //                 //         color: Colors.white,
      //                 //         fontSize: 40,
      //                 //         fontWeight: FontWeight.bold,
      //                 //       ),
      //                 //     ),
      //                 //   ),
      //                 // ),
      //                 Container(
      //                   decoration: BoxDecoration(
      //                     shape: BoxShape.circle,
      //                     color: AppTheme.primaryBlack,
      //                   ),
      //                   child: Icon(
      //                     Icons.ios_share,
      //                     size: 40,
      //                     color: Colors.white,
      //                   ),
      //                 ),
      //           ),
      //   ),
      // ),
    );
  }
}

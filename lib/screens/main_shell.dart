import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/profile_screen.dart';
import 'package:tapni_app/screens/qr_code_sheet.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/utils/theme.dart';

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
  }

  Widget _buildCurrentScreen() {
    switch (_currentPage) {
      case 'Links':
        return const SocialLinksScreen(isTab: true);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final isEditing = profileProvider.isEditingProfile;
    final profile = profileProvider.profile;

    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                color: _currentPage == 'Links'
                    ? AppTheme.primaryBlack
                    : Colors.grey,
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Links';
                  });
                  profileProvider.setEditingProfile(false);
                },
                icon: _currentPage == 'Links'
                    ? const Icon(Icons.link)
                    : const Icon(Icons.link_outlined),
              ),
              IconButton(
                color: _currentPage == 'Contacts'
                    ? AppTheme.primaryBlack
                    : Colors.grey,
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Contacts';
                  });
                  profileProvider.setEditingProfile(false);
                },
                icon: _currentPage == 'Contacts'
                    ? const Icon(Icons.people)
                    : const Icon(Icons.people_outline),
              ),
              const SizedBox(width: 60),
              IconButton(
                color: _currentPage == 'Explore'
                    ? AppTheme.primaryBlack
                    : Colors.grey,
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Explore';
                  });
                  profileProvider.setEditingProfile(false);
                },
                icon: _currentPage == 'Explore'
                    ? const Icon(Icons.explore)
                    : const Icon(Icons.explore_outlined),
              ),
              IconButton(
                color: _currentPage == 'Settings'
                    ? AppTheme.primaryBlack
                    : Colors.grey,
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Settings';
                  });
                  profileProvider.setEditingProfile(false);
                },
                icon: _currentPage == 'Settings'
                    ? const Icon(Icons.settings)
                    : const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                    SharingProfileSheet.show(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlack,
                    ),
                    child: const Icon(
                      Icons.ios_share,
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
                        style: const TextStyle(
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
                          style: const TextStyle(
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
                          style: const TextStyle(
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
      //                 //       style: const TextStyle(
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

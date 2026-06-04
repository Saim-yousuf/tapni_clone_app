import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandabar/main.view.dart';
import 'package:pandabar/model.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/digital_card_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/profile_screen.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/utils/theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _currentPage = 'Links';

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
    // final isEditing = profileProvider.isEditingProfile;
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
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Links';
                  });
                },
                icon: const Icon(Icons.link),
              ),
              IconButton(
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Contacts';
                  });
                },
                icon: const Icon(Icons.people),
              ),
              const SizedBox(width: 60),
              IconButton(
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Explore';
                  });
                },
                icon: const Icon(Icons.explore),
              ),
              IconButton(
                iconSize: 34,
                onPressed: () {
                  setState(() {
                    _currentPage = 'Settings';
                  });
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: InkWell(
        onTap: () {
          setState(() {
            _currentPage = 'My Card';
          });
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: _currentPage == 'My Card'
              ? profile.profilePhotoUrl == null ||
                        profile.profilePhotoUrl!.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlack,
                        ),
                        child: const Icon(
                          Icons.ios_share,
                          size: 40,
                          color: Colors.white,
                        ),
                      )
                    : ClipOval(
                        child: Image.network(
                          profile.profilePhotoUrl ?? "",
                          fit: BoxFit.cover,
                        ),
                      )
              : ClipOval(
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
        ),
      ),
    );
  }
}

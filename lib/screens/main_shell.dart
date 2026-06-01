import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/home_dashboard.dart';
import 'package:tapni_app/screens/digital_card_screen.dart';
import 'package:tapni_app/screens/leads_screen.dart';
import 'package:tapni_app/screens/analytics_screen.dart';
import 'package:tapni_app/screens/settings_screen.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/utils/theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboard(),
    const SocialLinksScreen(isTab: true),
    const DigitalCardScreen(),
    const LeadsScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppTheme.greyBorderDark
                  : AppTheme.greyBorderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(
                Icons.grid_view_rounded,
                color: AppTheme.accentGold,
              ),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.link_rounded),
              activeIcon: Icon(Icons.link_rounded, color: AppTheme.accentGold),
              label: 'Links',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.badge_outlined),
              // activeIcon: Container(
              //   padding: const EdgeInsets.all(4),
              //   decoration: const BoxDecoration(
              //     color: AppTheme.accentGold,
              //     shape: BoxShape.circle,
              //   ),
              //   child: const Icon(
              //     Icons.contactless,
              //     color: AppTheme.secondaryWhite,
              //     size: 20,
              //   ),
              // ),
              activeIcon: Icon(
                Icons.badge,
                color: AppTheme.accentGold,
              ),
              label: 'My Card',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(
                Icons.people_rounded,
                color: AppTheme.accentGold,
              ),
              label: 'Contacts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics, color: AppTheme.accentGold),
              label: 'Analytics',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings, color: AppTheme.accentGold),
              label: 'Settings',
            ),
          ],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}

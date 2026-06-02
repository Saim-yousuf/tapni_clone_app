import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandabar/main.view.dart';
import 'package:pandabar/model.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
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
  String _currentPage = 'Links';

  Widget _buildCurrentScreen() {
    switch (_currentPage) {
      case 'Links':
        return const SocialLinksScreen(isTab: true);
      case 'My Card':
        return const DigitalCardScreen();
      case 'Contacts':
        return const LeadsScreen();
      case 'Analytics':
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

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: PandaBar(
        backgroundColor: isDark ? AppTheme.accentDarkGrey : Colors.white,
        buttonColor: isDark ? Colors.white54 : Colors.black38,
        buttonSelectedColor: AppTheme.accentGold,
       fabColors: [Colors.transparent, Colors.transparent],
        fabIcon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.accentGold,
                AppTheme.accentGold.withOpacity(0.7),
              ],
            ),
          ),
          child: const Icon(Icons.badge_outlined, color: Colors.white),
        ),
        buttonData: [
          PandaBarButtonData(
            id: 'Links',
            icon: Icons.link_rounded,
            title: 'Links',
          ),
          PandaBarButtonData(
            id: 'Contacts',
            icon: Icons.people_outline_rounded,
            title: 'Contacts',
          ),
          PandaBarButtonData(
            id: 'Analytics',
            icon: Icons.analytics_outlined,
            title: 'Analytics',
          ),
          PandaBarButtonData(
            id: 'Settings',
            icon: Icons.settings_outlined,
            title: 'Settings',
          ),
        ],
        onChange: (id) {
          setState(() {
            _currentPage = id;
          });
        },
        onFabButtonPressed: () {
          setState(() {
            _currentPage = 'My Card';
          });
        },
      ),
      body: _buildCurrentScreen(),
    );
  }
}

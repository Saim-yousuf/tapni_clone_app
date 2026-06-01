import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/splash_screen.dart';
import 'package:tapni_app/utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => LeadsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TapniApp(),
    ),
  );
}

class TapniApp extends StatelessWidget {
  const TapniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Tapni Demo',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

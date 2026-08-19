import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/splash_screen.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/services/push_notification_service.dart';

 void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Hold native splash until first frame / route is ready (no white flash).
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SharedPrefHelper.getInstance();
  Api.init();
  // Match light theme by default (status + nav bars).
  AppTheme.applySystemUi(Brightness.light);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => LeadsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
      ],
      child: const TapniApp(),
    ),
  );
  // FCM setup must not block cold start / splash.
  unawaited(PushNotificationService.initialize());
}

class TapniApp extends StatelessWidget {
  const TapniApp({Key? key}) : super(key: key);

  /// Effective locale for fonts: explicit app language, else device locale.
  Locale _fontLocale(LocaleProvider localeProvider) {
    return localeProvider.locale ??
        WidgetsBinding.instance.platformDispatcher.locale;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final fontLocale = _fontLocale(localeProvider);
    final brightness =
        themeProvider.isDarkMode ? Brightness.dark : Brightness.light;
    final systemUi = AppTheme.systemUiFor(brightness);

    // Keep Android status + nav bars in sync with app theme (like WhatsApp).
    AppTheme.applySystemUi(brightness);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUi,
      child: MaterialApp(
        title: 'BarQody - Digital Business Card',
        debugShowCheckedModeBanner: false,
        navigatorKey: PushNotificationService.navigatorKey,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightThemeFor(fontLocale),
        darkTheme: AppTheme.darkThemeFor(fontLocale),
        locale: localeProvider.locale,
        supportedLocales: AppLocalizationSetup.supportedLocales,
        localizationsDelegates: AppLocalizationSetup.localizationsDelegates,
        localeResolutionCallback: AppLocalizationSetup.localeResolutionCallback,
        home: const SplashScreen(),
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUiFor(Theme.of(context).brightness),
          child: ResponsiveWrapper.builder(
            BouncingScrollWrapper.builder(context, child!),
            maxWidth: double.infinity,
            minWidth: 450,
            defaultScale: true,
            breakpoints: [
              const ResponsiveBreakpoint.resize(450, name: MOBILE),
              const ResponsiveBreakpoint.resize(800, name: TABLET),
              const ResponsiveBreakpoint.resize(1000, name: TABLET),
              const ResponsiveBreakpoint.autoScale(
                double.infinity,
                name: DESKTOP,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

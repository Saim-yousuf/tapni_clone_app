# Project Context

## App
- Name: tapni_app (display title "BarQody - Digital Business Card")
- Framework: Flutter, Dart SDK ^3.12.0
- Platforms: Android, iOS, web, Windows, macOS, Linux
- State: Provider (ChangeNotifier)
- Localization: flutter_localizations + intl
- Firebase: configured via lib/firebase_options.dart

## Main entry
lib/main.dart initializes shared prefs, API, theme, providers, and MaterialApp with SplashScreen home.

## Feature areas
Auth/onboarding, profiles, digital cards, social links, gallery, QR, contacts sync, catalog/items, orders, POS, booking, attendance, loyalty, invitations, banner ads, business website, explore/search, leads, subscriptions/points, settings, help, linked devices.

## Structure
lib/{screens,models,providers,repository,services,utils,widgets,helper,l10n}; assets; platform dirs; docs; test.
" filePath">
F:\FlutterApps\tapni_app\tapni_app\memory-bank\context.md
# AGENTS.md

## Project
Flutter app `tapni_app` ("BarQody - Digital Business Card"), Dart SDK ^3.12.0. Multi-platform: Android, iOS, web, Windows, macOS, Linux. State management via Provider. Localization via flutter_localizations/intl. Firebase configured (firebase_options.dart).

## Key directories
- `lib/main.dart` - app entry, MultiProvider setup, MaterialApp, theming/locale
- `lib/screens/` - feature UI (auth, profile, catalog, orders, POS, booking, attendance, loyalty, invitations, business website, etc.)
- `lib/models/` - data models
- `lib/providers/` - ChangeNotifier providers (auth, profile, leads, theme, subscription, locale, invitation, explore cart, connectivity)
- `lib/repository/` - API/data repositories
- `lib/services/` - push notifications and services
- `lib/utils/` - helpers, endpoints, theme, checkout, webview registration
- `lib/widgets/` - reusable widgets
- `lib/helper/` - image/launcher helpers
- `assets/` - images/fonts/media
- `docs/` - integration docs
- `test/` - widget/unit tests
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` - platform code

## Conventions
- Prefer editing existing files; follow existing Provider/repository patterns.
- No comments unless requested.
- Run `flutter analyze` and tests after changes.
- Do not commit unless explicitly asked.

## Notes
- Git working tree currently has many modified/untracked files; avoid reverting unrelated changes.
- App uses responsive_framework and google_fonts.
" filePath">
F:\FlutterApps\tapni_app\tapni_app\AGENTS.md
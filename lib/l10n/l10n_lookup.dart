import 'package:flutter/widgets.dart';
import 'package:tapni_app/l10n/app_localizations.dart';
import 'package:tapni_app/services/push_notification_service.dart';

/// Resolve [AppLocalizations] from the app navigator when no BuildContext is handy.
AppLocalizations? tryL10n([BuildContext? context]) {
  final ctx = context ?? PushNotificationService.navigatorKey.currentContext;
  if (ctx == null) return null;
  return Localizations.of<AppLocalizations>(ctx, AppLocalizations);
}

String l10nOr(String Function(AppLocalizations l) pick, String fallback) {
  final l10n = tryL10n();
  if (l10n == null) return fallback;
  return pick(l10n);
}

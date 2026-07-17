import 'package:flutter/material.dart';
import 'package:tapni_app/services/push_notification_service.dart';

/// Pops create flow screens, then shows a floating toast on the remaining screen.
void finishInvitationFlow(
  BuildContext context, {
  required String message,
  required int screensToPop,
}) {
  final nav = Navigator.of(context);
  for (var i = 0; i < screensToPop; i++) {
    if (nav.canPop()) {
      nav.pop();
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final rootContext = PushNotificationService.navigatorKey.currentContext;
    if (rootContext == null) return;
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/app_toast.dart';

export 'package:tapni_app/widgets/app_toast.dart';

/// Canonical app snackbar — thin wrapper around [appToastSnackBar].
/// Prefer [showAppToast] / [showSuccessToast] / [showErrorToast] for new code.
SnackBar appSnackBar(
  String message, {
  bool isError = false,
  bool isSuccess = false,
  bool isWarning = false,
  AppToastKind? kind,
  Duration duration = const Duration(seconds: 3),
  EdgeInsetsGeometry? margin,
}) {
  return appToastSnackBar(
    message,
    kind: kind ??
        appToastKindFrom(
          isError: isError,
          isSuccess: isSuccess,
          isWarning: isWarning,
        ),
    duration: duration,
    margin: margin,
  );
}

void showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
  bool isWarning = false,
  AppToastKind? kind,
  Duration duration = const Duration(seconds: 3),
}) {
  showAppToast(
    context,
    message,
    kind: kind ??
        appToastKindFrom(
          isError: isError,
          isSuccess: isSuccess,
          isWarning: isWarning,
        ),
    duration: duration,
  );
}

/// Legacy overlay alerts — now route through [showAppToast].
class ShowAlert {
  static void error({required String message, required BuildContext context}) {
    showErrorToast(context, message);
  }

  static void success({required String message, required BuildContext context}) {
    showSuccessToast(context, message);
  }

  static void warning({required String message, required BuildContext context}) {
    showWarningToast(context, message);
  }

  static void info({required String message, required BuildContext context}) {
    showInfoToast(context, message);
  }
}

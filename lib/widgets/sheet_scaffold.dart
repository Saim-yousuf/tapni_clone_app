import 'package:flutter/material.dart';

/// Wrap bottom sheet content so [SnackBar]s appear above the sheet immediately.
class SheetScaffold extends StatelessWidget {
  final Widget body;
  final Color backgroundColor;

  const SheetScaffold({
    super.key,
    required this.body,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // Sheets pad for the keyboard themselves; resizing here double-applies
      // viewInsets and can push the sheet off-screen.
      resizeToAvoidBottomInset: false,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: body,
      ),
    );
  }
}

void showSheetSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}

/// Capture before `await` in sheet actions so messages still show after async work.
ScaffoldMessengerState sheetMessenger(BuildContext context) {
  return ScaffoldMessenger.of(context);
}

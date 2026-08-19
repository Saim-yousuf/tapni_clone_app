import 'package:flutter/material.dart';

/// Root wrapper for a modal sheet. Put this **outside** the sheet widget
/// (in [showModalBottomSheet] builder) so [ScaffoldMessenger.of] from the
/// sheet's [State] finds this messenger — a messenger inside [build] is a
/// descendant and is never used.
class SheetMessengerScope extends StatelessWidget {
  final Widget child;

  const SheetMessengerScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(child: child);
  }
}

/// Sheet layout (transparent full-height [Scaffold]). Do not nest another
/// [ScaffoldMessenger] here — the sheet [State] cannot see descendants.
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

SnackBar sheetSnackBar(
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  return SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: backgroundColor,
    duration: duration,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
  );
}

void showSheetSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    sheetSnackBar(
      message,
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}

/// Capture before `await` in sheet actions so messages still show after async work.
ScaffoldMessengerState sheetMessenger(BuildContext context) {
  return ScaffoldMessenger.of(context);
}

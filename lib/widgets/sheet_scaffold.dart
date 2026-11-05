import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

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
///
/// Taps on the dimmed area above [body] dismiss the route (same as
/// [showModalBottomSheet] `isDismissible: true`). Without this, the
/// full-height scaffold swallows barrier taps.
class SheetScaffold extends StatelessWidget {
  final Widget body;
  final Color backgroundColor;
  final bool dismissOnBarrierTap;

  const SheetScaffold({
    super.key,
    required this.body,
    this.backgroundColor = Colors.transparent,
    this.dismissOnBarrierTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // Sheets pad for the keyboard themselves; resizing here double-applies
      // viewInsets and can push the sheet off-screen.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (dismissOnBarrierTap)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                },
              ),
            ),
          // Painted above the barrier detector — sheet content keeps its taps.
          // Enter motion comes from [showAppModalBottomSheet] → [AppSheetPanelMotion].
          Align(
            alignment: Alignment.bottomCenter,
            child: body,
          ),
        ],
      ),
    );
  }
}

/// App-wide bottom sheet: noticeable slide + fade + scale on every open.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  Color? backgroundColor,
  Color? barrierColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
  double? elevation,
  bool enableDrag = true,
  bool? showDragHandle,
  BoxConstraints? constraints,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  String? barrierLabel,
  AnimationStyle? sheetAnimationStyle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.45),
    shape: shape,
    clipBehavior: clipBehavior,
    elevation: elevation,
    showDragHandle: showDragHandle,
    constraints: constraints,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    barrierLabel: barrierLabel,
    sheetAnimationStyle: sheetAnimationStyle ?? AppMotion.sheetStyle,
    builder: (ctx) => AppSheetPanelMotion(child: builder(ctx)),
  );
}

SnackBar sheetSnackBar(
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
  bool isError = false,
}) {
  return SnackBar(
    content: Text(
      message,
      style: WaUi.body.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor:
        backgroundColor ?? (isError ? const Color(0xFFC62828) : Colors.black),
    duration: duration,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
  );
}

void showSheetSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    sheetSnackBar(
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      isError: isError,
    ),
  );
}

/// Capture before `await` in sheet actions so messages still show after async work.
ScaffoldMessengerState sheetMessenger(BuildContext context) {
  return ScaffoldMessenger.of(context);
}

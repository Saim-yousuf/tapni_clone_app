import 'package:flutter/material.dart';

/// Clear slide + fade — intentionally noticeable on every push/pop.
///
/// Incoming: slides in from the right (~full card width feel).
/// Outgoing: drifts left (parallax).
class PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionsBuilder();

  static const Duration duration = Duration(milliseconds: 480);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final primary = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(primary);

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(primary);

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.28, 0),
    ).animate(secondary);

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slideIn,
          child: child,
        ),
      ),
    );
  }
}

/// App-wide [PageTransitionsTheme] — same animation on every platform.
const PageTransitionsTheme kAppPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: PremiumPageTransitionsBuilder(),
    TargetPlatform.iOS: PremiumPageTransitionsBuilder(),
    TargetPlatform.macOS: PremiumPageTransitionsBuilder(),
    TargetPlatform.windows: PremiumPageTransitionsBuilder(),
    TargetPlatform.linux: PremiumPageTransitionsBuilder(),
    TargetPlatform.fuchsia: PremiumPageTransitionsBuilder(),
  },
);

/// Prefer this for pushes — noticeable 480ms slide + fade.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Duration get transitionDuration => PremiumPageTransitionsBuilder.duration;

  @override
  Duration get reverseTransitionDuration =>
      PremiumPageTransitionsBuilder.duration;
}

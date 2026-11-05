import 'package:flutter/material.dart';

/// Shared motion tokens — intentionally noticeable (not subtle).
abstract final class AppMotion {
  static const Duration sheet = Duration(milliseconds: 560);
  static const Duration sheetReverse = Duration(milliseconds: 420);
  static const Duration dialog = Duration(milliseconds: 380);
  static const Duration dialogReverse = Duration(milliseconds: 280);
  static const Duration content = Duration(milliseconds: 420);
  static const Duration listItem = Duration(milliseconds: 450);
  static const Duration tab = Duration(milliseconds: 450);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;

  /// Sheet enter/exit (Flutter 3.27+ [sheetAnimationStyle]).
  static const AnimationStyle sheetStyle = AnimationStyle(
    duration: sheet,
    reverseDuration: sheetReverse,
    curve: easeOut,
    reverseCurve: easeIn,
  );
}

/// Fade + rise — shimmer→content and mode swaps (clearly visible).
class AppContentSwitcher extends StatelessWidget {
  const AppContentSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.content,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeIn,
      // Default layout — do NOT stack previous+current (breaks shared
      // DraggableScrollableController on Profile).
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.easeOut,
          reverseCurve: AppMotion.easeIn,
        );
        // Keep some opacity so scaffold white never fully flashes through.
        final fade = Tween<double>(begin: 0.35, end: 1).animate(curved);
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}

/// One-shot fade + slide-up + scale for list / card rows.
class AppAppear extends StatefulWidget {
  const AppAppear({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.listItem,
    this.maxStagger = 10,
    this.stagger = const Duration(milliseconds: 45),
  });

  final Widget child;
  final int index;
  final Duration duration;
  final int maxStagger;
  final Duration stagger;

  @override
  State<AppAppear> createState() => _AppAppearState();
}

class _AppAppearState extends State<AppAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
    _opacity = curved;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(curved);

    final delaySteps = widget.index.clamp(0, widget.maxStagger);
    final delay = widget.stagger * delaySteps;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Noticeable sheet enter/exit — slide up + fade + scale from bottom.
///
/// Driven by the modal route so dismiss reverses cleanly. Wrap every sheet
/// body (via [showAppModalBottomSheet] / [SheetScaffold]).
class AppSheetPanelMotion extends StatelessWidget {
  const AppSheetPanelMotion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    // Only modal/popup routes drive enter+dismiss. Page routes are already
    // settled (animation == 1) — use [AppSheetEnter] for embedded panels.
    final animation =
        route is PopupRoute ? route.animation : null;
    if (animation == null) {
      return AppSheetEnter(child: child);
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeIn,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.45),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: Alignment.bottomCenter,
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

/// One-shot sheet enter for embedded panels (Profile sheet, etc.).
///
/// Slide + light scale only — **no fade to transparent** (that caused a white
/// flash while waiting / animating over a white scaffold).
///
/// [play] false → show final state immediately (e.g. edit → view return).
class AppSheetEnter extends StatefulWidget {
  const AppSheetEnter({
    super.key,
    required this.child,
    this.duration = AppMotion.sheet,
    this.play = true,
    this.startDelay = Duration.zero,
    this.replayToken = 0,
    this.onCompleted,
  });

  final Widget child;
  final Duration duration;
  final bool play;
  final Duration startDelay;
  /// Bump to replay slide without remounting [child] (avoids DSS re-attach).
  final int replayToken;
  final VoidCallback? onCompleted;

  @override
  State<AppSheetEnter> createState() => _AppSheetEnterState();
}

class _AppSheetEnterState extends State<AppSheetEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.97, end: 1).animate(curved);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _bootstrap();
  }

  void _bootstrap() {
    if (!widget.play) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStart());
  }

  Future<void> _tryStart() async {
    if (!mounted || !widget.play) return;
    // PageView off-stage tabs disable tickers — wait until visible.
    if (!TickerMode.of(context)) {
      // Keep sheet fully shown while off-stage so we never flash white.
      if (_controller.value != 1) _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryStart());
      return;
    }
    if (widget.startDelay > Duration.zero) {
      await Future<void>.delayed(widget.startDelay);
    }
    if (!mounted || !widget.play) return;
    if (!TickerMode.of(context)) {
      if (_controller.value != 1) _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryStart());
      return;
    }
    // Replay from start only when actually visible.
    await _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant AppSheetEnter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.play && !widget.play) {
      _controller.value = 1;
      return;
    }
    if (!oldWidget.play && widget.play) {
      _bootstrap();
      return;
    }
    // Same child subtree — only re-run the slide.
    if (widget.play && widget.replayToken != oldWidget.replayToken) {
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: ScaleTransition(
        alignment: Alignment.bottomCenter,
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Noticeable fade + scale dialog.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final barrier = barrierColor ?? Colors.black.withValues(alpha: 0.5);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrier,
    transitionDuration: AppMotion.dialog,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.easeOut,
        reverseCurve: AppMotion.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

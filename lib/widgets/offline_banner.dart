import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/connectivity_provider.dart';
import 'package:tapni_app/services/push_notification_service.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Re-shows the offline banner on each navigation while still offline.
final offlineBannerNavigatorObserver = OfflineBannerNavigatorObserver();

class OfflineBannerNavigatorObserver extends NavigatorObserver {
  void _onRouteChange() {
    final context = PushNotificationService.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    context.read<ConnectivityProvider>().resetBannerForRoute();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _onRouteChange();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteChange();
  }
}

/// App-wide soft banner when the device has no network connection.
class OfflineBannerHost extends StatelessWidget {
  const OfflineBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        const _OfflineBannerOverlay(),
      ],
    );
  }
}

class _OfflineBannerOverlay extends StatefulWidget {
  const _OfflineBannerOverlay();

  @override
  State<_OfflineBannerOverlay> createState() => _OfflineBannerOverlayState();
}

class _OfflineBannerOverlayState extends State<_OfflineBannerOverlay>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late final AnimationController _snapController;
  Animation<Offset>? _snapAnimation;

  static const _dismissUp = -48.0;
  static const _dismissLeft = -72.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_snapAnimation != null) {
          setState(() => _drag = _snapAnimation!.value);
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_snapController.isAnimating) return;
    setState(() {
      final next = _drag + details.delta;
      _drag = Offset(
        next.dx.clamp(_dismissLeft * 1.4, 0),
        next.dy.clamp(_dismissUp * 1.4, 8),
      );
    });
  }

  void _onDragEnd(DragEndDetails details, ConnectivityProvider connectivity) {
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;
    final dismiss = _drag.dy <= _dismissUp ||
        _drag.dx <= _dismissLeft ||
        vy <= -520 ||
        vx <= -520;

    if (dismiss) {
      connectivity.dismissBanner();
      setState(() => _drag = Offset.zero);
      return;
    }

    _animateSnapTo(Offset.zero);
  }

  void _animateSnapTo(Offset target) {
    _snapAnimation = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final visible = connectivity.shouldShowBanner;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!visible) {
      _drag = Offset.zero;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            offset: visible ? Offset.zero : const Offset(0, -1.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              opacity: visible ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Transform.translate(
                  offset: visible ? _drag : Offset.zero,
                  child: GestureDetector(
                    onVerticalDragUpdate: _onDragUpdate,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: (d) => _onDragEnd(d, connectivity),
                    onHorizontalDragEnd: (d) => _onDragEnd(d, connectivity),
                    child: _OfflineBannerCard(isDark: isDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBannerCard extends StatelessWidget {
  const _OfflineBannerCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final surface = isDark
        ? const Color(0xFF1F1F1F).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.94);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8ECF0);
    final iconBg = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFF4F6F8);
    final iconColor = isDark
        ? const Color(0xFFFFB4AB)
        : const Color(0xFF64748B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(WaUi.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(WaUi.radiusLg),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.noInternetConnection,
                        style: AppFonts.titleStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : WaUi.primaryText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.pleaseCheckYourConnection,
                        style: AppFonts.titleStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : WaUi.secondaryText,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

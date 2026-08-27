import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Soft scooped bottom bar — organic cradle around the center button.
class CurvedBottomNav extends StatelessWidget {
  const CurvedBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.centerButton,
    this.backgroundColor = Colors.white,
    this.height = 72,
    this.fabSize = 74,
    this.notchMargin = 12,
  });

  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget centerButton;
  final Color backgroundColor;
  final double height;
  final double fabSize;
  final double notchMargin;

  /// FAB is centered on the bar top so the cut-out wraps its lower half.
  static double fabOverhang([double fabSize = 74]) => fabSize * 0.5;

  /// Space the shell must keep clear so tab content sits above the white bar.
  static double contentClearance(
    BuildContext context, {
    double height = 72,
  }) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return height + bottomInset;
  }

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'CurvedBottomNav expects exactly 4 side items.');
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final notchRadius = fabSize / 2 + notchMargin;
    const lip = _ScoopGeometry.lip;
    final fabOverhang = CurvedBottomNav.fabOverhang(fabSize);
    final totalHeight = height + bottomInset + fabOverhang;
    final barHeight = height + bottomInset;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = backgroundColor;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: CustomPaint(
              painter: _ScoopedBarShadowPainter(notchRadius: notchRadius),
              child: ClipPath(
                clipper: _ScoopedBarClipper(notchRadius: notchRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: ColoredBox(
                    color: fill,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Row(
                        children: [
                          Expanded(
                            child: _NavIconButton(
                              item: items[0],
                              selected: currentIndex == 0,
                              onTap: () => onTap(0),
                            ),
                          ),
                          Expanded(
                            child: _NavIconButton(
                              item: items[1],
                              selected: currentIndex == 1,
                              onTap: () => onTap(1),
                            ),
                          ),
                          SizedBox(width: (notchRadius + lip) * 2),
                          Expanded(
                            child: _NavIconButton(
                              item: items[2],
                              selected: currentIndex == 2,
                              onTap: () => onTap(2),
                            ),
                          ),
                          Expanded(
                            child: _NavIconButton(
                              item: items[3],
                              selected: currentIndex == 3,
                              onTap: () => onTap(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Soft hairline along the scooped top edge.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScoopedBarStrokePainter(
                  notchRadius: notchRadius,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFD8D8DC),
                ),
              ),
            ),
          ),
          Positioned(top: 0, child: centerButton),
        ],
      ),
    );
  }
}

class CurvedNavItem {
  const CurvedNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.selectedColor = Colors.black,
    this.unselectedColor = const Color(0xFF8E8E93),
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color selectedColor;
  final Color unselectedColor;
}

class _NavIconButton extends StatefulWidget {
  const _NavIconButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

/// Soft & sweet tab select — gentle spring pill + icon.
class _NavIconButtonState extends State<_NavIconButton>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 420);

  late final AnimationController _controller;
  late final Animation<double> _pillScale;
  late final Animation<double> _pillOpacity;
  late final Animation<double> _iconScale;

  bool get _visuallySelected {
    final item = widget.item;
    return widget.selected &&
        (item.selectedIcon != item.icon ||
            item.selectedColor != item.unselectedColor);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);

    // Creamy ease-out-back: soft overshoot, then settle.
    final spring = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _pillScale = Tween<double>(begin: 0.62, end: 1.0).animate(spring);
    _pillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    if (_visuallySelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _NavIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSelected =
        oldWidget.selected &&
        (oldWidget.item.selectedIcon != oldWidget.item.icon ||
            oldWidget.item.selectedColor != oldWidget.item.unselectedColor);
    final isSelected = _visuallySelected;
    if (isSelected && !wasSelected) {
      HapticFeedback.selectionClick();
      _controller.forward(from: 0);
    } else if (!isSelected && wasSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final visuallySelected = _visuallySelected;
    final icon = visuallySelected ? item.selectedIcon : item.icon;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark
        ? const Color(0xFF3A3A3C)
        : WaUi.navPill;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final showPill =
                    visuallySelected || _controller.isAnimating;
                final pillScale = showPill ? _pillScale.value : 0.62;
                final pillOpacity = showPill ? _pillOpacity.value : 0.0;
                final iconScale = visuallySelected || _controller.isAnimating
                    ? (_controller.status == AnimationStatus.reverse
                        ? 1.0
                        : _iconScale.value)
                    : 1.0;

                return SizedBox(
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: pillOpacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: pillScale.clamp(0.5, 1.15),
                          child: Container(
                            width: 58,
                            height: 30,
                            decoration: BoxDecoration(
                              color: pillColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: iconScale,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.88,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            icon,
                            key: ValueKey(icon),
                            size: 24,
                            color: item.selectedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _duration,
              curve: Curves.easeOutCubic,
              style: AppFonts.titleStyle(
                fontSize: 12,
                fontWeight:
                    visuallySelected ? FontWeight.w500 : FontWeight.w400,
                color: item.selectedColor,
                height: 1.1,
              ).copyWith(inherit: false),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft Material-style cradle: wide rounded lips + round circular well.
/// Clearly softer than a V tip, softer than a hard half-circle hole.
class _ScoopGeometry {
  /// Wide flare so shoulders are obviously soft and start further out.
  static const double lip = 48.0;

  static Path topEdge(Size size, double notchRadius) {
    final cx = size.width / 2;
    final r = notchRadius;
    const flare = lip;

    // Meet the circle higher up → long soft lips, round belly (no V tip).
    const alpha = 0.32;
    final ax = r * math.cos(alpha);
    final ay = r * math.sin(alpha);
    final half = r + flare;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(cx - half, 0)
      // Left lip — long, creamy S-curve into the well.
      ..cubicTo(
        cx - half + flare * 0.38,
        0,
        cx - ax - flare * 0.18,
        ay * 0.12,
        cx - ax,
        ay,
      )
      // Round U under FAB (circular arc = no pointed tip).
      ..arcToPoint(
        Offset(cx + ax, ay),
        radius: Radius.circular(r),
        clockwise: false,
      )
      // Right lip.
      ..cubicTo(
        cx + ax + flare * 0.18,
        ay * 0.12,
        cx + half - flare * 0.38,
        0,
        cx + half,
        0,
      )
      ..lineTo(size.width, 0);
  }

  static Path fill(Size size, double notchRadius) {
    return Path()
      ..addPath(topEdge(size, notchRadius), Offset.zero)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }
}

class _ScoopedBarClipper extends CustomClipper<Path> {
  _ScoopedBarClipper({required this.notchRadius});

  final double notchRadius;

  @override
  Path getClip(Size size) => _ScoopGeometry.fill(size, notchRadius);

  @override
  bool shouldReclip(covariant _ScoopedBarClipper oldClipper) {
    return oldClipper.notchRadius != notchRadius;
  }
}

class _ScoopedBarShadowPainter extends CustomPainter {
  _ScoopedBarShadowPainter({required this.notchRadius});

  final double notchRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _ScoopGeometry.fill(size, notchRadius);

    // Layered soft shadows — diffused, not harsh.
    canvas.drawPath(
      path.shift(const Offset(0, -2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawPath(
      path.shift(const Offset(0, -1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _ScoopedBarShadowPainter oldDelegate) {
    return oldDelegate.notchRadius != notchRadius;
  }
}

class _ScoopedBarStrokePainter extends CustomPainter {
  _ScoopedBarStrokePainter({
    required this.notchRadius,
    required this.color,
  });

  final double notchRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _ScoopGeometry.topEdge(size, notchRadius),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoopedBarStrokePainter oldDelegate) {
    return oldDelegate.notchRadius != notchRadius ||
        oldDelegate.color != color;
  }
}

/// Circular floating center button.
class CurvedNavCenterButton extends StatelessWidget {
  const CurvedNavCenterButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = 74,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: Colors.white24,
        highlightColor: Colors.transparent,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: IconTheme(
              data: IconThemeData(color: foregroundColor, size: size * 0.42),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foregroundColor),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.82,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: child.key ?? ValueKey(child.runtimeType),
                    child: Center(child: child),
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

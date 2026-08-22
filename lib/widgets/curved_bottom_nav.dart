import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// White bottom bar with a circular cut-out so the center button is never
/// covered by the bar — same cradle as a docked FAB.
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

    /// Gap between the FAB edge and the white cut-out.
    this.notchMargin = 8,
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
  /// FAB overhang is not included — the center button is meant to float over content.
  /// Sticky bottom CTAs should add [fabOverhang] themselves so they stay tappable.
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
    const lip = _ScoopedBarPainter.lip;
    final fabOverhang = CurvedBottomNav.fabOverhang(fabSize);
    final totalHeight = height + bottomInset + fabOverhang;

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
            child: CustomPaint(
              painter: _ScoopedBarPainter(
                color: backgroundColor,
                notchRadius: notchRadius,
              ),
              child: SizedBox(
                height: height + bottomInset,
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

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 220);
    final visuallySelected =
        selected &&
        (item.selectedIcon != item.icon ||
            item.selectedColor != item.unselectedColor);
    final icon = visuallySelected ? item.selectedIcon : item.icon;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: visuallySelected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3A3A3C)
                        : WaUi.navPill)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: 24,
                  color: item.selectedColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: Curves.easeOut,
              style: WaUi.navLabel.copyWith(
                color: item.selectedColor,
                fontSize: 12,
                fontWeight:
                    visuallySelected ? FontWeight.w700 : FontWeight.w500,
                height: 1.1,
              ),
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

/// Circular cut-out around the FAB so the bar never draws behind the button.
/// Rounded lips join the flat top to the arc (Material [CircularNotchedRectangle]).
class _ScoopedBarPainter extends CustomPainter {
  _ScoopedBarPainter({required this.color, required this.notchRadius});

  final Color color;
  final double notchRadius;

  /// Outward rounded corner where the flat top meets the circular well.
  static const double lip = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final topEdge = _topEdgePath(size);
    final fillPath = Path()
      ..addPath(topEdge, Offset.zero)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(fillPath.shift(const Offset(0, -1)), shadowPaint);
    canvas.drawPath(fillPath, Paint()..color = color);

    canvas.drawPath(
      topEdge.shift(const Offset(0, 0.5)),
      Paint()
        ..color = const Color(0xFFD8D8DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  Path _topEdgePath(Size size) {
    final host = Offset.zero & size;
    final guest = Rect.fromCircle(
      center: Offset(size.width / 2, 0),
      radius: notchRadius,
    );

    final r = notchRadius;
    const s1 = lip;
    const s2 = 1.0;

    final a = -r - s2;
    final b = host.top - guest.center.dy;
    final denom = a * a + b * b;
    final n2 = math.sqrt(b * b * r * r * (denom - r * r));
    final p2xA = ((a * r * r) - n2) / denom;
    final p2xB = ((a * r * r) + n2) / denom;
    final p2yA = math.sqrt(r * r - p2xA * p2xA);
    final p2yB = math.sqrt(r * r - p2xB * p2xB);

    final p = List<Offset>.filled(6, Offset.zero);
    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);
    p[3] = Offset(-p[2].dx, p[2].dy);
    p[4] = Offset(-p[1].dx, p[1].dy);
    p[5] = Offset(-p[0].dx, p[0].dy);

    for (var i = 0; i < p.length; i++) {
      p[i] += guest.center;
    }

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(p[3], radius: Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right, host.top);
  }

  @override
  bool shouldRepaint(covariant _ScoopedBarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.notchRadius != notchRadius;
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
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: IconTheme(
              data: IconThemeData(color: foregroundColor, size: size * 0.42),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foregroundColor),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.86,
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

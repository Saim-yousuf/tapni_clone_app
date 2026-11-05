import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// White bottom bar whose top edge dips in a soft center wave (not a round hole)
/// so the floating center button sits in the trough.
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

  /// FAB is centered on the bar top so the wave trough clears its lower half.
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
    final wave = _WaveBarPainter.metrics(
      fabSize: fabSize,
      notchMargin: notchMargin,
    );
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
              painter: _WaveBarPainter(
                color: backgroundColor,
                waveHalfWidth: wave.halfWidth,
                waveDepth: wave.depth,
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
                      SizedBox(width: wave.halfWidth * 2),
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

/// WhatsApp Business–style tab select: pill pops in, icon bounces once.
class _NavIconButtonState extends State<_NavIconButton>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 360);

  late final AnimationController _controller;
  late final Animation<double> _pillScale;
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
    _pillScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_controller);
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
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
      _controller.forward(from: 0);
    } else if (!isSelected && wasSelected) {
      _controller.value = 0;
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
    final pillColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3C)
        : WaUi.navPill;

    return InkWell(
      onTap: widget.onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final animatingIn =
                    visuallySelected && !_controller.isDismissed;
                final pillScale =
                    animatingIn ? _pillScale.value.clamp(0.0, 1.2) : 1.0;
                final iconScale = animatingIn ? _iconScale.value : 1.0;
                final showPill = visuallySelected;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pill scales independently so icon bounce isn't compounded.
                      if (showPill)
                        Transform.scale(
                          scale: pillScale,
                          child: Container(
                            width: 56,
                            height: 32,
                            decoration: BoxDecoration(
                              color: pillColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      Transform.scale(
                        scale: iconScale,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
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
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: _duration,
              curve: Curves.easeOut,
              // Rebuild via AppFonts — copyWith(fontWeight) is a no-op with Google Fonts.
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

class _WaveMetrics {
  const _WaveMetrics({required this.halfWidth, required this.depth});
  final double halfWidth;
  final double depth;
}

/// Soft center wave on the bar top — wide trough, not a circular hole.
class _WaveBarPainter extends CustomPainter {
  _WaveBarPainter({
    required this.color,
    required this.waveHalfWidth,
    required this.waveDepth,
  });

  final Color color;
  final double waveHalfWidth;
  final double waveDepth;

  static const double cornerRadius = 16.0;

  /// Wider than a round notch so the silhouette reads as a wave / lehr.
  static _WaveMetrics metrics({
    required double fabSize,
    required double notchMargin,
  }) {
    final depth = fabSize * 0.5 + notchMargin;
    // Spread past the FAB so sides slope gently instead of wrapping tight.
    final halfWidth = fabSize * 0.5 + notchMargin + 28;
    return _WaveMetrics(halfWidth: halfWidth, depth: depth);
  }

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

  /// Flat → soft dip → flat. Two cubics form one continuous wave trough.
  Path _topEdgePath(Size size) {
    final w = size.width;
    final cx = w / 2;
    final hw = waveHalfWidth;
    final d = waveDepth;
    const cr = cornerRadius;

    // Control points pull the curve down early / up late so it feels like a
    // wave valley, not a punched circular well around the FAB.
    return Path()
      ..moveTo(0, cr)
      ..quadraticBezierTo(0, 0, cr, 0)
      ..lineTo(cx - hw, 0)
      ..cubicTo(
        cx - hw * 0.45,
        0,
        cx - hw * 0.55,
        d,
        cx,
        d,
      )
      ..cubicTo(
        cx + hw * 0.55,
        d,
        cx + hw * 0.45,
        0,
        cx + hw,
        0,
      )
      ..lineTo(w - cr, 0)
      ..quadraticBezierTo(w, 0, w, cr);
  }

  @override
  bool shouldRepaint(covariant _WaveBarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.waveHalfWidth != waveHalfWidth ||
        oldDelegate.waveDepth != waveDepth;
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
                  duration: const Duration(milliseconds: 320),
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

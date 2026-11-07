import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_motion.dart';

/// Vertical roll when [text] changes — same motion as cart qty.
class AppRollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? compareValue;
  final Duration duration;
  final double slideFactor;
  final double? height;
  final double? width;

  const AppRollingText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.compareValue,
    this.duration = const Duration(milliseconds: 220),
    this.slideFactor = 0.55,
    this.height,
    this.width,
  });

  @override
  State<AppRollingText> createState() => _AppRollingTextState();
}

class _AppRollingTextState extends State<AppRollingText> {
  int _direction = 1;
  String _prevText = '';
  int? _prevCompare;

  @override
  void initState() {
    super.initState();
    _prevText = widget.text;
    _prevCompare = widget.compareValue;
  }

  @override
  void didUpdateWidget(covariant AppRollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text) return;

    if (widget.compareValue != null && _prevCompare != null) {
      _direction = widget.compareValue! >= _prevCompare! ? 1 : -1;
    } else {
      final next = double.tryParse(
        widget.text.replaceAll(RegExp(r'[^0-9.\-]'), ''),
      );
      final prev = double.tryParse(
        _prevText.replaceAll(RegExp(r'[^0-9.\-]'), ''),
      );
      if (next != null && prev != null && next != prev) {
        _direction = next > prev ? 1 : -1;
      } else {
        _direction = 1;
      }
    }
    _prevText = widget.text;
    _prevCompare = widget.compareValue;
  }

  @override
  Widget build(BuildContext context) {
    final child = Text(
      widget.text,
      key: ValueKey(widget.text),
      textAlign: widget.textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );

    final switcher = AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            ...previous,
            if (current != null) current,
          ],
        );
      },
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(widget.text);
        final begin = Offset(
          0,
          widget.slideFactor * (incoming ? _direction : -_direction),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: child,
    );

    Widget out = ClipRect(child: switcher);
    if (widget.height != null || widget.width != null) {
      out = SizedBox(
        height: widget.height,
        width: widget.width,
        child: out,
      );
    }
    return out;
  }
}

/// Convenience for money / qty labels with app motion timing.
class AppRollingMoney extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double? compareValue;

  const AppRollingMoney(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.compareValue,
  });

  @override
  Widget build(BuildContext context) {
    return AppRollingText(
      text,
      style: style,
      textAlign: textAlign,
      compareValue: compareValue == null
          ? null
          : (compareValue! * 100).round(),
      duration: AppMotion.content,
      height: ((style?.fontSize ?? 15) * (style?.height ?? 1.25)).clamp(
        18.0,
        32.0,
      ),
    );
  }
}

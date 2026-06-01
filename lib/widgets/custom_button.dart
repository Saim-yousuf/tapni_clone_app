import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSecondary;
  final bool isGold;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.isSecondary = false,
    this.isGold = false,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buttonBody = Center(
      child: widget.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isSecondary 
                        ? (isDark ? Colors.white : Colors.black)
                        : (widget.isGold ? AppTheme.secondaryWhite : AppTheme.secondaryWhite),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: widget.isSecondary 
                        ? (isDark ? Colors.white : Colors.black)
                        : (widget.isGold ? AppTheme.secondaryWhite : AppTheme.secondaryWhite),
                  ),
                ),
              ],
            ),
    );

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isGold && !widget.isSecondary ? AppTheme.goldGradient : null,
            color: widget.isGold 
                ? null 
                : widget.isSecondary
                    ? Colors.transparent
                    : (isDark ? Colors.white : Colors.black),
            border: widget.isSecondary
                ? Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                    width: 1.5,
                  )
                : null,
            boxShadow: widget.isGold && !widget.isSecondary
                ? [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: buttonBody,
        ),
      ),
    );
  }
}

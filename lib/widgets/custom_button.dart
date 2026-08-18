import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

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

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: WaPrimaryButton(
          label: widget.text,
          onPressed: widget.isLoading ? null : widget.onTap,
          loading: widget.isLoading,
          icon: widget.icon,
          outlined: widget.isSecondary,
          backgroundColor: widget.isGold ? AppTheme.accentGold : null,
        ),
      ),
    );
  }
}

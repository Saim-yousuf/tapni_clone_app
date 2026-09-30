import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Shared chrome for Tools / Accounts / modal redesigns.
class BarqodyChrome {
  BarqodyChrome._();

  static const Color scaffold = Colors.white;
  static const Color circleBtn = Color(0xFFF2F2F7);
  static const Color searchBg = Color(0xFFF2F2F7);
  static const Color secondaryText = Color(0xFF8E8E93);
  static const Color bodyText = Color(0xFF707070);
  static const Color divider = Color(0xFFE8E8E8);
  static const Color fieldFill = Color(0xFFF2F2F7);
  static const Color star = Color(0xFFFFCC00);
  static const double sheetRadius = 32;
  static const double modalRadius = 28;
  static const double sidePad = 20;
}

class BarqodyTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  const BarqodyTitleBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            CircleBackButton(onTap: onBack),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.toolsTitleOf(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
            ),
            trailing ?? const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class CircleAssetButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  final double iconSize;
  final Widget? child;
  final bool badge;

  const CircleAssetButton({
    super.key,
    required this.asset,
    this.onTap,
    this.iconSize = 16,
    this.child,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child ??
                  Image.asset(
                    asset,
                    width: iconSize,
                    height: iconSize,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.circle_outlined,
                      size: iconSize,
                      color: Colors.black,
                    ),
                  ),
              if (badge)
                const Positioned(
                  top: 7,
                  right: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 7, height: 7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircleBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const CircleBackButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Image.asset(
              'assets/images/png/arrow-back.png',
              width: 12,
              height: 12,
              color: Colors.black,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircleCloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CircleCloseButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.close, size: 16, color: Colors.black),
        ),
      ),
    );
  }
}

class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD1D1D6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool enabled;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: WaUi.promoButton.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1.2),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class AssetIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const AssetIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      color: color,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_outlined,
        size: size,
        color: color ?? Colors.black,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

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
                  size: 20,
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

/// Puts [child] strictly below the drag handle (never beside/overlay it).
/// Use for close buttons, title rows, and all sheet chrome after the handle.
class SheetHandleThen extends StatelessWidget {
  final Widget child;
  final bool showHandle;
  final double topGap;
  final double afterHandleGap;

  const SheetHandleThen({
    super.key,
    required this.child,
    this.showHandle = true,
    this.topGap = 10,
    this.afterHandleGap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle) ...[
          SizedBox(height: topGap),
          const SheetDragHandle(),
          SizedBox(height: afterHandleGap),
        ],
        child,
      ],
    );
  }
}

/// Standard sheet top: [SheetDragHandle] then [BarqodyTitleBar] (OTP back).
/// Use on every titled bottom sheet. Close/back always start after the handle.
class SheetHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showHandle;

  const SheetHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return SheetHandleThen(
      showHandle: showHandle,
      afterHandleGap: 8,
      child: BarqodyTitleBar(
        title: title,
        trailing: trailing,
        onBack: onBack ?? () => Navigator.of(context).maybePop(),
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

/// Alias of [AuthBackButton] (OTP / Verify) for Barqody chrome call sites.
class CircleBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const CircleBackButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return AuthBackButton(
      onPressed: onTap,
      backgroundColor: color,
    );
  }
}

class CircleCloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CircleCloseButton({super.key, this.onTap});

  static const asset = 'assets/images/png/cross-icon.png';

  @override
  Widget build(BuildContext context) {
    // Match [AuthBackButton] / [CircleBackButton] hit size (40×40).
    // Always use [asset] for close/cross — never Icons.close.
    return Material(
      color: BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Image.asset(
              asset,
              width: 22,
              height: 22,
              color: Colors.black,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.close,
                size: 22,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Canonical bottom-sheet grabber — 40×4, `#D1D1D6`, centered.
/// Use this everywhere (never ad-hoc Containers).
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  static const double width = 80;
  static const double height = 4;
  static const Color color = Color(0xFFD1D1D6);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// App-wide pill CTA — same height / type as login Continue
/// ([AuthUi.buttonHeight] 54, label 16 / w700).
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
    final m = AuthScale.of(context);
    final h = m.buttonH;
    final labelStyle = WaUi.body.copyWith(
      fontSize: m.s(AuthUi.buttonLabelSize),
      fontWeight: FontWeight.w700,
      color: filled ? Colors.white : Colors.black,
      height: 1,
    );

    if (filled) {
      return Container(
        width: double.infinity,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h / 2),
          boxShadow: AuthUi.primaryButtonShadow(m),
        ),
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
            minimumSize: Size(double.infinity, h),
            maximumSize: Size(double.infinity, h),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(label, style: labelStyle),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: h,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(
            color: Colors.black,
            width: AuthUi.outlineBorderWidth,
          ),
          shape: const StadiumBorder(),
          minimumSize: Size(double.infinity, h),
          maximumSize: Size(double.infinity, h),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: labelStyle),
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

/// Soft branded stand-in when a profile has no cover photo.
class ProfileCoverPlaceholder extends StatelessWidget {
  const ProfileCoverPlaceholder({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD6E0E8),
              Color(0xFFE8EEF2),
              Color(0xFFB8C6D1),
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft vignette so the sheet edge reads cleaner.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 0.14,
                child: Image.asset(
                  'assets/images/png/app_icon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    size: 56,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

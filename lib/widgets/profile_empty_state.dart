import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Empty placeholder for profile Apps / Gallery / Reviews / Links.
/// Pass [imageAsset] for contacts-style vector + float; otherwise [icon].
class ProfileEmptyState extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final String? subtitle;
  final Widget? action;

  const ProfileEmptyState({
    super.key,
    this.icon,
    this.imageAsset,
    required this.title,
    this.subtitle,
    this.action,
  }) : assert(icon != null || imageAsset != null);

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final hasAsset = imageAsset != null && imageAsset!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.s(28), vertical: m.v(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasAsset)
                _FloatingEmptyVector(asset: imageAsset!)
              else
                Container(
                  width: m.s(72),
                  height: m.s(72),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Icon(
                    icon,
                    size: m.s(32),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              SizedBox(height: m.v(24)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: WaUi.toolsTitleOf(
                  size: 22,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.15,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                SizedBox(height: m.v(10)),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: m.s(15),
                    height: 1.35,
                    color: BarqodyChrome.bodyText,
                  ),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: m.v(18)),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingEmptyVector extends StatefulWidget {
  final String asset;

  const _FloatingEmptyVector({required this.asset});

  @override
  State<_FloatingEmptyVector> createState() => _FloatingEmptyVectorState();
}

class _FloatingEmptyVectorState extends State<_FloatingEmptyVector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: Image.asset(
        widget.asset,
        width: m.s(140),
        height: m.s(140),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.link_rounded,
          size: m.s(80),
          color: BarqodyChrome.secondaryText.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

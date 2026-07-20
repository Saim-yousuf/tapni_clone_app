import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class WaToolsHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const WaToolsHeader({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: WaUi.toolsTitle.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class WaSectionHeader extends StatelessWidget {
  final String title;

  const WaSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title, style: WaUi.sectionHeader),
    );
  }
}

class WaToolsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showBadge;
  final Color? titleColor;
  final Widget? trailing;

  const WaToolsListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showBadge = false,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 24, color: WaUi.promoIconFg),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WaUi.listTitle.copyWith(color: titleColor),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: WaUi.listSubtitle),
              ],
            ),
          ),
          if (showBadge)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: WaUi.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: trailing!,
            ),
        ],
      ),
    );

    return Material(
      color: WaUi.toolsScaffold,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class WaForYouCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const WaForYouCard({
    super.key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: WaUi.promoCardDecoration,
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WaUi.promoIconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: WaUi.promoIconFg,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: WaUi.secondaryText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: WaUi.promoTitle),
            const SizedBox(height: 6),
            Text(description, style: WaUi.promoBody),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusPill),
                  ),
                  elevation: 0,
                ),
                child: Text(buttonLabel, style: WaUi.promoButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaBottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool showDot;

  const WaBottomNavItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    // WhatsApp-style: soft gray ripple clipped to the icon pill only.
    const pillRadius = BorderRadius.all(Radius.circular(16));
    final splash = const Color(0xFF667781).withValues(alpha: 0.14);
    final highlight = const Color(0xFF667781).withValues(alpha: 0.08);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Material(
                  color: selected ? WaUi.navPill : Colors.transparent,
                  borderRadius: pillRadius,
                  child: InkWell(
                    onTap: onTap,
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: pillRadius,
                    splashFactory: InkRipple.splashFactory,
                    splashColor: splash,
                    highlightColor: highlight,
                    child: SizedBox(
                      width: 64,
                      height: 32,
                      child: Icon(
                        selected ? (selectedIcon ?? icon) : icon,
                        size: 24,
                        color: WaUi.primaryText,
                      ),
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: WaUi.accent,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: WaUi.label.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (showDot)
                  Positioned(
                    right: 4,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: WaUi.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: selected ? WaUi.navLabelActive : WaUi.navLabel,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/contact_category.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/profile_photo_avatar.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/verified_name.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class WaChatsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  const WaChatsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(leading != null ? 17 : 25, 8, 17, 4),
      child: SizedBox(
        height: 52,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WaUi.toolsTitleOf(
                      weight: FontWeight.w600,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: WaUi.caption),
                  ],
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class WaChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final String? hintText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  WaChatSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.hintText,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(25, 10, 25, 12),
  });

  @override
  Widget build(BuildContext context) {
    final field = SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        showCursor: !readOnly,
        enableInteractiveSelection: !readOnly,
        onChanged: onChanged,
        style: WaUi.body.copyWith(fontSize: 16, height: 1.2),
        cursorColor: WaUi.buttonDark,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF2F2F7),
          hintText: hintText ?? context.l10n.searchEllipsis,
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E93),
            height: 1.2,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 56,
          ),
          suffixIcon: trailing != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: trailing,
                )
              : (!readOnly && controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFF8E8E93),
                      onPressed: onClear,
                    )
                  : null),
          suffixIconConstraints: trailing != null
              ? const BoxConstraints(minWidth: 48, minHeight: 48)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );

    return Padding(
      padding: padding,
      child: field,
    );
  }
}

class WaPillFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Color? selectedColor;
  final Color? borderColor;
  final Color? selectedBorderColor;

  const WaPillFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.selectedColor,
    this.borderColor,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? (selectedColor ?? WaUi.buttonDark)
        : Colors.white;
    final outline = selected
        ? (selectedBorderColor ?? selectedColor ?? WaUi.buttonDark)
        : (borderColor ?? const Color(0xFFE5E5EA));
    final textColor =
        selected ? Colors.white : const Color(0xFF8E8E93);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WaUi.radiusPill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(WaUi.radiusPill),
              border: Border.all(color: outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 6),
                ],
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WaContactFilterChips extends StatelessWidget {
  final List<ContactCategory> categories;
  final String? activeCategoryId;
  final VoidCallback onAllTap;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onAddCategory;

  WaContactFilterChips({
    super.key,
    required this.categories,
    required this.activeCategoryId,
    required this.onAllTap,
    required this.onCategoryTap,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 12),
        children: [
          WaPillFilterChip(
            label: context.l10n.all,
            selected: activeCategoryId == null,
            onTap: onAllTap,
            borderColor: const Color(0xFFE5E5EA),
          ),
          ...categories.map((category) {
            return WaPillFilterChip(
              label: category.name,
              selected: activeCategoryId == category.id,
              borderColor: const Color(0xFFE5E5EA),
              onTap: () => onCategoryTap(category.id),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddCategory,
                borderRadius: BorderRadius.circular(WaUi.radiusPill),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaChatListTile extends StatelessWidget {
  final String name;
  final String preview;
  final String date;
  final String? imageUrl;
  final String? initial;
  final Color? avatarColor;
  final Color? categoryColor;
  final bool highlightDate;
  final int? unreadCount;
  final Widget? previewIcon;
  final bool showDivider;
  final bool verified;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const WaChatListTile({
    super.key,
    required this.name,
    required this.preview,
    required this.date,
    this.imageUrl,
    this.initial,
    this.avatarColor,
    this.categoryColor,
    this.highlightDate = false,
    this.unreadCount,
    this.previewIcon,
    this.showDivider = true,
    this.verified = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 21, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    imageUrl: imageUrl,
                    initial: initial,
                    color: avatarColor,
                    ringColor: categoryColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: VerifiedName(
                                name: name,
                                verified: verified,
                                badgeSize: 20,
                                textAlign: TextAlign.start,
                                style: WaUi.chatName.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (date.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                date,
                                style: highlightDate
                                    ? WaUi.chatDateHighlight
                                    : WaUi.chatDate,
                              ),
                            ],
                          ],
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (previewIcon != null) ...[
                                previewIcon!,
                                const SizedBox(width: 3),
                              ],
                              Expanded(
                                child: Text(
                                  preview,
                                  style: WaUi.chatPreview.copyWith(
                                    color: const Color(0xFF8E8E93),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount != null && unreadCount! > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 20),
                                  height: 20,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: WaUi.accent,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unreadCount! > 99 ? '99+' : '$unreadCount',
                                    style: WaUi.label.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Color(0xFFC7C7CC),
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Divider(
                height: 1,
                thickness: 0.5,
                indent: 0,
                endIndent: 0,
                color: Color(0xFFE5E5EA),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? initial;
  final Color? color;
  final Color? ringColor;

  const _Avatar({
    this.imageUrl,
    this.initial,
    this.color,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: 2)
            : null,
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: color ?? WaUi.navPill,
        backgroundImage: hasImage
            ? NetworkImage(imageUrl!.trim())
            : BarqodyProfilePhoto.provider,
      ),
    );
  }
}

class WaContactEmptyState extends StatelessWidget {
  final bool isSearching;

  const WaContactEmptyState({
    super.key,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          BarqodyChrome.sidePad,
          m.v(24),
          BarqodyChrome.sidePad,
          100,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EmptyIllustration(isSearching: isSearching),
              SizedBox(height: m.v(24)),
              Text(
                isSearching
                    ? context.l10n.noMatches
                    : context.l10n.noContactsYet,
                textAlign: TextAlign.center,
                style: WaUi.toolsTitleOf(
                  size: 22,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.15,
                ),
              ),
              SizedBox(height: m.v(10)),
              Text(
                isSearching
                    ? context.l10n.tryADifferentNameEmailOrCompany
                    : context.l10n
                        .scanAQRCodeOrAddSomeoneYouMetToBuildYourNetwork,
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(
                  fontSize: m.s(15),
                  height: 1.35,
                  color: BarqodyChrome.bodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatefulWidget {
  final bool isSearching;

  const _EmptyIllustration({required this.isSearching});

  @override
  State<_EmptyIllustration> createState() => _EmptyIllustrationState();
}

class _EmptyIllustrationState extends State<_EmptyIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _float = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _startIfNeeded();
  }

  void _startIfNeeded() {
    if (widget.isSearching) {
      _floatCtrl.stop();
      return;
    }
    _floatCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _EmptyIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSearching != widget.isSearching) {
      if (widget.isSearching) {
        _floatCtrl.stop();
      } else {
        _startIfNeeded();
      }
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    if (widget.isSearching) {
      return Icon(
        Icons.search_off_rounded,
        size: m.s(120),
        color: BarqodyChrome.secondaryText.withValues(alpha: 0.35),
      );
    }

    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/png/notebook-of-contacts.png',
        width: m.s(140),
        height: m.s(140),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.people_alt_outlined,
          size: m.s(80),
          color: BarqodyChrome.secondaryText.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class WaContactSpeedDial extends StatefulWidget {
  final VoidCallback onAdd;
  final VoidCallback onFind;

  WaContactSpeedDial({
    super.key,
    required this.onAdd,
    required this.onFind,
  });

  @override
  State<WaContactSpeedDial> createState() => _WaContactSpeedDialState();
}

class _WaContactSpeedDialState extends State<WaContactSpeedDial> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _run(VoidCallback action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _speedAction(
            label: context.l10n.findUser,
            icon: Icons.person_search_outlined,
            onTap: () => _run(widget.onFind),
          ),
          SizedBox(height: 14),
          _speedAction(
            label: context.l10n.addContact,
            icon: Icons.person_add_outlined,
            onTap: () => _run(widget.onAdd),
          ),
          SizedBox(height: 14),
        ],
        FloatingActionButton(
          heroTag: 'contacts_more',
          onPressed: _toggle,
          elevation: 3,
          backgroundColor: WaUi.buttonDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: Duration(milliseconds: 200),
            child: Icon(_open ? Icons.close : Icons.add, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _speedAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: WaUi.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(label, style: WaUi.bodyMedium),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          elevation: 2,
          backgroundColor: WaUi.surface,
          foregroundColor: WaUi.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: WaUi.divider),
          ),
          child: Icon(icon, size: 22),
        ),
      ],
    );
  }
}

Color waAvatarColorFor(String seed) {
  if (seed.isEmpty) return WaUi.avatarPalette.first;
  final index = seed.codeUnits.fold<int>(0, (a, b) => a + b) %
      WaUi.avatarPalette.length;
  return WaUi.avatarPalette[index];
}

String waFormatContactDate(DateTime date, [BuildContext? context]) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$minute $period';
  }
  if (diff == 1) return context?.l10n.yesterday ?? 'Yesterday';
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm/${date.year}';
}

/// Contacts list loading placeholder — matches [WaChatListTile] rows.
/// Uses a [Column] (not [ListView]) so it can sit in [SliverFillRemaining].
class ContactsListShimmer extends StatelessWidget {
  final int itemCount;

  const ContactsListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itemCount, (index) {
            final nameWidth = 120.0 + (index % 3) * 28;
            final previewWidth = 160.0 + (index % 4) * 24;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 12, 21, 12),
                  child: Row(
                    children: [
                      const ShimmerBox(
                        width: 56,
                        height: 56,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: nameWidth,
                              height: 16,
                              borderRadius: 6,
                            ),
                            const SizedBox(height: 10),
                            ShimmerBox(
                              width: previewWidth,
                              height: 13,
                              borderRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != itemCount - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 95),
                    child: Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Color(0xFFE8E8E8),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

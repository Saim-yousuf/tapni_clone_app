import 'package:flutter/material.dart';
import 'package:tapni_app/models/contact_category.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class WaChatsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const WaChatsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WaUi.toolsTitle,
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: SizedBox(
        height: 48,
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
          cursorColor: WaUi.accent,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            filled: true,
            fillColor: WaUi.searchBg,
            hintText: hintText ?? context.l10n.searchEllipsis,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF667781),
              height: 1.2,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(
                Icons.search,
                size: 22,
                color: Color(0xFF667781),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 48,
            ),
            suffixIcon: !readOnly && controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFF667781),
                    onPressed: onClear,
                  )
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
      ),
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
        ? (selectedColor ?? WaUi.chipSelected)
        : Colors.transparent;
    final outline = selected
        ? (selectedBorderColor ?? selectedColor ?? WaUi.chipSelected)
        : (borderColor ?? WaUi.chipBorder);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WaUi.radiusPill),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                Text(
                  label,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: WaUi.primaryText,
                  ),
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
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        children: [
          WaPillFilterChip(
            label: context.l10n.all,
            selected: activeCategoryId == null,
            onTap: onAllTap,
          ),
          ...categories.map((category) {
            Color color;
            try {
              color = Color(int.parse(category.color.replaceAll('#', '0xff')));
            } catch (_) {
              color = WaUi.secondaryText;
            }
            return WaPillFilterChip(
              label: category.name,
              selected: activeCategoryId == category.id,
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () => onCategoryTap(category.id),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 2),
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
                    shape: BoxShape.circle,
                    border: Border.all(color: WaUi.chipBorder),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: WaUi.primaryText,
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
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.toolsScaffold,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    imageUrl: imageUrl,
                    initial: initial,
                    color: avatarColor,
                    ringColor: categoryColor,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: WaUi.chatName,
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
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (previewIcon != null) ...[
                              previewIcon!,
                              const SizedBox(width: 3),
                            ],
                            Expanded(
                              child: Text(
                                preview,
                                style: WaUi.chatPreview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount != null && unreadCount! > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(minWidth: 20),
                                height: 20,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
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
                ],
              ),
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.only(left: 81),
                child: Divider(height: 1, thickness: 0.4, color: WaUi.divider),
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
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final letter = (initial != null && initial!.isNotEmpty)
        ? initial!.substring(0, 1).toUpperCase()
        : '?';

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
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: !hasImage
            ? Text(letter, style: WaUi.avatarInitial)
            : null,
      ),
    );
  }
}

class WaContactEmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onScan;
  final VoidCallback onAdd;

  WaContactEmptyState({
    super.key,
    required this.isSearching,
    required this.onScan,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmptyIllustration(isSearching: isSearching),
            const SizedBox(height: 28),
            Text(
              isSearching ? context.l10n.noMatches : context.l10n.noContactsYet,
              style: WaUi.headline.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isSearching
                  ? context.l10n.tryADifferentNameEmailOrCompany
                  : context.l10n.scanAQRCodeOrAddSomeoneYouMetToBuildYourNetwork,
              style: WaUi.caption.copyWith(
                height: 1.45,
                fontSize: 14.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onScan,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: Text(
                        context.l10n.scanQR,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.promoButton.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: WaUi.buttonDark,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(WaUi.radiusPill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: WaUi.primaryText,
                      ),
                      label: Text(
                        context.l10n.add,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.promoButton.copyWith(
                          color: WaUi.primaryText,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WaUi.primaryText,
                        side: const BorderSide(
                          color: WaUi.chipBorder,
                          width: 1.2,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(WaUi.radiusPill),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  final bool isSearching;

  const _EmptyIllustration({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WaUi.searchBg,
              border: Border.all(color: WaUi.divider, width: 1),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.people_alt_outlined,
              size: 42,
              color: WaUi.buttonDark.withValues(alpha: 0.78),
            ),
          ),
          if (!isSearching)
            Positioned(
              right: 6,
              bottom: 10,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: WaUi.buttonDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
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

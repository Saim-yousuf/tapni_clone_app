import 'package:flutter/material.dart';
import 'package:tapni_app/models/contact_category.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WaUi.toolsTitle),
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
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  const WaChatSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: WaUi.navPill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          style: WaUi.body,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search name, email or company',
            hintStyle: WaUi.caption.copyWith(fontSize: 15),
            prefixIcon: const Icon(
              Icons.search,
              size: 22,
              color: WaUi.secondaryText,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: WaUi.secondaryText,
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
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

  const WaContactFilterChips({
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          _chip(
            label: 'All',
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
            return _chip(
              label: category.name,
              selected: activeCategoryId == category.id,
              dotColor: color,
              onTap: () => onCategoryTap(category.id),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ActionChip(
              label: const Icon(Icons.add, size: 16),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              backgroundColor: WaUi.navPill,
              side: BorderSide.none,
              onPressed: onAddCategory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        showCheckmark: false,
        labelStyle: WaUi.body.copyWith(
          fontSize: 14,
          color: selected ? Colors.white : WaUi.primaryText,
        ),
        backgroundColor: WaUi.navPill,
        selectedColor: WaUi.buttonDark,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onSelected: (_) => onTap(),
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
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
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
                            Expanded(
                              child: Text(
                                name,
                                style: WaUi.chatName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: highlightDate
                                  ? WaUi.chatDateHighlight
                                  : WaUi.chatDate,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (previewIcon != null) ...[
                              previewIcon!,
                              const SizedBox(width: 4),
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
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.only(left: 80),
                child: Divider(height: 1, thickness: 0.5, color: WaUi.divider),
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: 2)
            : null,
      ),
      child: CircleAvatar(
        radius: 24,
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

  const WaContactEmptyState({
    super.key,
    required this.isSearching,
    required this.onScan,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: WaUi.navPill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.people_outline,
                size: 40,
                color: WaUi.secondaryText.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No matches' : 'No contacts yet',
              style: WaUi.title,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different name, email, or company.'
                  : 'Scan a QR code or add someone you met to build your network.',
              style: WaUi.caption,
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: Text(
                      'Scan QR',
                      style: WaUi.bodyMedium.copyWith(color: Colors.white),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: WaUi.buttonDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(WaUi.radiusPill),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: Text('Add', style: WaUi.bodyMedium),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WaUi.primaryText,
                      side: const BorderSide(color: WaUi.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(WaUi.radiusPill),
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

class WaContactSpeedDial extends StatefulWidget {
  final VoidCallback onScan;
  final VoidCallback onAdd;
  final VoidCallback onFind;

  const WaContactSpeedDial({
    super.key,
    required this.onScan,
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
            label: 'Find user',
            icon: Icons.person_search_outlined,
            onTap: () => _run(widget.onFind),
          ),
          const SizedBox(height: 14),
          _speedAction(
            label: 'Add contact',
            icon: Icons.person_add_outlined,
            onTap: () => _run(widget.onAdd),
          ),
          const SizedBox(height: 14),
        ],
        FloatingActionButton.small(
          heroTag: 'contacts_more',
          onPressed: _toggle,
          elevation: 2,
          backgroundColor: WaUi.surface,
          foregroundColor: WaUi.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: WaUi.divider),
          ),
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_open ? Icons.close : Icons.add, size: 22),
          ),
        ),
        const SizedBox(height: 14),
        FloatingActionButton.extended(
          heroTag: 'contacts_scan',
          onPressed: widget.onScan,
          elevation: 3,
          backgroundColor: WaUi.buttonDark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
          label: Text('Scan', style: WaUi.bodyMedium.copyWith(color: Colors.white)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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

String waFormatContactDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$minute $period';
  }
  if (diff == 1) return 'Yesterday';
  if (diff < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
  return '${date.month}/${date.day}/${date.year.toString().substring(2)}';
}

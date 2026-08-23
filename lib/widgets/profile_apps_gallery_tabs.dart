import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/widgets/profile_gallery_grid.dart';

class ProfileAppsGalleryTabs extends StatefulWidget {
  final Widget apps;
  final List<GalleryItem> gallery;
  final bool isOwner;
  final bool uploading;
  final int initialTab;
  /// When true and [initialTab] is 0, Gallery opens by default.
  final bool appsEmpty;
  final VoidCallback? onAddPhotos;
  final Future<bool> Function(GalleryItem item)? onDeletePhoto;
  final ValueChanged<int>? onTabChanged;

  const ProfileAppsGalleryTabs({
    super.key,
    required this.apps,
    required this.gallery,
    this.isOwner = false,
    this.uploading = false,
    this.initialTab = 0,
    this.appsEmpty = false,
    this.onAddPhotos,
    this.onDeletePhoto,
    this.onTabChanged,
  });

  @override
  State<ProfileAppsGalleryTabs> createState() => _ProfileAppsGalleryTabsState();
}

class _ProfileAppsGalleryTabsState extends State<ProfileAppsGalleryTabs> {
  late int _index;

  int _resolveInitialIndex() {
    if (widget.appsEmpty && widget.initialTab == 0) return 1;
    return widget.initialTab.clamp(0, 1);
  }

  @override
  void initState() {
    super.initState();
    _index = _resolveInitialIndex();
  }

  @override
  void didUpdateWidget(covariant ProfileAppsGalleryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // First time we learn apps are empty, prefer Gallery once.
    if (!oldWidget.appsEmpty && widget.appsEmpty && _index == 0) {
      _index = 1;
    }
  }

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _SegmentedProfileTabs(
            index: _index,
            onChanged: _selectTab,
            appsLabel: l10n.profileTabApps,
            galleryLabel: l10n.profileTabGallery,
          ),
        ),
        const SizedBox(height: 8),
        if (_index == 0) widget.apps else ProfileGalleryGrid(
          items: widget.gallery,
          isOwner: widget.isOwner,
          uploading: widget.uploading,
          onAddPhotos: widget.onAddPhotos,
          onDeletePhoto: widget.onDeletePhoto,
        ),
      ],
    );
  }
}

class _SegmentedProfileTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final String appsLabel;
  final String galleryLabel;

  const _SegmentedProfileTabs({
    required this.index,
    required this.onChanged,
    required this.appsLabel,
    required this.galleryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegTab(
              selected: index == 0,
              icon: Icons.apps_rounded,
              label: appsLabel,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegTab(
              selected: index == 1,
              icon: Icons.grid_view_rounded,
              label: galleryLabel,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SegTab({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: selected ? 0.5 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFF111B21)
                    : const Color(0xFF8A9199),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF111B21)
                      : const Color(0xFF8A9199),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

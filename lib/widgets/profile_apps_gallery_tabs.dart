import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _SegmentedProfileTabs(
            index: _index,
            onChanged: _selectTab,
            appsLabel: l10n.profileTabApps,
            galleryLabel: l10n.profileTabGallery,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: _index == 0
                ? widget.apps
                : ProfileGalleryGrid(
                    items: widget.gallery,
                    isOwner: widget.isOwner,
                    uploading: widget.uploading,
                    onAddPhotos: widget.onAddPhotos,
                    onDeletePhoto: widget.onDeletePhoto,
                  ),
          ),
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
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              // Animated sliding indicator pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: SizedBox(
                  width: tabWidth,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Interactive Tab Labels Row
              Row(
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
            ],
          );
        },
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            letterSpacing: selected ? -0.2 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(selected),
                  size: 17,
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 7),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}


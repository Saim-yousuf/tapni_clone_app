import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/screens/gallery_viewer_screen.dart';
import 'package:tapni_app/widgets/profile_empty_state.dart';

class ProfileGalleryGrid extends StatelessWidget {
  final List<GalleryItem> items;
  final bool isOwner;
  final bool uploading;
  final VoidCallback? onAddPhotos;
  final Future<bool> Function(GalleryItem item)? onDeletePhoto;

  const ProfileGalleryGrid({
    super.key,
    required this.items,
    this.isOwner = false,
    this.uploading = false,
    this.onAddPhotos,
    this.onDeletePhoto,
  });

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryViewerScreen(
          items: items,
          initialIndex: index,
          isOwner: isOwner,
          onDelete: onDeletePhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isOwner) {
      return ProfileEmptyState(
        icon: Icons.photo_library_outlined,
        title: context.l10n.galleryEmpty,
        subtitle: context.l10n.galleryEmptySubtitle,
      );
    }

    if (items.isEmpty && isOwner) {
      return ProfileEmptyState(
        icon: Icons.photo_library_outlined,
        title: context.l10n.galleryEmpty,
        subtitle: context.l10n.galleryEmptyOwner,
        action: FilledButton.icon(
          onPressed: uploading ? null : onAddPhotos,
          icon: uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(context.l10n.addToGallery),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      );
    }

    final showAdd = isOwner && onAddPhotos != null;
    final count = items.length + (showAdd ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.2,
        mainAxisSpacing: 1.2,
      ),
      itemBuilder: (context, index) {
        if (showAdd && index == 0) {
          return _AddTile(
            uploading: uploading,
            onTap: onAddPhotos,
          );
        }
        final photoIndex = showAdd ? index - 1 : index;
        final item = items[photoIndex];
        return GestureDetector(
          onTap: () => _openViewer(context, photoIndex),
          child: Hero(
            tag: 'gallery-${item.id}',
            child: ColoredBox(
              color: const Color(0xFFF0F0F0),
              child: Image.network(
                item.url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(color: Color(0xFFF0F0F0));
                },
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFF0F0F0),
                  child: Icon(Icons.broken_image_outlined, color: Colors.black26),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  final bool uploading;
  final VoidCallback? onTap;

  const _AddTile({required this.uploading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: ColoredBox(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: uploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, size: 36, color: Colors.black87),
        ),
      ),
    );
  }
}

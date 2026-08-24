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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.black26),
                  ),
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Center(
          child: uploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black87,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 20,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

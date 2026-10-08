import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/screens/gallery_viewer_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class ProfileGalleryGrid extends StatelessWidget {
  final List<GalleryItem> items;
  final bool isOwner;
  final bool uploading;
  final VoidCallback? onAddPhotos;
  final Future<bool> Function(GalleryItem item)? onDeletePhoto;
  /// When true, empty owner state fills the screen like the Gallery empty mock.
  final bool fullScreenEmpty;

  const ProfileGalleryGrid({
    super.key,
    required this.items,
    this.isOwner = false,
    this.uploading = false,
    this.onAddPhotos,
    this.onDeletePhoto,
    this.fullScreenEmpty = false,
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

  Widget _emptyOwner(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/png/empty-gallery.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.photo_library_outlined,
            size: 88,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Create Your Gallery',
          textAlign: TextAlign.center,
          style: WaUi.toolsTitleOf(
            size: 22,
            weight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Add photos to showcase your business,\nproducts, and menu.',
          textAlign: TextAlign.center,
          style: WaUi.body.copyWith(
            fontSize: 15,
            height: 1.45,
            color: BarqodyChrome.secondaryText,
          ),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: SizedBox(
            width: double.infinity,
            height: WaUi.primaryButtonHeight,
            child: ElevatedButton(
              onPressed: uploading ? null : onAddPhotos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                shape: const StadiumBorder(),
              ),
              child: uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.l10n.addToGallery,
                      style: WaUi.promoButton.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );

    if (!fullScreenEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Center(child: content),
          ),
        );
      },
    );
  }

  Widget _emptyGuest(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/png/empty-gallery.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.galleryEmpty,
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: 18,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.galleryEmptySubtitle,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: BarqodyChrome.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isOwner) {
      return fullScreenEmpty
          ? Center(child: _emptyGuest(context))
          : _emptyGuest(context);
    }

    if (items.isEmpty && isOwner) {
      return _emptyOwner(context);
    }

    final showAdd = isOwner && onAddPhotos != null;
    final count = items.length + (showAdd ? 1 : 0);

    return GridView.builder(
      shrinkWrap: !fullScreenEmpty,
      physics: fullScreenEmpty
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFFF5F5F5),
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
                          color: Color(0xFF8E8E93),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
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
              : Image.asset(
                  'assets/images/png/add-camera.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.add_a_photo_outlined,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}

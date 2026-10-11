import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/screens/gallery_viewer_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

class ProfileGalleryGrid extends StatelessWidget {
  static const _title = 'Create Your Gallery';
  static const _subtitle =
      'Add photos to showcase your business, products, and menu.';
  static const _cta = 'Add Photos';

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
    final m = AuthScale.of(context);
    final iconSize = m.s(fullScreenEmpty ? 170 : 148);
    final sidePad = fullScreenEmpty ? m.s(22) : m.s(28);
    final topPad = fullScreenEmpty ? m.v(56) : m.v(40);
    final bottomPad = fullScreenEmpty ? m.v(40) : m.v(36);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/png/empty-gallery.png',
          width: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.photo_library_outlined,
            size: m.s(88),
            color: Colors.black,
          ),
        ),
        SizedBox(height: m.v(fullScreenEmpty ? 46 : 28)),
        Text(
          _title,
          textAlign: TextAlign.center,
          style: AppFonts.textStyle(
            fontSize: m.s(22),
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        SizedBox(height: m.v(fullScreenEmpty ? 22 : 10)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: m.s(8)),
          child: Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: m.s(15),
              fontWeight: FontWeight.w400,
              color: AuthUi.textMuted,
              height: 1.45,
            ),
          ),
        ),
        SizedBox(height: m.v(fullScreenEmpty ? 56 : 36)),
        _GalleryAddPhotosButton(
          label: _cta,
          uploading: uploading,
          onPressed: onAddPhotos,
        ),
      ],
    );

    if (!fullScreenEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(sidePad, topPad, sidePad, bottomPad),
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(sidePad, topPad, sidePad, bottomPad),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - topPad - bottomPad,
            ),
            // Top-weighted like the reference (extra space below the CTA).
            child: Align(
              alignment: const Alignment(0, -0.35),
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _emptyGuest(BuildContext context) {
    final m = AuthScale.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(m.s(28), m.v(48), m.s(28), m.v(36)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/png/empty-gallery.png',
            width: m.s(120),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.photo_library_outlined,
              size: m.s(72),
              color: Colors.black54,
            ),
          ),
          SizedBox(height: m.v(20)),
          Text(
            context.l10n.galleryEmpty,
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: m.s(18),
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          SizedBox(height: m.v(8)),
          Text(
            context.l10n.galleryEmptySubtitle,
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: m.s(14),
              fontWeight: FontWeight.w400,
              color: AuthUi.textMuted,
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

    final m = AuthScale.of(context);
    final gap = m.s(10);
    final radius = m.s(18);

    return GridView.builder(
      shrinkWrap: !fullScreenEmpty,
      physics: fullScreenEmpty
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(m.s(20), m.v(12), m.s(20), m.v(24)),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
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
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: m.s(18),
                        height: m.s(18),
                        child: const CircularProgressIndicator(
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
    final m = AuthScale.of(context);
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(m.s(18)),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Center(
          child: uploading
              ? SizedBox(
                  width: m.s(22),
                  height: m.s(22),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black87,
                  ),
                )
              : Image.asset(
                  'assets/images/png/add-camera.png',
                  width: m.s(36),
                  height: m.s(36),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.add_a_photo_outlined,
                    size: m.s(28),
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Pill CTA matching [PillButton] chrome, with upload spinner support.
class _GalleryAddPhotosButton extends StatelessWidget {
  final String label;
  final bool uploading;
  final VoidCallback? onPressed;

  const _GalleryAddPhotosButton({
    required this.label,
    required this.uploading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.buttonH;
    final enabled = !uploading && onPressed != null;

    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: AuthUi.primaryButtonShadow(m),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          minimumSize: Size(double.infinity, h),
          maximumSize: Size(double.infinity, h),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: uploading
            ? SizedBox(
                width: m.s(20),
                height: m.s(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: m.s(AuthUi.buttonLabelSize),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
      ),
    );
  }
}

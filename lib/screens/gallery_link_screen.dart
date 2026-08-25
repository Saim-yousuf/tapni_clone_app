import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/widgets/profile_gallery_grid.dart';

/// Full-screen gallery opened from a Gallery app/link tile.
class GalleryLinkScreen extends StatefulWidget {
  final List<GalleryItem> items;
  final bool isOwner;

  const GalleryLinkScreen({
    super.key,
    required this.items,
    this.isOwner = false,
  });

  @override
  State<GalleryLinkScreen> createState() => _GalleryLinkScreenState();
}

class _GalleryLinkScreenState extends State<GalleryLinkScreen> {
  Future<void> _addPhotos(ProfileProvider profileProvider) async {
    if (profileProvider.isGalleryUploading) return;
    if (profileProvider.profile.gallery.length >=
        ProfileProvider.galleryMaxItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.galleryMaxReached(ProfileProvider.galleryMaxItems),
          ),
        ),
      );
      return;
    }

    final picked = await pickMultiFile();
    if (picked == null || picked.files.isEmpty || !mounted) return;

    final remaining =
        ProfileProvider.galleryMaxItems - profileProvider.profile.gallery.length;
    final files = picked.files.take(remaining).toList();
    final res = await profileProvider.addGalleryPhotos(files);
    if (!mounted) return;

    final added = res.data is Map ? res.data['added'] as int? : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? (added != null && added > 1
                    ? context.l10n.photosAdded(added)
                    : context.l10n.photoAdded)
              : (res.message ?? context.l10n.couldNotAddPhotos),
        ),
      ),
    );
  }

  Future<bool> _deletePhoto(
    ProfileProvider profileProvider,
    GalleryItem item,
  ) async {
    final res = await profileProvider.deleteGalleryItem(item.id);
    return res.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(context.l10n.profileTabGallery),
      ),
      body: SafeArea(
        child: widget.isOwner
            ? Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    child: ProfileGalleryGrid(
                      items: profileProvider.profile.gallery,
                      isOwner: true,
                      uploading: profileProvider.isGalleryUploading,
                      onAddPhotos: () => _addPhotos(profileProvider),
                      onDeletePhoto: (item) =>
                          _deletePhoto(profileProvider, item),
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                child: ProfileGalleryGrid(
                  items: widget.items,
                  isOwner: false,
                ),
              ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';

/// Cached network image with shimmer placeholder for Explore and related UIs.
class CachedAppImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;
  final Color? shimmerBase;

  const CachedAppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.error,
    this.shimmerBase,
  });

  /// Use with [DecorationImage] / [BoxDecoration.image].
  static ImageProvider? provider(String? url) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return CachedNetworkImageProvider(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    final radius = borderRadius;
    final fallback = error ??
        ColoredBox(
          color: shimmerBase ?? const Color(0xFFE8E8E8),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 28, color: Color(0xFF9AA3AB)),
          ),
        );

    if (trimmed.isEmpty) return _wrap(fallback, radius);

    final loading = placeholder ??
        AppShimmer(
          child: SizedBox(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            child: ColoredBox(color: shimmerBase ?? const Color(0xFFE8E8E8)),
          ),
        );

    return _wrap(
      CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: const Duration(milliseconds: 180),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (_, _) => loading,
        errorWidget: (_, _, _) => fallback,
      ),
      radius,
    );
  }

  Widget _wrap(Widget child, BorderRadius? radius) {
    if (radius == null) return child;
    return ClipRRect(borderRadius: radius, child: child);
  }
}

/// Full-bleed shimmer block used as image placeholder.
class ImageShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

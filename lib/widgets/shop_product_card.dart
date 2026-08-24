import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';

/// Marketplace-style product card: image, badge, title, category, seller,
/// rating stars, divider, and orange price.
///
/// Height follows content (no empty spacer gap). Parent should only constrain
/// width — do not force a tall fixed height.
class ShopProductCard extends StatelessWidget {
  static const double radius = 16;
  static const double imageAspectRatio = 1.25; // width / height
  static const Color priceOrange = Color(0xFFEA580C);
  static const Color badgeBg = Color(0xFFFFEDD5);
  static const Color badgeText = Color(0xFFC2410C);
  static const Color categoryBg = Color(0xFFECFDF5);
  static const Color categoryBorder = Color(0xFFA7F3D0);
  static const Color categoryText = Color(0xFF047857);
  static const Color starEmpty = Color(0xFFCBD5E1);
  static const Color starFilled = Color(0xFFF5A623);

  final String title;
  final String? imageUrl;
  final String category;
  final String sellerName;
  final double price;
  final double avgRating;
  final String badgeLabel;
  final VoidCallback onTap;
  final bool isDark;

  const ShopProductCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.category = '',
    this.sellerName = '',
    this.price = 0,
    this.avgRating = 0,
    this.badgeLabel = 'Shop Product',
    required this.onTap,
    this.isDark = false,
  });

  /// Approximate card height for a given width (grid / skeleton).
  static double heightForWidth(double width) {
    final imageH = width / imageAspectRatio;
    // title(2) + category + seller + stars + divider + price + padding
    // Keep headroom for text scale / long labels so grids don't overflow.
    const contentH = 142.0;
    return imageH + contentH;
  }

  static String formatPrice(double price, {String freeLabel = 'Free'}) {
    if (price <= 0) return freeLabel;
    final parts = price.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return 'Rs ${buf.toString()}.${parts[1]}';
  }

  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final sellerColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor = isDark ? Colors.white12 : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE8E8E8),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: imageAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: badgeText,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleCase(title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (category.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                              : categoryBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF34D399).withValues(alpha: 0.4)
                                : categoryBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 10,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : categoryText,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                category.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF6EE7B7)
                                      : categoryText,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (sellerName.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 12,
                            color: sellerColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'by ${sellerName.trim()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: sellerColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    _StarRow(rating: avgRating),
                    const SizedBox(height: 8),
                    Divider(height: 1, thickness: 1, color: dividerColor),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: priceOrange,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = imageUrl?.trim() ?? '';
    final fallback = ColoredBox(
      color: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF4F5F7),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 36,
        color: isDark ? const Color(0xFF8A8D91) : const Color(0xFF9AA3AB),
      ),
    );
    if (url.isEmpty) return fallback;
    return CachedAppImage(
      url: url,
      fit: BoxFit.cover,
      placeholder: const ImageShimmerPlaceholder(),
      error: ColoredBox(
        color: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF4F5F7),
        child: Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: isDark ? const Color(0xFF8A8D91) : const Color(0xFF9AA3AB),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;

  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = rating >= i + 0.5;
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 1.5 : 0),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: filled
                ? ShopProductCard.starFilled
                : ShopProductCard.starEmpty,
          ),
        );
      }),
    );
  }
}

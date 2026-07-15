import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class CatalogProductCard extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onTap;
  final int? cartQty;
  final bool isService;

  const CatalogProductCard({
    super.key,
    required this.item,
    required this.onTap,
    this.cartQty,
    this.isService = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                      child: _buildImage(),
                    ),
                    if (cartQty != null && cartQty! > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$cartQty',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.price > 0
                          ? 'Rs ${item.price.toStringAsFixed(0)}'
                          : 'Free',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isService) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            context.l10n.book,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    final image = item.imageUrl.trim();
    if (image.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.fastfood_outlined,
            size: 36,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }
    return Image.network(
      image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/widgets/shop_product_card.dart';

class CatalogProductCard extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onTap;
  final int? cartQty;
  final bool isService;
  final String? currency;

  const CatalogProductCard({
    super.key,
    required this.item,
    required this.onTap,
    this.cartQty,
    this.isService = false,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        children: [
          ShopProductCard(
            title: item.name,
            imageUrl: item.imageUrl,
            category: item.category,
            price: item.price,
            currency: currency ?? 'PKR',
            badgeLabel: isService ? 'Service' : 'Shop Product',
            onTap: onTap,
            isDark: isDark,
          ),
          if (cartQty != null && cartQty! > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cartQty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

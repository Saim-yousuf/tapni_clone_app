import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';

class CatalogProductCard extends StatelessWidget {
  static const double radius = 16;
  static const double _imageAspectRatio = 1.0;
  static const String _plusAsset = 'assets/images/png/plus-icon.png';

  final CatalogItem item;
  final VoidCallback onTap;
  final int? cartQty;
  final bool isService;
  final String? currency;
  final String? durationLabel;

  const CatalogProductCard({
    super.key,
    required this.item,
    required this.onTap,
    this.cartQty,
    this.isService = false,
    this.currency,
    this.durationLabel,
  });

  /// Grid row height for [menu_catalog_sheet] and similar layouts.
  static double heightForWidth(double width, {bool isService = false}) {
    final imageH = width / _imageAspectRatio;
    final contentH = isService ? 108.0 : 92.0;
    return imageH + contentH;
  }

  String get _priceLabel {
    final price = item.displayPrice;
    if (price <= 0) {
      return formatMoney(0, currency: currency, freeLabel: 'Free');
    }
    return formatMoney(price, currency: currency);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: BarqodyChrome.divider, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageArea(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 36, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontSize: isService ? 16 : 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          if (isService &&
                              durationLabel != null &&
                              durationLabel!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              durationLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.body.copyWith(
                                fontSize: 12,
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _AddCircleButton(onTap: onTap),
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

  Widget _buildImageArea(BuildContext context) {
    final topRadius = const BorderRadius.vertical(top: Radius.circular(radius));
    return AspectRatio(
      aspectRatio: _imageAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: topRadius,
            child: CachedAppImage(
              url: item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              borderRadius: topRadius,
              error: ColoredBox(
                color: BarqodyChrome.fieldFill,
                child: Icon(
                  isService
                      ? Icons.spa_outlined
                      : Icons.fastfood_outlined,
                  size: 36,
                  color: BarqodyChrome.secondaryText,
                ),
              ),
            ),
          ),
          if (cartQty != null && cartQty! > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$cartQty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Image.asset(
              CatalogProductCard._plusAsset,
              width: 14,
              height: 14,
              color: Colors.white,
              errorBuilder: (_, _, _) => const Icon(
                Icons.add,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';
import 'package:tapni_app/widgets/service_booking_sheet.dart';

/// Result after booking a service from the detail sheet.
class ServiceDetailBookingResult {
  final String bookingDate;
  final String bookingTime;
  final bool bookNow;
  final int quantity;

  const ServiceDetailBookingResult({
    required this.bookingDate,
    required this.bookingTime,
    required this.bookNow,
    this.quantity = 1,
  });
}

Future<ServiceDetailBookingResult?> showServiceDetailSheet({
  required BuildContext context,
  required CatalogItem item,
  required String businessId,
  required String businessLinkId,
  required String businessName,
  String? businessPhoto,
  String? businessUsername,
  bool businessVerified = false,
  String? currency,
  VoidCallback? onProviderTap,
}) {
  return showModalBottomSheet<ServiceDetailBookingResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ServiceDetailSheet(
      item: item,
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName,
      businessPhoto: businessPhoto,
      businessUsername: businessUsername,
      businessVerified: businessVerified,
      currency: currency,
      onProviderTap: onProviderTap,
    ),
  );
}

class _ServiceDetailSheet extends StatelessWidget {
  final CatalogItem item;
  final String businessId;
  final String businessLinkId;
  final String businessName;
  final String? businessPhoto;
  final String? businessUsername;
  final bool businessVerified;
  final String? currency;
  final VoidCallback? onProviderTap;

  const _ServiceDetailSheet({
    required this.item,
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    this.businessPhoto,
    this.businessUsername,
    this.businessVerified = false,
    this.currency,
    this.onProviderTap,
  });

  Future<void> _book(BuildContext context) async {
    final result = await showServiceBookingSheet(
      context: context,
      item: item,
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName,
      currency: currency,
    );
    if (result == null || !context.mounted) return;
    Navigator.pop(
      context,
      ServiceDetailBookingResult(
        bookingDate: result.bookingDate,
        bookingTime: result.bookingTime,
        bookNow: result.bookNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceLabel = item.displayPrice > 0
        ? formatMoney(item.displayPrice, currency: currency)
        : formatMoney(0, currency: currency, freeLabel: 'Free');
    final photo = businessPhoto?.trim() ?? '';
    final hasPhoto = photo.isNotEmpty;
    final initial =
        businessName.isNotEmpty ? businessName[0].toUpperCase() : '?';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Center(child: SheetDragHandle()),
            const SizedBox(height: 8),
            BarqodyTitleBar(
              title: 'Service',
              onBack: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  12,
                  BarqodyChrome.sidePad,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(url: item.imageUrl),
                    const SizedBox(height: 18),
                    Text(
                      item.name,
                      style: WaUi.toolsTitleOf(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceLabel,
                            style: WaUi.toolsTitleOf(
                              size: 22,
                              weight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (item.durationLabel.isNotEmpty)
                          Text(
                            item.durationLabel,
                            style: WaUi.body.copyWith(
                              fontSize: 13,
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: BarqodyChrome.divider),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: WaUi.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description.trim(),
                        style: WaUi.body.copyWith(
                          fontSize: 14,
                          color: BarqodyChrome.bodyText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: BarqodyChrome.divider),
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: onProviderTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: BarqodyChrome.fieldFill,
                              backgroundImage:
                                  hasPhoto ? NetworkImage(photo) : null,
                              child: hasPhoto
                                  ? null
                                  : Text(
                                      initial,
                                      style: WaUi.avatarInitial,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          businessName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: WaUi.body.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (businessVerified) ...[
                                        const SizedBox(width: 6),
                                        Image.asset(
                                          'assets/images/png/verified-badge.png',
                                          width: 16,
                                          height: 16,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: BarqodyChrome.star,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if ((businessUsername ?? '').isNotEmpty)
                                    Text(
                                      '@$businessUsername',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: WaUi.body.copyWith(
                                        fontSize: 12,
                                        color: BarqodyChrome.secondaryText,
                                      ),
                                    )
                                  else if (item.description.trim().isNotEmpty)
                                    Text(
                                      item.description.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: WaUi.body.copyWith(
                                        fontSize: 12,
                                        color: BarqodyChrome.secondaryText,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: BarqodyChrome.divider),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PillButton(
                label: 'Book Service',
                onPressed: () => _book(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String url;

  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    final image = url.trim();
    if (image.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          height: 200,
          width: double.infinity,
          color: BarqodyChrome.fieldFill,
          child: const Icon(
            Icons.spa_outlined,
            size: 48,
            color: BarqodyChrome.secondaryText,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedAppImage(
        url: image,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        borderRadius: radius,
      ),
    );
  }
}

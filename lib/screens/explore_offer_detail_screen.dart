import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class ExploreOfferDetailScreen extends StatelessWidget {
  final ExploreOffer offer;

  const ExploreOfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final image = (offer.logo != null && offer.logo!.isNotEmpty)
        ? offer.logo
        : offer.businessPhoto;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Reward offer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3DC),
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: WaUi.headline.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (offer.stamps > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${offer.stamps} stamps',
                              style: WaUi.label.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: double.infinity,
                  child: image != null && image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.card_giftcard, size: 42),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.card_giftcard, size: 42),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            offer.businessName,
            style: WaUi.title.copyWith(fontWeight: FontWeight.w700),
          ),
          if (offer.distanceKm != null) ...[
            const SizedBox(height: 4),
            Text(
              '${offer.distanceKm!.toStringAsFixed(1)} km away',
              style: WaUi.label.copyWith(color: WaUi.secondaryText),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'About this offer',
            style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            offer.description.trim().isNotEmpty
                ? offer.description
                : 'Collect stamps and unlock rewards at this business.',
            style: WaUi.body.copyWith(
              color: WaUi.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: WaPrimaryButton(
            label: 'View business',
            onPressed: () {
              if (offer.businessUsername.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScannedProfileScreen(
                    username: offer.businessUsername,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

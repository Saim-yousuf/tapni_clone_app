import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/utils/explore_actions.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

enum ExploreSeeAllKind { offers, items, services, businesses }

class ExploreSeeAllScreen extends StatelessWidget {
  final ExploreSeeAllKind kind;
  final List<ExploreOffer> offers;
  final List<ExploreItem> items;
  final List<ExploreBusiness> businesses;

  const ExploreSeeAllScreen({
    super.key,
    required this.kind,
    this.offers = const [],
    this.items = const [],
    this.businesses = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffold = isDark ? const Color(0xFF111111) : Colors.white;
    final primaryText =
        isDark ? Colors.white : WaUi.primaryText;

    return Scaffold(
      backgroundColor: scaffold,
      appBar: AppBar(
        backgroundColor: scaffold,
        foregroundColor: primaryText,
        title: Text('Reward Offers'),
      ),
      body: offers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 42,
                      color: WaUi.secondaryText.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reward offers nearby',
                      style: WaUi.title.copyWith(color: primaryText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Loyalty offers from nearby businesses will appear here.',
                      style: WaUi.caption.copyWith(color: WaUi.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                const pad = 16.0;
                final cardW = (constraints.maxWidth - pad * 2 - spacing) / 2;
                final cardH = _RewardSeeAllCard.heightForWidth(cardW);
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(pad, 8, pad, 28),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: cardH,
                  ),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return _RewardSeeAllCard(
                      offer: offer,
                      isDark: isDark,
                      onTap: () => ExploreActions.openOffer(context, offer),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _RewardSeeAllCard extends StatelessWidget {
  static const double previewRatio = 0.72;
  static const double footerHeight = 110;

  static double heightForWidth(double width) {
    return (width / previewRatio) + footerHeight;
  }

  final ExploreOffer offer;
  final bool isDark;
  final VoidCallback onTap;

  const _RewardSeeAllCard({
    required this.offer,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = offer.toRewardProgram();
    final surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE2E8F0);
    final primaryText = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : WaUi.secondaryText;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border.withValues(alpha: 0.9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    offer.hasDesign
                        ? ColoredBox(
                            color: surface,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    height: constraints.maxWidth /
                                        offer.design!.aspectRatio
                                            .clamp(0.55, 0.85),
                                    child: LoyaltyCardDesignRenderer(
                                      design: offer.design!,
                                      borderRadius: 0,
                                      shadows: const [],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : _ClassicPreview(program: program),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF111827), Color(0xFF374151)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.card_giftcard_rounded,
                              size: 12,
                              color: Color(0xFF10A375),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'REWARD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: footerHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title.isNotEmpty
                            ? offer.title
                            : 'Special Reward Offer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        offer.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'View Offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassicPreview extends StatelessWidget {
  final RewardProgram program;

  const _ClassicPreview({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = program.theme;
    return ColoredBox(
      color: theme.cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.label.isNotEmpty)
              Text(
                program.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.cardTextColor.withValues(alpha: 0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.cardTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: List.generate(
                program.stamps.clamp(1, 8),
                (_) => RewardStampSlot(
                  filled: false,
                  theme: theme,
                  stampIconUrl: program.stampIcon,
                  unstampIconUrl: program.unstampIcon,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

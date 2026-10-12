import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_enroll_qr_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

/// Figma `Offer` — stamp card + Enroll Me / Enrolled CTA + visit business.
class ExploreOfferDetailScreen extends StatefulWidget {
  final ExploreOffer offer;

  const ExploreOfferDetailScreen({super.key, required this.offer});

  @override
  State<ExploreOfferDetailScreen> createState() =>
      _ExploreOfferDetailScreenState();
}

class _ExploreOfferDetailScreenState extends State<ExploreOfferDetailScreen> {
  bool _loadingEnrollment = true;
  RewardEnrollment? _enrollment;

  ExploreOffer get offer => widget.offer;

  bool get _isEnrolled => _enrollment != null;

  int get _filledStamps => _enrollment?.stamps ?? 0;

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    setState(() => _loadingEnrollment = true);
    try {
      final res = await RewardRepo().getMyEnrollments();
      if (!mounted) return;
      RewardEnrollment? match;
      if (res.success && res.data != null) {
        final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
        final list = raw is List ? raw : const [];
        for (final item in list) {
          if (item is! Map) continue;
          final e = RewardEnrollment.fromJson(
            Map<String, dynamic>.from(item),
          );
          final progId = e.programId.isNotEmpty
              ? e.programId
              : (e.program?.id ?? '');
          if (progId == offer.id) {
            match = e;
            break;
          }
        }
      }
      setState(() {
        _enrollment = match;
        _loadingEnrollment = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enrollment = null;
        _loadingEnrollment = false;
      });
    }
  }

  Future<void> _onEnrollMe() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerEnrollQrScreen(
          businessName: offer.businessName,
        ),
      ),
    );
    if (mounted) await _loadEnrollment();
  }

  void _openBusiness() {
    if (offer.businessUsername.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ScannedProfileScreen(username: offer.businessUsername),
        ),
      );
      return;
    }
    if (offer.businessId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(user: offer.businessId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStamps = offer.stamps > 0 ? offer.stamps : 12;
    final logo = (offer.logo != null && offer.logo!.isNotEmpty)
        ? offer.logo
        : offer.businessPhoto;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Offer'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OfferStampCard(
                      offer: offer,
                      totalStamps: totalStamps,
                      filledStamps: _filledStamps,
                      logoUrl: logo,
                    ),
                    const SizedBox(height: 22),
                    _EnrollCta(
                      loading: _loadingEnrollment,
                      enrolled: _isEnrolled,
                      onEnroll: _onEnrollMe,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Visit ${offer.businessName}',
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: BarqodyChrome.divider,
                    ),
                    InkWell(
                      onTap: _openBusiness,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Container(
                                width: 44,
                                height: 44,
                                color: BarqodyChrome.fieldFill,
                                child: logo != null && logo.isNotEmpty
                                    ? Image.network(
                                        logo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _Initial(name: offer.businessName),
                                      )
                                    : _Initial(name: offer.businessName),
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
                                          offer.businessName,
                                          style: WaUi.body.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Image.asset(
                                        'assets/images/png/verified-badge.png',
                                        width: 16,
                                        height: 16,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Color(0xFFFFCC00),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    offer.description.trim().isNotEmpty
                                        ? offer.description
                                        : 'Tap to view this business profile',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: WaUi.body.copyWith(
                                      fontSize: 13,
                                      color: BarqodyChrome.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: BarqodyChrome.divider,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollCta extends StatelessWidget {
  final bool loading;
  final bool enrolled;
  final VoidCallback onEnroll;

  const _EnrollCta({
    required this.loading,
    required this.enrolled,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: WaUi.primaryButtonHeight,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    if (enrolled) {
      return SizedBox(
        height: WaUi.primaryButtonHeight,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBDBDBD),
            disabledBackgroundColor: const Color(0xFFBDBDBD),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'Enrolled',
            style: WaUi.promoButton.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: WaUi.primaryButtonHeight,
      child: ElevatedButton(
        onPressed: onEnroll,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.28),
          shape: const StadiumBorder(),
        ),
        child: Text(
          'Enroll Me',
          style: WaUi.promoButton.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OfferStampCard extends StatelessWidget {
  final ExploreOffer offer;
  final int totalStamps;
  final int filledStamps;
  final String? logoUrl;

  const _OfferStampCard({
    required this.offer,
    required this.totalStamps,
    required this.filledStamps,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (offer.hasDesign) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LoyaltyCardDesignRenderer(
            design: offer.design!,
            filledStamps: filledStamps,
            borderRadius: 14,
            shadows: const [],
          ),
        ),
      );
    }

    final theme = offer.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (logoUrl != null && logoUrl!.isNotEmpty)
            ClipOval(
              child: Image.network(
                logoUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _Initial(name: offer.businessName, size: 64),
              ),
            )
          else
            _Initial(name: offer.businessName, size: 64),
          const SizedBox(height: 12),
          Text(
            offer.businessName,
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: 18,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            offer.title,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = totalStamps <= 6
                  ? 3
                  : totalStamps <= 9
                      ? 3
                      : 4;
              const gap = 10.0;
              final size =
                  ((constraints.maxWidth - gap * (cols - 1)) / cols)
                      .clamp(36.0, 56.0);
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: gap,
                runSpacing: gap,
                children: List.generate(totalStamps, (index) {
                  return RewardStampSlot(
                    filled: index < filledStamps,
                    theme: theme,
                    size: size,
                    stampIconUrl: offer.stampIcon,
                    unstampIconUrl: offer.unstampIcon,
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;
  final double size;

  const _Initial({required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: BarqodyChrome.fieldFill,
      child: Text(
        letter,
        style: WaUi.body.copyWith(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

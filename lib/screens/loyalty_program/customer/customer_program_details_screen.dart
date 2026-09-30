import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/screens/loyalty_program/customer/stamp_history_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class CustomerProgramDetailsScreen extends StatelessWidget {
  final RewardEnrollment enrollment;

  const CustomerProgramDetailsScreen({super.key, required this.enrollment});

  static const _muted = Color(0xFF6B6B6B);
  static const _howToBg = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final theme = program?.theme ?? RewardTheme();
    final totalStamps = program?.stamps ?? 10;
    final currentStamps = enrollment.stamps;
    final businessName =
        program?.displayBusinessName ?? context.l10n.businessLabel;
    final title = program?.title ?? context.l10n.program;
    final photo = program?.businessPhoto;
    final logo = program?.logo;
    final avatarUrl = (photo != null && photo.isNotEmpty)
        ? photo
        : (logo != null && logo.isNotEmpty ? logo : null);
    final rewardName = _rewardNoun(title);
    final howToLines = _howToEarnLines(
      totalStamps: totalStamps,
      rewardName: rewardName,
    );

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Reward',
              trailing: CircleAssetButton(
                asset: 'assets/images/png/scan-icon-1.png',
                iconSize: 18,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  12,
                  BarqodyChrome.sidePad,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StampHeroCard(
                      enrollment: enrollment,
                      theme: theme,
                      businessName: businessName,
                      title: title,
                      avatarUrl: avatarUrl,
                      currentStamps: currentStamps,
                      totalStamps: totalStamps,
                    ),
                    const SizedBox(height: 16),
                    _HowToEarnCard(
                      lines: howToLines,
                      background: _howToBg,
                      muted: _muted,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Visit $businessName',
                      style: WaUi.toolsTitleOf(
                        size: 20,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _VisitBusinessRow(
                      name: businessName,
                      subtitle: program?.description.isNotEmpty == true
                          ? program!.description
                          : 'Tap to view this business profile',
                      avatarUrl: avatarUrl,
                      muted: _muted,
                      onTap: () {
                        final id = program?.businessId;
                        if (id == null || id.isEmpty) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScannedProfileScreen(user: id),
                          ),
                        );
                      },
                      enabled: program?.businessId != null &&
                          program!.businessId!.isNotEmpty,
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE8E8E8),
                    ),
                    const SizedBox(height: 20),
                    PillButton(
                      label: 'View History',
                      filled: false,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StampHistoryScreen(
                              enrollment: enrollment,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _rewardNoun(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('coffee')) return 'Coffee';
    if (lower.contains('pizza')) return 'Pizza';
    if (lower.contains('drink')) return 'Drink';
    return 'reward';
  }

  static List<String> _howToEarnLines({
    required int totalStamps,
    required String rewardName,
  }) {
    return [
      'Make a purchase → Earn 1 Stamp',
      'Complete $totalStamps stamps to unlock your free $rewardName.',
    ];
  }
}

class _StampHeroCard extends StatelessWidget {
  final RewardEnrollment enrollment;
  final RewardTheme theme;
  final String businessName;
  final String title;
  final String? avatarUrl;
  final int currentStamps;
  final int totalStamps;

  const _StampHeroCard({
    required this.enrollment,
    required this.theme,
    required this.businessName,
    required this.title,
    required this.avatarUrl,
    required this.currentStamps,
    required this.totalStamps,
  });

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: program?.hasDesign == true
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LoyaltyCardDesignRenderer(
                    design: program!.design!,
                    filledStamps: currentStamps,
                    borderRadius: 16,
                    shadows: const [],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                if (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _LogoFallback(
                        name: businessName,
                        theme: theme,
                      ),
                    ),
                  )
                else
                  _LogoFallback(name: businessName, theme: theme),
                const SizedBox(height: 12),
                Text(
                  businessName,
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = totalStamps <= 6
                        ? 3
                        : totalStamps <= 9
                            ? 3
                            : 4;
                    final gap = 12.0;
                    final size =
                        ((constraints.maxWidth - gap * (cols - 1)) / cols)
                            .clamp(44.0, 64.0);
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      alignment: WrapAlignment.center,
                      children: List.generate(totalStamps, (i) {
                        return RewardStampSlot(
                          filled: i < currentStamps,
                          theme: theme,
                          stampIconUrl: program?.stampIcon,
                          unstampIconUrl: program?.unstampIcon,
                          size: size,
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

class _LogoFallback extends StatelessWidget {
  final String name;
  final RewardTheme theme;

  const _LogoFallback({required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.stampColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: theme.cardTextColor,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _HowToEarnCard extends StatelessWidget {
  final List<String> lines;
  final Color background;
  final Color muted;

  const _HowToEarnCard({
    required this.lines,
    required this.background,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO EARN',
            style: WaUi.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE0E0E0),
                ),
              ),
            Text(
              lines[i],
              style: WaUi.body.copyWith(
                fontSize: 14,
                color: muted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitBusinessRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final Color muted;
  final VoidCallback onTap;
  final bool enabled;

  const _VisitBusinessRow({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.muted,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFF2F2F7),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF2F2F7),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/png/check-icon-1.png',
                          width: 14,
                          height: 14,
                          color: const Color(0xFFFFCC00),
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.verified,
                            size: 14,
                            color: Color(0xFFFFCC00),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

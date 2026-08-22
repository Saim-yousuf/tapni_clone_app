import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class CustomerProgramDetailsScreen extends StatelessWidget {
  final RewardEnrollment enrollment;

  const CustomerProgramDetailsScreen({super.key, required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final theme = program?.theme ?? RewardTheme();
    final totalStamps = program?.stamps ?? 10;
    final currentStamps = enrollment.stamps;
    final remaining = (totalStamps - currentStamps).clamp(0, totalStamps);
    final text = theme.screenTextColor;
    final businessName =
        program?.displayBusinessName ?? context.l10n.businessLabel;
    final title = program?.title ?? context.l10n.program;
    final photo = program?.businessPhoto;
    final logo = program?.logo;
    final avatarUrl = (photo != null && photo.isNotEmpty)
        ? photo
        : (logo != null && logo.isNotEmpty ? logo : null);

    return Scaffold(
      backgroundColor: theme.screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.screenBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          program?.label.isNotEmpty == true
              ? program!.label
              : context.l10n.rewardProgram,
          style: WaUi.headline.copyWith(
            color: text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              _BusinessIdentity(
                name: businessName,
                avatarUrl: avatarUrl,
                initial: businessName.isNotEmpty
                    ? businessName[0].toUpperCase()
                    : '?',
                theme: theme,
                onVisit: () {
                  final id = program?.businessId;
                  if (id == null || id.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScannedProfileScreen(user: id),
                    ),
                  );
                },
                canVisit: program?.businessId != null &&
                    program!.businessId!.isNotEmpty,
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: WaUi.headline.copyWith(
                  color: text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.4,
                ),
              ),
              if (program?.description.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    program!.description,
                    textAlign: TextAlign.center,
                    style: WaUi.body.copyWith(
                      color: text.withValues(alpha: 0.55),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Align(
                child: FractionallySizedBox(
                  widthFactor: 0.84,
                  child: program?.hasDesign == true
                      ? LoyaltyCardDesignRenderer(
                          design: program!.design!,
                          filledStamps: currentStamps,
                          borderRadius: 20,
                        )
                      : _ClassicStampCard(
                          theme: theme,
                          program: program,
                          currentStamps: currentStamps,
                          totalStamps: totalStamps,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.stampsProgress(currentStamps, totalStamps),
                style: WaUi.label.copyWith(
                  color: text.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 24),
              if (enrollment.isCompleted)
                _StatusCard(
                  icon: Icons.celebration_rounded,
                  iconColor: const Color(0xFF1B8A4A),
                  background: const Color(0xFF1B8A4A).withValues(alpha: 0.08),
                  border: const Color(0xFF1B8A4A).withValues(alpha: 0.28),
                  title: context.l10n.rewardCompletedShowThisCardToRedeem,
                  titleColor: const Color(0xFF1B8A4A),
                )
              else
                _StatusCard(
                  icon: Icons.storefront_outlined,
                  iconColor: text.withValues(alpha: 0.55),
                  background: text.withValues(alpha: 0.04),
                  border: text.withValues(alpha: 0.08),
                  title: remaining == 0
                      ? context.l10n.almostThere
                      : '$remaining more stamp${remaining == 1 ? '' : 's'} to go',
                  titleColor: text,
                  subtitle: context.l10n.visitBusinessToCollectStamps(
                    businessName,
                  ),
                  subtitleColor: text.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessIdentity extends StatelessWidget {
  const _BusinessIdentity({
    required this.name,
    required this.avatarUrl,
    required this.initial,
    required this.theme,
    required this.onVisit,
    required this.canVisit,
  });

  final String name;
  final String? avatarUrl;
  final String initial;
  final RewardTheme theme;
  final VoidCallback onVisit;
  final bool canVisit;

  @override
  Widget build(BuildContext context) {
    final text = theme.screenTextColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: text.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.cardBackgroundColor,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: theme.cardTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.bodyMedium.copyWith(
                color: text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canVisit ? onVisit : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Visit',
              style: WaUi.bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicStampCard extends StatelessWidget {
  const _ClassicStampCard({
    required this.theme,
    required this.program,
    required this.currentStamps,
    required this.totalStamps,
  });

  final RewardTheme theme;
  final RewardProgram? program;
  final int currentStamps;
  final int totalStamps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(totalStamps, (i) {
          return RewardStampSlot(
            filled: i < currentStamps,
            theme: theme,
            stampIconUrl: program?.stampIcon,
            unstampIconUrl: program?.unstampIcon,
            size: 52,
          );
        }),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.border,
    required this.title,
    required this.titleColor,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color border;
  final String title;
  final Color titleColor;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WaUi.bodyMedium.copyWith(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: WaUi.caption.copyWith(
                color: subtitleColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

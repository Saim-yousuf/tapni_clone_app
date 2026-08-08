import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class CustomerProgramDetailsScreen extends StatelessWidget {
  final RewardEnrollment enrollment;

  CustomerProgramDetailsScreen({super.key, required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final theme = program?.theme ?? RewardTheme();
    final totalStamps = program?.stamps ?? 10;
    final currentStamps = enrollment.stamps;
    final remaining = (totalStamps - currentStamps).clamp(0, totalStamps);

    return Scaffold(
      backgroundColor: theme.screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.screenBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.screenTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          program?.label.isNotEmpty == true ? program!.label : context.l10n.rewardProgram,
          style: TextStyle(
            color: theme.screenTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (program?.businessPhoto != null &&
                  program!.businessPhoto!.isNotEmpty)
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(program.businessPhoto!),
                )
              else if (program != null)
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.cardBackgroundColor,
                  child: Text(
                    program.displayBusinessName.isNotEmpty
                        ? program.displayBusinessName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.cardTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                program?.displayBusinessName ?? context.l10n.businessLabel,
                style: TextStyle(
                  color: theme.screenTextColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              if (program?.logo.isNotEmpty == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    program!.logo,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              if (program?.logo.isNotEmpty == true) const SizedBox(height: 12),

              Text(
                program?.title ?? context.l10n.program,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.screenTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (program?.description.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  program!.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.screenTextColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              if (program?.hasDesign == true)
                Column(
                  children: [
                    LoyaltyCardDesignRenderer(
                      design: program!.design!,
                      filledStamps: currentStamps,
                      borderRadius: 22,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.stampsProgress(currentStamps, totalStamps),
                      style: TextStyle(
                        color: theme.screenTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        context.l10n.stampsProgress(currentStamps, totalStamps),
                        style: TextStyle(
                          color: theme.cardTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: List.generate(totalStamps, (i) {
                          final filled = i < currentStamps;
                          return RewardStampSlot(
                            filled: filled,
                            theme: theme,
                            stampIconUrl: program?.stampIcon,
                            unstampIconUrl: program?.unstampIcon,
                            size: 60,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),

              if (enrollment.isCompleted)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.rewardCompletedShowThisCardToRedeem,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.screenTextColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.screenTextColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_activity_outlined,
                        color: theme.screenTextColor.withOpacity(0.6),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        remaining == 0
                            ? context.l10n.almostThere
                            : '$remaining more stamp${remaining == 1 ? '' : 's'} to complete',
                        style: TextStyle(
                          color: theme.screenTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.visitBusinessToCollectStamps(
                          program?.displayBusinessName ?? context.l10n.businessLabel,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.screenTextColor.withOpacity(0.6),
                          fontSize: 13,
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
}

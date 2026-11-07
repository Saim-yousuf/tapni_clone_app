import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/business_profile_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

/// Returns true if business profile is complete; otherwise shows checklist sheet.
///
/// When the user taps Continue setup, parent modal sheets (e.g. Add Link) are
/// dismissed and [BusinessProfileScreen] opens on the root navigator.
Future<bool> ensureBusinessProfileComplete(BuildContext context) async {
  final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
  final completeness = BusinessCompleteness.fromProfile(profile);
  if (completeness.isComplete) return true;

  final rootNav = Navigator.of(context, rootNavigator: true);
  final goToSetup = await showBusinessCompletenessSheet(context, completeness);
  if (goToSetup != true) return false;

  // Drop Add Link / other modals so Business Profile is not buried under them.
  rootNav.popUntil((route) => route is PageRoute);
  await rootNav.push(
    AppPageRoute(builder: (_) => const BusinessProfileScreen()),
  );
  return false;
}

/// `true` = Continue setup, `false` / null = dismissed.
Future<bool?> showBusinessCompletenessSheet(
  BuildContext context,
  BusinessCompleteness completeness,
) {
  return showAppModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final progress = completeness.totalCount == 0
          ? 0.0
          : completeness.completedCount / completeness.totalCount;
      final bottomPad = MediaQuery.paddingOf(ctx).bottom;

      return Material(
        color: AuthUi.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad > 0 ? bottomPad : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHandleThen(
                afterHandleGap: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Complete Business Profile',
                            style: WaUi.toolsTitleOf(
                              size: 20,
                              weight: FontWeight.w700,
                              color: AuthUi.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                        CircleCloseButton(
                          onTap: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  'Add these details before creating a menu website or business rewards.',
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AuthUi.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      completeness.progressLabel,
                      style: WaUi.label.copyWith(
                        color: AuthUi.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: WaUi.caption.copyWith(
                        color: AuthUi.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: BarqodyChrome.searchBg,
                    color: AuthUi.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BarqodyChrome.fieldFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _CheckRow(
                        done: completeness.hasName,
                        label: 'Business name',
                        showDivider: true,
                      ),
                      _CheckRow(
                        done: completeness.hasIndustry,
                        label: 'Industry category',
                        showDivider: true,
                      ),
                      _CheckRow(
                        done: completeness.hasLocation,
                        label: 'Business location on map',
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WaPrimaryButton(
                  label: 'Continue setup',
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    foregroundColor: AuthUi.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Not now',
                    style: WaUi.bodyMedium.copyWith(
                      color: AuthUi.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );
}

class _CheckRow extends StatelessWidget {
  final bool done;
  final String label;
  final bool showDivider;

  const _CheckRow({
    required this.done,
    required this.label,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: done ? WaUi.accent : BarqodyChrome.secondaryText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: WaUi.body.copyWith(
                    fontSize: 15,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    color: done
                        ? AuthUi.textPrimary
                        : AuthUi.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: BarqodyChrome.divider,
            ),
          ),
      ],
    );
  }
}

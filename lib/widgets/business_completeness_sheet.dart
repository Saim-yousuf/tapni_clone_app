import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/business_profile_screen.dart';
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

/// Returns true if business profile is complete; otherwise shows checklist sheet.
Future<bool> ensureBusinessProfileComplete(BuildContext context) async {
  final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
  final completeness = BusinessCompleteness.fromProfile(profile);
  if (completeness.isComplete) return true;

  await showBusinessCompletenessSheet(context, completeness);
  return false;
}

Future<void> showBusinessCompletenessSheet(
  BuildContext context,
  BusinessCompleteness completeness,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: WaUi.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WaUi.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Business Profile',
                style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Add these details before creating rewards, menu items, or appearing on Explore.',
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
              const SizedBox(height: 8),
              Text(
                completeness.progressLabel,
                style: WaUi.label.copyWith(color: WaUi.accent),
              ),
              const SizedBox(height: 16),
              _CheckRow(
                done: completeness.hasName,
                label: 'Business name',
              ),
              _CheckRow(
                done: completeness.hasIndustry,
                label: 'Industry category',
              ),
              _CheckRow(
                done: completeness.hasLocation,
                label: 'Business location on map',
              ),
              const SizedBox(height: 20),
              WaPrimaryButton(
                label: 'Complete Business Profile',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BusinessProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Not now', style: WaUi.bodyMedium),
                ),
              ),
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

  const _CheckRow({required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? WaUi.accent : WaUi.secondaryText,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                color: done ? WaUi.primaryText : WaUi.secondaryText,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

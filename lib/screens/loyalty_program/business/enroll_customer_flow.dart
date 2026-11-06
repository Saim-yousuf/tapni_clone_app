import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/app_toast.dart';

/// Enrolls [customerId] in [program], then opens [AddStampScreen].
/// Returns `true` when enroll succeeded (stamp screen may still be open/closed).
Future<bool> enrollCustomerAndOpenStamp({
  required BuildContext context,
  required RewardProgram program,
  required String customerId,
  String? customerName,
  String? customerUsername,
  String? customerPhoto,
}) async {
  if (customerId.trim().isEmpty) {
    showAppToast(
          context,
          context.l10n.profileNotFound,
          kind: AppToastKind.info,
        );
    return false;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Colors.black),
    ),
  );

  final res = await RewardRepo().enrollCustomer(program.id, customerId);
  if (!context.mounted) return false;
  Navigator.of(context).pop(); // loading

  if (!res.success || res.data == null) {
    showAppToast(
          context,
          res.message ?? context.l10n.failedToEnrollCustomer,
          kind: AppToastKind.error,
        );
    return false;
  }

  final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
  final map = raw is Map
      ? Map<String, dynamic>.from(raw)
      : <String, dynamic>{};
  final enrollment = RewardEnrollment.fromJson(map);
  final enriched = RewardEnrollment(
    id: enrollment.id,
    program: program,
    programId: program.id,
    stamps: enrollment.stamps,
    status: enrollment.status,
    customerName: customerName ?? enrollment.customerName,
    customerUsername: customerUsername ?? enrollment.customerUsername,
    customerPhoto: customerPhoto ?? enrollment.customerPhoto,
    enrolledByLabel: enrollment.enrolledByLabel,
  );

  await Navigator.of(context).push(
    AppPageRoute(
      builder: (_) => AddStampScreen(
        enrollment: enriched,
        customerName: enriched.customerName,
        customerUsername: enriched.customerUsername,
        customerPhoto: enriched.customerPhoto,
      ),
    ),
  );
  return true;
}

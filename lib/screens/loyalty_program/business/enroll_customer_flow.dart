import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          context.l10n.profileNotFound,
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          res.message ?? context.l10n.failedToEnrollCustomer,
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
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
    MaterialPageRoute(
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

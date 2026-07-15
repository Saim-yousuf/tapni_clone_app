import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class BusinessOnlyCard extends StatelessWidget {
  BusinessOnlyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 340,
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: 26,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Text(
              context.l10n.accessRESTRICTED,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 6),
            Text(context.l10n.businessUsersOnly,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${context.l10n.thisFeatureIsExclusivelyAvailableToBusinessUsers2} '
              '${context.l10n.switchToABusinessAccountToUnlockFullAccess}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  SizedBox(width: 6),
                  Text(
                    context.l10n.notAvailableOnYourCurrentPlan,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, thickness: 0.5),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  SubcriptionSheet.show(context);
                },
                icon: Icon(
                  Icons.business_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(context.l10n.goBusiness,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

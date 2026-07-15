import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class GoBussinessButton extends StatelessWidget {
  GoBussinessButton({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    if (profile.isPro == true) {
      return SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        SubcriptionSheet.show(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              context.l10n.go2,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(context.l10n.business,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

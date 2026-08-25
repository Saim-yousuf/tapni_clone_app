import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
class AddPointsScreen extends StatefulWidget {
  AddPointsScreen({super.key});

  @override
  State<AddPointsScreen> createState() => _AddPointsScreenState();
}

class _AddPointsScreenState extends State<AddPointsScreen> {
  final TextEditingController billController = TextEditingController();

  int points = 0;

  void calculatePoints(String value) {
    final amount = double.tryParse(value) ?? 0;

    // Example rule: 1 point per 100
    setState(() {
      points = (amount / 100).floor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.addPoints,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.billAmount,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            TextField(
              controller: billController,
              keyboardType: TextInputType.number,
              onChanged: calculatePoints,
              decoration: WaUi.fieldDecoration(
                hintText: context.l10n.enterBillAmount,
                prefixIcon: const Icon(Icons.receipt_long),
                radius: 14,
              ),
            ),

            SizedBox(height: 30),

            // Points Preview Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(context.l10n.pointsEarned,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.n1Point100PKRExampleRule,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: points == 0
                    ? null
                    : () {
                        // submit points
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(context.l10n.confirmAddPoints,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class CreateLoyaltyProgramScreen extends StatefulWidget {
  CreateLoyaltyProgramScreen({super.key});

  @override
  State<CreateLoyaltyProgramScreen> createState() =>
      _CreateLoyaltyProgramScreenState();
}

class _CreateLoyaltyProgramScreenState
    extends State<CreateLoyaltyProgramScreen> {
  String selectedType = 'Stamp';

  final programNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final rewardController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.createLoyaltyProgram,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.programName,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: programNameController,
              decoration: _inputDecoration(context.l10n.enterProgramName),
            ),

            SizedBox(height: 20),

            Text(context.l10n.description,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(context.l10n.describeYourLoyaltyProgram),
            ),

            SizedBox(height: 24),

            Text(context.l10n.programType,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 12),

            Row(
              children: [
                _typeChip('Stamp'),
                SizedBox(width: 10),
                _typeChip(context.l10n.points),
                SizedBox(width: 10),
                _typeChip('Both'),
              ],
            ),

            SizedBox(height: 24),

            Text(context.l10n.rewardDetails,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: rewardController,
              maxLines: 3,
              decoration: _inputDecoration(context.l10n.example10StampsFreeCoffee),
            ),

            SizedBox(height: 24),

            Text(context.l10n.startDate,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            _dateField(context.l10n.selectStartDate),

            SizedBox(height: 20),

            Text(context.l10n.endDate,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            _dateField(context.l10n.selectEndDate),

            SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {},
                child: Text(context.l10n.createProgram,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black),
          ),
          child: Text(
            type,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String title) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ),
          const Icon(Icons.calendar_month, color: Colors.black),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}

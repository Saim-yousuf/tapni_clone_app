import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class BankDetailDialog extends StatelessWidget {
  final Map<String, dynamic> bankDetails;

  BankDetailDialog({super.key, required this.bankDetails});

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  value.isEmpty ? "-" : value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(context, value),
            icon: Icon(Icons.copy, color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.bankDetails,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.black),
                ),
              ],
            ),

            SizedBox(height: 10),

            _buildRow(
              context,
              "Account Holder Name",
              bankDetails["accountHolderName"] ?? "",
            ),
            _buildRow(context, "IBAN", bankDetails["iban"] ?? ""),
            _buildRow(
              context,
              "Account Number",
              bankDetails["accountNumber"] ?? "",
            ),

            SizedBox(height: 10),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class RewardRedemptionScreen extends StatefulWidget {
  RewardRedemptionScreen({super.key});

  @override
  State<RewardRedemptionScreen> createState() => _RewardRedemptionScreenState();
}

class _RewardRedemptionScreenState extends State<RewardRedemptionScreen> {
  bool redeemed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: Text(context.l10n.redeemReward,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: redeemed ? _successView() : _redeemView(),
      ),
    );
  }

  // BEFORE REDEEM
  Widget _redeemView() {
    return Column(
      children: [
        // Reward Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(Icons.card_giftcard, color: Colors.white, size: 40),
              SizedBox(height: 10),
              Text(
                context.l10n.freeCoffee,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                context.l10n.n10StampsRequired,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        SizedBox(height: 30),

        // QR SCAN BOX
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 70, color: Colors.black),
              SizedBox(height: 10),
              Text(
                context.l10n.scanBusinessQRToRedeem,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        Spacer(),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                redeemed = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(context.l10n.confirmRedemption,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // AFTER REDEEM
  Widget _successView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: Colors.black, size: 90),
        SizedBox(height: 20),
        Text(context.l10n.rewardRedeemed,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(context.l10n.yourFreeCoffeeHasBeenSuccessfullyRedeemed,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                redeemed = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.black12),
            ),
            child: Text(context.l10n.redeemAnotherReward),
          ),
        ),
      ],
    );
  }
}

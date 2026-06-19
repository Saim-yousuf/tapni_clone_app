import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_reward_screen.dart';

class CustomerLoyaltyHomeScreen extends StatelessWidget {
  const CustomerLoyaltyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Loyalty Home",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP SUMMARY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Total Points", style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                    "1,250",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Keep earning to unlock rewards",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STAMP CARDS SECTION
            const Text(
              "Active Stamp Cards",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _StampCard(progress: "7/10"),
                  _StampCard(progress: "3/10"),
                  _StampCard(progress: "10/10"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // REWARDS SECTION
            const Text(
              "Available Rewards",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _RewardTile(
              title: "Free Coffee",
              subtitle: "10 Stamps Required",
              icon: Icons.local_cafe,
            ),

            _RewardTile(
              title: "10% Discount",
              subtitle: "500 Points Required",
              icon: Icons.discount,
            ),

            _RewardTile(
              title: "Free Dessert",
              subtitle: "8 Stamps + 300 Points",
              icon: Icons.icecream,
            ),
          ],
        ),
      ),
    );
  }
}

// STAMP CARD WIDGET
class _StampCard extends StatelessWidget {
  final String progress;

  const _StampCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_activity, color: Colors.black),
          const SizedBox(height: 10),
          Text(
            progress,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text("Stamps", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// REWARD TILE WIDGET
class _RewardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _RewardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          // MaterialPageRoute(builder: (_) => CustomerProgramDetailsScreen()),
          MaterialPageRoute(builder: (_) => CustomerRewardScreen()),

        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

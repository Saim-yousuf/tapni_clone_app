import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/customer/reward_redemption_screen.dart';

class CustomerProgramDetailsScreen extends StatelessWidget {
  const CustomerProgramDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Coffee Rewards",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROGRAM HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Coffee Rewards",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Stamp + Points Program",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Keep collecting to unlock rewards",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STAMP PROGRESS
            const Text(
              "Stamp Progress",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _ProgressCard(
              title: "Coffee Stamps",
              progress: "7 / 10",
              subtitle: "3 more to get Free Coffee",
              icon: Icons.local_activity,
            ),

            const SizedBox(height: 20),

            // POINTS SECTION
            const Text(
              "Points Balance",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  Icon(Icons.stars, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "1,250 Points",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Earn more to unlock discounts",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // REWARD PROGRESS
            const Text(
              "Next Reward",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _ProgressCard(
              title: "Free Coffee Reward",
              progress: "7 / 10 Stamps",
              subtitle: "Almost there 🎉",
              icon: Icons.card_giftcard,
            ),

            const SizedBox(height: 20),

            // RECENT ACTIVITY
            const Text(
              "Recent Activity",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _ActivityTile(title: "Earned 1 Stamp", time: "Today"),

            _ActivityTile(title: "Earned 50 Points", time: "Yesterday"),

            _ActivityTile(title: "Redeemed Free Coffee", time: "2 days ago"),
          ],
        ),
      ),
    );
  }
}

// PROGRESS CARD
class _ProgressCard extends StatelessWidget {
  final String title;
  final String progress;
  final String subtitle;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
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
                Text(progress, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ACTIVITY TILE
class _ActivityTile extends StatelessWidget {
  final String title;
  final String time;

  const _ActivityTile({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RewardRedemptionScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            Text(time, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/create_reward_screen.dart';

class RewardsManagementScreen extends StatelessWidget {
  const RewardsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewards = [
      {"title": "Free Coffee", "type": "Stamp", "requirement": "10 Stamps"},
      {"title": "10% Discount", "type": "Points", "requirement": "500 Points"},
      {
        "title": "Free Dessert",
        "type": "Both",
        "requirement": "8 Stamps + 300 Points",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rewards',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Create Reward
            },
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reward = rewards[index];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard, color: Colors.white),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward["title"]!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${reward["type"]} • ${reward["requirement"]}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "edit", child: Text("Edit")),
                    const PopupMenuItem(value: "delete", child: Text("Delete")),
                  ],
                  onSelected: (value) {
                    if (value == "edit") {
                      // Edit reward
                    }
                    if (value == "delete") {
                      // Delete reward
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => CreateRewardScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Reward"),
      ),
    );
  }
}

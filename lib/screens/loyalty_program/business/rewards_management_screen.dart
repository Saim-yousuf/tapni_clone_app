import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/create_reward_screen.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class RewardsManagementScreen extends StatelessWidget {
  RewardsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewards = [
      {"title": context.l10n.freeCoffee, "type": context.l10n.stampType, "requirement": "10 Stamps"},
      {"title": context.l10n.n10Discount, "type": context.l10n.points, "requirement": "500 Points"},
      {
        "title": context.l10n.freeDessert,
        "type": context.l10n.bothType,
        "requirement": "8 Stamps + 300 Points",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.rewards,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Create Reward
            },
            icon: const Icon(Icons.add, color: Colors.black)),
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
                  offset: Offset(0, 4),
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
                  child: Icon(Icons.card_giftcard, color: Colors.white),
                ),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward["title"]!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${reward["type"]} • ${reward["requirement"]}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton(
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: "edit", child: Text(context.l10n.edit)),
                    PopupMenuItem(value: "delete", child: Text(context.l10n.delete)),
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
        icon: Icon(Icons.add),
        label: Text(context.l10n.createReward),
      ),
    );
  }
}

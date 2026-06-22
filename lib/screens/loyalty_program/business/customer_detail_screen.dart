import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_points_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Customer Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Customer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'John Smith',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Joined: Jan 15, 2026',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Points',
                    value: '450',
                    icon: Icons.stars_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'Stamps',
                    value: '7 / 10',
                    icon: Icons.local_activity_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _statCard(
              title: 'Rewards Earned',
              value: '3',
              icon: Icons.card_giftcard,
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddPointsScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Points'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddStampScreen(
                              enrollment: RewardEnrollment(
                                id: '',
                                programId: '',
                                stamps: 0,
                                status: 'ACTIVE',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_activity),
                      label: const Text('Add Stamp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Recent Activity
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            _activityTile(
              title: 'Earned 50 Points',
              subtitle: 'Today • 3:15 PM',
            ),

            _activityTile(
              title: 'Received 1 Stamp',
              subtitle: 'Yesterday • 5:42 PM',
            ),

            _activityTile(
              title: 'Redeemed Free Coffee',
              subtitle: '2 Days Ago',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  static Widget _activityTile({
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(Icons.history, color: Colors.white, size: 18),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

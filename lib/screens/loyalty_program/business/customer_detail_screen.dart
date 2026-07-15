import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_points_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class CustomerDetailsScreen extends StatelessWidget {
  CustomerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.customerDetails,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Customer Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.black),
                  ),
                  SizedBox(height: 12),
                  Text(context.l10n.johnSmith,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.joinedJan152026,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: context.l10n.points,
                    value: '450',
                    icon: Icons.stars_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: context.l10n.stamps,
                    value: '7 / 10',
                    icon: Icons.local_activity_outlined,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            _statCard(
              title: context.l10n.rewardsEarned,
              value: '3',
              icon: Icons.card_giftcard,
              fullWidth: true,
            ),

            SizedBox(height: 24),

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
                      icon: Icon(Icons.add),
                      label: Text(context.l10n.addPoints),
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
                SizedBox(width: 12),
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
                                status: context.l10n.active2,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.local_activity),
                      label: Text(context.l10n.addStamp),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Recent Activity
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.recentActivity,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 12),

            _activityTile(
              title: context.l10n.earned50Points,
              subtitle: context.l10n.today315PM,
            ),

            _activityTile(
              title: context.l10n.received1Stamp,
              subtitle: context.l10n.yesterday542PM,
            ),

            _activityTile(
              title: context.l10n.redeemedFreeCoffee,
              subtitle: context.l10n.n2DaysAgo,
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey)),
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

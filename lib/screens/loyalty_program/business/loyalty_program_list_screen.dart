import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/create_reward_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_details_screen.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class LoyaltyProgramListScreen extends StatefulWidget {
  LoyaltyProgramListScreen({super.key});

  @override
  State<LoyaltyProgramListScreen> createState() => _LoyaltyProgramListScreenState();
}

class _LoyaltyProgramListScreenState extends State<LoyaltyProgramListScreen> {
  List<RewardProgram> _programs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await RewardRepo().getPrograms();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        final list = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
        _programs = list.map((e) => RewardProgram.fromJson(e as Map<String, dynamic>)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.rewardPrograms, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => CreateRewardScreen()),
              );
              if (created == true) _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _programs.length,
                    itemBuilder: (_, i) => _buildCard(_programs[i]),
                  ),
                ),
      floatingActionButton: !_isLoading && _programs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => CreateRewardScreen()),
                );
                if (created == true) _load();
              },
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add),
              label: Text(context.l10n.newReward),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(context.l10n.noRewardProgramsYet, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(context.l10n.createYourFirstRewardCardForCustomers, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => CreateRewardScreen()),
              );
              if (created == true) _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.add),
            label: Text(context.l10n.createReward),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(RewardProgram program) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => LoyaltyProgramDetailsScreen(programId: program.id)),
        );
        if (changed == true) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: program.theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (program.logo.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(program.logo, width: 36, height: 36, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => SizedBox()),
                  ),
                if (program.logo.isNotEmpty) SizedBox(width: 10),
                Expanded(
                  child: Text(program.label.isNotEmpty ? program.label : program.title,
                      style: TextStyle(color: program.theme.cardTextColor.withOpacity(0.6), fontSize: 12)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: program.isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    program.isActive ? context.l10n.active : context.l10n.inactive,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: program.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(program.title,
                style: TextStyle(color: program.theme.cardTextColor, fontSize: 17, fontWeight: FontWeight.bold)),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(program.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: program.theme.cardTextColor.withOpacity(0.55), fontSize: 12)),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(program.stamps.clamp(1, 12), (i) => Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: i < 3 ? program.theme.stampColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: program.theme.stampBorderColor, width: 1.5),
                ),
              )),
            ),
            const SizedBox(height: 6),
            Text(context.l10n.stampsRequiredCount(program.stamps),
                style: TextStyle(color: program.theme.cardTextColor.withOpacity(0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

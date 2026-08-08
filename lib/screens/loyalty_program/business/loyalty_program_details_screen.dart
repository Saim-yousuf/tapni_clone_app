import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/create_reward_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class LoyaltyProgramDetailsScreen extends StatefulWidget {
  final String programId;
  const LoyaltyProgramDetailsScreen({super.key, required this.programId});

  @override
  State<LoyaltyProgramDetailsScreen> createState() => _LoyaltyProgramDetailsScreenState();
}

class _LoyaltyProgramDetailsScreenState extends State<LoyaltyProgramDetailsScreen> {
  RewardProgram? _program;
  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await RewardRepo().getProgramById(widget.programId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
        _program = RewardProgram.fromJson(data as Map<String, dynamic>);
      }
    });
  }

  Future<void> _toggleActive() async {
    if (_program == null) return;
    setState(() => _isToggling = true);
    final res = await RewardRepo().toggleActive(_program!.id);
    setState(() => _isToggling = false);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? context.l10n.failed)));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.deleteReward),
        content: Text(context.l10n.thisWillPermanentlyDeleteThisRewardProgramAndAllItsEnrollments),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await RewardRepo().deleteProgram(_program!.id);
    if (!mounted) return;
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? context.l10n.failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.programDetails, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_program != null) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined),
              onPressed: () async {
                final p = _program!;
                bool? changed;
                if (p.hasDesign) {
                  changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoyaltyDesignEditorScreen(
                        design: p.design!.copy(),
                        existingProgramId: p.id,
                        existingProgram: p,
                      ),
                    ),
                  );
                } else {
                  // Offer template gallery redesign or classic form edit
                  final choice = await showModalBottomSheet<String>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.palette_outlined),
                            title: Text(ctx.l10n.chooseATemplate),
                            onTap: () => Navigator.pop(ctx, 'template'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(ctx.l10n.editReward),
                            onTap: () => Navigator.pop(ctx, 'classic'),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (!mounted) return;
                  if (choice == 'template') {
                    changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoyaltyTemplateGalleryScreen(existing: p),
                      ),
                    );
                  } else if (choice == 'classic') {
                    changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateRewardScreen(existing: p),
                      ),
                    );
                  }
                }
                if (changed == true) _load();
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _program == null
              ? Center(child: Text(context.l10n.programNotFound))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _program!;
    final stats = p.stats;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Preview
          _buildCardPreview(p),
          SizedBox(height: 28),

          // Active / Inactive Toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: p.isActive ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
              border: Border.all(color: p.isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(p.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: p.isActive ? Colors.green : Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.isActive ? context.l10n.active : context.l10n.inactive,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: p.isActive ? Colors.green : Colors.red)),
                      Text(p.isActive ? context.l10n.customersCanBeEnrolledAndStamped : context.l10n.thisProgramIsPaused,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                _isToggling
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch.adaptive(
                        value: p.isActive,
                        onChanged: (_) => _toggleActive(),
                        activeColor: Colors.green,
                      ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Stats
          if (stats != null) ...[
            Text(context.l10n.stats, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statTile(context.l10n.enrolled, '${stats.totalEnrollments}', Icons.people_outline)),
              SizedBox(width: 12),
              Expanded(child: _statTile(context.l10n.stampsGiven, '${stats.totalStampsGiven}', Icons.star_outline)),
            ]),
            SizedBox(height: 24),
          ],

          // Details
          Text(context.l10n.details, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          _detailRow(context.l10n.title, p.title),
          _detailRow(context.l10n.label, p.label.isNotEmpty ? p.label : '-'),
          _detailRow(context.l10n.description, p.description.isNotEmpty ? p.description : '-'),
          _detailRow(context.l10n.totalStamps, '${p.stamps}'),
          if (p.createdAt != null)
            _detailRow(context.l10n.created, '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCardPreview(RewardProgram p) {
    if (p.hasDesign) {
      return LoyaltyCardDesignRenderer(
        design: p.design!,
        borderRadius: 20,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (p.logo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(p.logo, width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            if (p.logo.isNotEmpty) const SizedBox(width: 10),
            Text(p.label, style: TextStyle(color: p.theme.cardTextColor.withOpacity(0.6), fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Text(p.title, style: TextStyle(color: p.theme.cardTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.description, style: TextStyle(color: p.theme.cardTextColor.withOpacity(0.55), fontSize: 12)),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(p.stamps.clamp(1, 12), (i) => Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: i < 3 ? p.theme.stampColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: p.theme.stampBorderColor, width: 2),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.stampsForReward(p.stamps),
              style: TextStyle(color: p.theme.cardTextColor.withOpacity(0.45), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

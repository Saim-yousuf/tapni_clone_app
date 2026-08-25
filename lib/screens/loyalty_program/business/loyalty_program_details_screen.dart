import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/create_reward_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class LoyaltyProgramDetailsScreen extends StatefulWidget {
  final String programId;
  const LoyaltyProgramDetailsScreen({super.key, required this.programId});

  @override
  State<LoyaltyProgramDetailsScreen> createState() =>
      _LoyaltyProgramDetailsScreenState();
}

class _LoyaltyProgramDetailsScreenState
    extends State<LoyaltyProgramDetailsScreen> {
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
    if (!mounted) return;
    setState(() => _isToggling = false);
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(res.message ?? context.l10n.failed, style: WaUi.body),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
        ),
        title: Text(context.l10n.deleteReward, style: WaUi.sectionHeader),
        content: Text(
          context.l10n
              .thisWillPermanentlyDeleteThisRewardProgramAndAllItsEnrollments,
          style: WaUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.delete, style: WaUi.promoButton),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(res.message ?? context.l10n.failed, style: WaUi.body),
        ),
      );
    }
  }

  Future<void> _edit() async {
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
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: WaUi.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(ctx.l10n.chooseATemplate, style: WaUi.listTitle),
                  onTap: () => Navigator.pop(ctx, 'template'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(ctx.l10n.editReward, style: WaUi.listTitle),
                  onTap: () => Navigator.pop(ctx, 'classic'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted) return;
      if (choice == 'template') {
        changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => LoyaltyTemplateGalleryScreen(existing: p),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.programDetails),
        actions: [
          if (_program != null) ...[
            IconButton(
              tooltip: context.l10n.editReward,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _edit),
            IconButton(
              tooltip: context.l10n.delete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
              onPressed: _delete),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _program == null
              ? Center(
                  child: Text(
                    context.l10n.programNotFound,
                    style: WaUi.bodyMedium,
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _program!;
    final stats = p.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _buildCardPreview(p),
        const SizedBox(height: 20),
        _ActiveToggle(
          isActive: p.isActive,
          isToggling: _isToggling,
          onChanged: (_) => _toggleActive(),
          activeLabel: context.l10n.active,
          inactiveLabel: context.l10n.inactive,
          activeHint: context.l10n.customersCanBeEnrolledAndStamped,
          inactiveHint: context.l10n.thisProgramIsPaused,
        ),
        if (stats != null) ...[
          const SizedBox(height: 22),
          Text(context.l10n.stats, style: WaUi.sectionHeader),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: context.l10n.enrolled,
                  value: '${stats.totalEnrollments}',
                  icon: Icons.people_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: context.l10n.stampsGiven,
                  value: '${stats.totalStampsGiven}',
                  icon: Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        Text(context.l10n.details, style: WaUi.sectionHeader),
        const SizedBox(height: 8),
        _DetailCard(
          rows: [
            (context.l10n.title, p.title),
            (context.l10n.label, p.label.isNotEmpty ? p.label : '-'),
            (
              context.l10n.description,
              p.description.isNotEmpty ? p.description : '-'
            ),
            (context.l10n.totalStamps, '${p.stamps}'),
            if (p.createdAt != null)
              (
                context.l10n.created,
                '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}'
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPreview(RewardProgram p) {
    // Keep preview compact — full-width AspectRatio makes portrait cards huge.
    const maxPreviewWidth = 220.0;

    Widget card;
    if (p.hasDesign) {
      card = LoyaltyCardDesignRenderer(
        design: p.design!,
        borderRadius: 16,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else {
      card = Container(
        width: maxPreviewWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.label.isNotEmpty)
              Text(
                p.label,
                style: WaUi.caption.copyWith(
                  color: p.theme.cardTextColor.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              p.title,
              style: WaUi.listTitle.copyWith(
                color: p.theme.cardTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                p.stamps.clamp(1, 12),
                (i) => RewardStampSlot(
                  filled: false,
                  theme: p.theme,
                  stampIconUrl: p.stampIcon,
                  unstampIconUrl: p.unstampIcon,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.stampsForReward(p.stamps),
              style: WaUi.caption.copyWith(
                color: p.theme.cardTextColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: maxPreviewWidth),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: card,
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final bool isToggling;
  final ValueChanged<bool> onChanged;
  final String activeLabel;
  final String inactiveLabel;
  final String activeHint;
  final String inactiveHint;

  const _ActiveToggle({
    required this.isActive,
    required this.isToggling,
    required this.onChanged,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.activeHint,
    required this.inactiveHint,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? WaUi.navGreen : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WaUi.divider),
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.check_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? activeLabel : inactiveLabel,
                  style: WaUi.listTitle.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? activeHint : inactiveHint,
                  style: WaUi.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (isToggling)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: isActive,
              onChanged: onChanged,
              activeColor: WaUi.navGreen,
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: WaUi.buttonDark),
          const SizedBox(height: 8),
          Text(
            value,
            style: WaUi.headline.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: WaUi.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<(String, String)> rows;

  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WaUi.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(rows[i].$1, style: WaUi.caption),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: WaUi.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, color: WaUi.divider),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_details_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class LoyaltyProgramListScreen extends StatefulWidget {
  const LoyaltyProgramListScreen({super.key});

  @override
  State<LoyaltyProgramListScreen> createState() =>
      _LoyaltyProgramListScreenState();
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
        final list = res.data is List
            ? res.data as List
            : (res.data['data'] as List? ?? []);
        _programs = list
            .map((e) => RewardProgram.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });
  }

  Future<void> _openCreate() async {
    final ok = await ensureBusinessProfileComplete(context);
    if (!ok || !mounted) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoyaltyTemplateGalleryScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openDetails(RewardProgram program) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoyaltyProgramDetailsScreen(programId: program.id),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: WaUi.primaryText,
        title: Text(
          context.l10n.loyaltyPrograms,
          style: WaUi.headline.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.createProgram,
            icon: const Icon(Icons.add_rounded),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _programs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: WaUi.accent,
                  backgroundColor: Colors.white,
                  onRefresh: _load,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: _programs.length,
                    itemBuilder: (_, i) {
                      final program = _programs[i];
                      return _ProgramGridTile(
                        program: program,
                        onTap: () => _openDetails(program),
                      );
                    },
                  ),
                ),
      floatingActionButton: !_isLoading && _programs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: WaUi.buttonDark,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                context.l10n.createProgram,
                style: WaUi.promoButton,
              ),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 56,
              color: WaUi.secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noRewardProgramsYet,
              textAlign: TextAlign.center,
              style: WaUi.sectionHeader,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.createYourFirstRewardCardForCustomers,
              textAlign: TextAlign.center,
              style: WaUi.caption,
            ),
            const SizedBox(height: 24),
            CustomAppButton(
              text: context.l10n.createProgram,
              icon: Icons.add_rounded,
              backgroundColor: WaUi.buttonDark,
              onTap: _openCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramGridTile extends StatelessWidget {
  final RewardProgram program;
  final VoidCallback onTap;

  const _ProgramGridTile({
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: program.hasDesign
                      ? LoyaltyCardDesignRenderer(
                          design: program.design!,
                          borderRadius: 14,
                          shadows: const [],
                        )
                      : _ClassicPreview(program: program),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              program.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.bodyMedium.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              program.isActive
                  ? context.l10n.stampsForReward(program.stamps)
                  : context.l10n.inactive,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.caption.copyWith(
                fontSize: 11,
                color: program.isActive
                    ? WaUi.secondaryText
                    : const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassicPreview extends StatelessWidget {
  final RewardProgram program;

  const _ClassicPreview({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = program.theme;
    return ColoredBox(
      color: theme.cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.label.isNotEmpty)
              Text(
                program.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.cardTextColor.withValues(alpha: 0.65),
                  fontSize: 10,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.cardTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                program.stamps.clamp(1, 8),
                (i) => RewardStampSlot(
                  filled: false,
                  theme: theme,
                  stampIconUrl: program.stampIcon,
                  unstampIconUrl: program.unstampIcon,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

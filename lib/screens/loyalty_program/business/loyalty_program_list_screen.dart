import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_details_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_rewards_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class LoyaltyProgramListScreen extends StatefulWidget {
  const LoyaltyProgramListScreen({super.key});

  @override
  State<LoyaltyProgramListScreen> createState() =>
      _LoyaltyProgramListScreenState();
}

class _LoyaltyProgramListScreenState extends State<LoyaltyProgramListScreen>
    with SingleTickerProviderStateMixin {
  List<RewardProgram> _programs = [];
  bool _isLoading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  List<RewardProgram> _filtered(int tab) {
    switch (tab) {
      case 0:
        return _programs.where((p) => p.isActive).toList();
      case 1:
        return _programs.where((p) => !p.isActive).toList();
      case 2:
        return _programs.where((p) => !p.hasDesign).toList();
      default:
        return _programs;
    }
  }

  Future<void> _openCreateModal() async {
    final ok = await ensureBusinessProfileComplete(context);
    if (!ok || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CreateStampCardDialog(
        onBrowseTemplates: () async {
          Navigator.of(ctx).pop();
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const LoyaltyTemplateGalleryScreen(),
            ),
          );
          if (created == true) _load();
        },
        onCreateOwnDesign: () async {
          Navigator.of(ctx).pop();
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => LoyaltyDesignEditorScreen(
                design: LoyaltyCardDesign.blank(),
              ),
            ),
          );
          if (created == true) _load();
        },
      ),
    );
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

  void _selectTab(int index) {
    if (_tabController.index == index && !_tabController.indexIsChanging) {
      return;
    }
    HapticFeedback.selectionClick();
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Stamp Rewards',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAssetButton(
                    asset: 'assets/images/png/money-icon.png',
                    iconSize: 18,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/points_rewards'),
                          builder: (_) => const PointsRewardsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  CircleAssetButton(
                    asset: 'assets/images/png/plus-icon.png',
                    iconSize: 16,
                    onTap: _openCreateModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) {
                  return _SegmentedTabs(
                    position: _tabController.animation!.value,
                    labels: [
                      context.l10n.active,
                      context.l10n.inactive,
                      context.l10n.draft,
                    ],
                    onChanged: _selectTab,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ProgramListTab(
                          programs: _filtered(0),
                          onRefresh: _load,
                          onOpen: _openDetails,
                          onCreate: _openCreateModal,
                        ),
                        _ProgramListTab(
                          programs: _filtered(1),
                          onRefresh: _load,
                          onOpen: _openDetails,
                          onCreate: _openCreateModal,
                        ),
                        _ProgramListTab(
                          programs: _filtered(2),
                          onRefresh: _load,
                          onOpen: _openDetails,
                          onCreate: _openCreateModal,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final double position;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.position,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final max = (labels.length - 1).toDouble();
    final t = position.clamp(0.0, max);
    final selected = t.round().clamp(0, labels.length - 1);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              Positioned(
                left: t * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontSize: 14,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: i == selected
                                  ? Colors.white
                                  : BarqodyChrome.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgramListTab extends StatelessWidget {
  final List<RewardProgram> programs;
  final Future<void> Function() onRefresh;
  final void Function(RewardProgram) onOpen;
  final VoidCallback onCreate;

  const _ProgramListTab({
    required this.programs,
    required this.onRefresh,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return _StampEmptyState(onCreate: onCreate);
    }
    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: programs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          return _ProgramListCard(
            program: programs[i],
            onTap: () => onOpen(programs[i]),
          );
        },
      ),
    );
  }
}

class _StampEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _StampEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const SizedBox(height: 48),
        Center(
          child: Image.asset(
            'assets/images/png/stamp-img.png',
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.local_offer_outlined,
              size: 80,
              color: BarqodyChrome.secondaryText.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Turn Visits Into Purchase',
          textAlign: TextAlign.center,
          style: WaUi.toolsTitleOf(
            size: 22,
            weight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.createYourFirstRewardCardForCustomers,
          textAlign: TextAlign.center,
          style: WaUi.body.copyWith(
            fontSize: 15,
            color: BarqodyChrome.secondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        PillButton(
          label: 'Create Stamp Card',
          onPressed: onCreate,
        ),
      ],
    );
  }
}

class _ProgramListCard extends StatelessWidget {
  final RewardProgram program;
  final VoidCallback onTap;

  const _ProgramListCard({
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enrollments = program.stats?.totalEnrollments ?? 0;
    final showEnrolled = program.stats != null && enrollments > 0;

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 72,
                  child: program.hasDesign
                      ? LoyaltyCardDesignRenderer(
                          design: program.design!,
                          borderRadius: 12,
                          shadows: const [],
                        )
                      : _ClassicThumb(program: program),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.toolsTitleOf(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${program.stamps} Stamps',
                      style: WaUi.body.copyWith(
                        fontSize: 14,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    if (showEnrolled) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$enrollments Enrolled Customers',
                          style: WaUi.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BarqodyChrome.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassicThumb extends StatelessWidget {
  final RewardProgram program;

  const _ClassicThumb({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = program.theme;
    return ColoredBox(
      color: theme.cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            program.stamps.clamp(1, 6),
            (_) => RewardStampSlot(
              filled: false,
              theme: theme,
              stampIconUrl: program.stampIcon,
              unstampIconUrl: program.unstampIcon,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateStampCardDialog extends StatelessWidget {
  final VoidCallback onBrowseTemplates;
  final VoidCallback onCreateOwnDesign;

  const _CreateStampCardDialog({
    required this.onBrowseTemplates,
    required this.onCreateOwnDesign,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Stamp Card',
                    style: WaUi.toolsTitleOf(
                      size: 20,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                CircleCloseButton(onTap: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Choose a design to start your reward card.',
              style: WaUi.body.copyWith(
                fontSize: 15,
                color: BarqodyChrome.bodyText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Browse Templates',
              onPressed: onBrowseTemplates,
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Create Own Design',
              filled: false,
              onPressed: onCreateOwnDesign,
            ),
          ],
        ),
      ),
    );
  }
}

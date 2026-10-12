import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_details_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
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
        // Active: Go Live — customers can earn stamps.
        return _programs.where((p) => p.isActive).toList();
      case 1:
        // Inactive: designed but not live (includes Save Draft).
        return _programs.where((p) => !p.isActive && p.hasDesign).toList();
      case 2:
        // Draft: incomplete — no card design yet.
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
    // Figma empty: no tabs / no +, just illustration + Create CTA.
    final showFullEmpty = !_isLoading && _programs.isEmpty;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Stamp Rewards',
              trailing: showFullEmpty
                  ? null
                  : CircleAssetButton(
                      asset: 'assets/images/png/plus-icon.png',
                      iconSize: 16,
                      onTap: _openCreateModal,
                    ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                ),
              )
            else if (showFullEmpty)
              Expanded(
                child: RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  onRefresh: _load,
                  child: _StampEmptyState(onCreate: _openCreateModal),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProgramListTab(
                      programs: _filtered(0),
                      emptyLabel: 'No active stamp cards yet.',
                      onRefresh: _load,
                      onOpen: _openDetails,
                      onCreate: _openCreateModal,
                    ),
                    _ProgramListTab(
                      programs: _filtered(1),
                      emptyLabel: 'No inactive stamp cards.',
                      onRefresh: _load,
                      onOpen: _openDetails,
                      onCreate: _openCreateModal,
                    ),
                    _ProgramListTab(
                      programs: _filtered(2),
                      emptyLabel: 'No draft stamp cards.',
                      onRefresh: _load,
                      onOpen: _openDetails,
                      onCreate: _openCreateModal,
                    ),
                  ],
                ),
              ),
            ],
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
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
  final String emptyLabel;
  final Future<void> Function() onRefresh;
  final void Function(RewardProgram) onOpen;
  final VoidCallback onCreate;

  const _ProgramListTab({
    required this.programs,
    required this.emptyLabel,
    required this.onRefresh,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.white,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
          children: [
            Text(
              emptyLabel,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: 15,
                color: BarqodyChrome.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Create Stamp Card',
              onPressed: onCreate,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: programs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
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

/// Figma `Stampe Reward Empty` — illustration + copy + Create CTA.
/// Upper-weighted stack (more empty space below), AuthScale proportions.
class _StampEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _StampEmptyState({required this.onCreate});

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.2);

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.padH.clamp(28.0, 36.0);
    final imageH = m.s(148).clamp(120.0, 168.0);
    final titleSize = _font(m, 24, min: 20);
    final bodySize = _font(m, 14, min: 12);
    final gapAfterImage = m.v(28).clamp(22.0, 34.0);
    final gapAfterTitle = m.v(10).clamp(8.0, 14.0);
    final gapAfterBody = m.v(32).clamp(24.0, 40.0);
    final bottomPad = m.v(16).clamp(12.0, 24.0);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(side, 0, side, bottomPad),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/png/stamp-img.png',
                  height: imageH,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.local_offer_outlined,
                    size: imageH * 0.55,
                    color: BarqodyChrome.secondaryText.withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: gapAfterImage),
                Text(
                  'Turn Visits Into Purchase',
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: titleSize,
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: gapAfterTitle),
                Text(
                  'Give customers a reason to come back with simple stamp rewards.',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: bodySize,
                    color: AuthUi.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: gapAfterBody),
                PillButton(
                  label: 'Create Stamp Card',
                  onPressed: onCreate,
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
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

  static String _formatCount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final enrollments = program.stats?.totalEnrollments ?? 0;
    final title = program.title.trim().isNotEmpty
        ? program.title.trim()
        : (program.label.trim().isNotEmpty ? program.label.trim() : 'Stamp Card');

    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 80,
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.toolsTitleOf(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${program.stamps} Stamps',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Text(
                        '${_formatCount(enrollments)} Enrolled Customers',
                        style: WaUi.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: BarqodyChrome.secondaryText,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black,
                size: 22,
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
                fontSize: 13,
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

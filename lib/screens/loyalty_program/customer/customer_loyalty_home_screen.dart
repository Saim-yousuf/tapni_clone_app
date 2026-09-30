import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/utils/api_error_messages.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/connection_error_state.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';

enum _RewardsTab { stamp, points, activity }

class CustomerLoyaltyHomeScreen extends StatefulWidget {
  const CustomerLoyaltyHomeScreen({super.key});

  @override
  State<CustomerLoyaltyHomeScreen> createState() =>
      _CustomerLoyaltyHomeScreenState();
}

class _CustomerLoyaltyHomeScreenState extends State<CustomerLoyaltyHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _cardBg = Color(0xFFF5F5F5);
  static const _cardBorder = Color(0xFFEAEAEA);
  static const _positiveGreen = Color(0xFF2E7D32);
  static const _muted = Color(0xFF757575);

  List<RewardEnrollment> _enrollments = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadEnrollments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await RewardRepo().getMyEnrollments();
    if (!mounted) return;

    if (res.success && res.data != null) {
      final list = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      setState(() {
        _enrollments = list
            .map((e) => RewardEnrollment.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = ApiErrorMessages.sanitize(
        res.message,
        fallback: context.l10n.failedToLoadPrograms,
      );
    });
  }

  int get _activeStampCount =>
      _enrollments.where((e) => !e.isCompleted).length;

  int get _totalPoints {
    // Customer points balance API is not wired yet; surface 0 until then.
    return 0;
  }

  List<_CustomerPointsCard> get _pointsCards {
    // Customer points balance is not available from the API yet.
    return const [];
  }

  List<_ActivityItem> get _activityItems {
    final items = <_ActivityItem>[];
    for (final e in _enrollments) {
      final name = e.program?.displayBusinessName ?? 'Business';
      if (e.stamps > 0) {
        items.add(
          _ActivityItem(
            amountLabel: e.stamps == 1 ? '+1 Stamp' : '+${e.stamps} Stamps',
            positive: true,
            merchant: name,
            orderLabel: 'Enrollment',
            at: e.program?.createdAt ?? DateTime.now(),
          ),
        );
      }
    }
    items.sort((a, b) => b.at.compareTo(a.at));
    return items;
  }

  void _selectTab(int index) {
    if (_tabController.index == index && !_tabController.indexIsChanging) {
      return;
    }
    HapticFeedback.selectionClick();
    _tabController.animateTo(index);
  }

  void _openDetails(RewardEnrollment enrollment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerProgramDetailsScreen(enrollment: enrollment),
      ),
    );
  }

  void _openScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  String _formatInt(int value) => NumberFormat('#,###').format(value);

  String _formatActivityDate(DateTime at) {
    return DateFormat('dd-MM-yyyy  hh:mm a').format(at);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: context.l10n.rewards),
            Expanded(
              child: _isLoading
                  ? const _RewardsShimmer()
                  : _errorMessage != null
                      ? Center(
                          child: ConnectionErrorState(
                            message: _errorMessage!,
                            onRetry: _loadEnrollments,
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                color: Colors.black,
                                backgroundColor: Colors.white,
                                onRefresh: _loadEnrollments,
                                child: CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          BarqodyChrome.sidePad,
                                          16,
                                          BarqodyChrome.sidePad,
                                          0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Your rewards, points, and stamp cards in one place.',
                                              style: WaUi.toolsTitleOf(
                                                size: 22,
                                                weight: FontWeight.w700,
                                                color: Colors.black,
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 22),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _StatBlock(
                                                    value: _formatInt(
                                                      _totalPoints,
                                                    ),
                                                    label: 'Total Points',
                                                  ),
                                                ),
                                                const SizedBox(width: 24),
                                                Expanded(
                                                  child: _StatBlock(
                                                    value: '$_activeStampCount',
                                                    label:
                                                        'Active Stamp Card',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'Earn points and stamps when you shop with participating businesses.',
                                              style: WaUi.body.copyWith(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: _muted,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            AnimatedBuilder(
                                              animation:
                                                  _tabController.animation!,
                                              builder: (context, _) {
                                                return _SegmentedTabs(
                                                  position: _tabController
                                                      .animation!.value,
                                                  labels: const [
                                                    'Stamp',
                                                    'Points',
                                                    'Activity',
                                                  ],
                                                  onChanged: _selectTab,
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ..._buildTabSlivers(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabSlivers() {
    final tab = _RewardsTab.values[_tabController.index.clamp(0, 2)];
    switch (tab) {
      case _RewardsTab.stamp:
        return _stampSlivers();
      case _RewardsTab.points:
        return _pointsSlivers();
      case _RewardsTab.activity:
        return _activitySlivers();
    }
  }

  List<Widget> _stampSlivers() {
    if (_enrollments.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyTab(
            title: context.l10n.noRewardProgramsYet,
            subtitle: context.l10n
                .whenABusinessEnrollsYouInTheirRewardProgramItWillAppearHere,
            actionLabel: context.l10n.scanQRCode,
            onAction: _openScan,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          BarqodyChrome.sidePad,
          0,
          BarqodyChrome.sidePad,
          28,
        ),
        sliver: SliverList.separated(
          itemCount: _enrollments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final enrollment = _enrollments[index];
            return _StampListCard(
              enrollment: enrollment,
              cardBg: _cardBg,
              cardBorder: _cardBorder,
              muted: _muted,
              onTap: () => _openDetails(enrollment),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _pointsSlivers() {
    final cards = _pointsCards;
    if (cards.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyTab(
            title: 'No points yet',
            subtitle:
                'Earn points when you shop with participating businesses.',
            actionLabel: context.l10n.scanQRCode,
            onAction: _openScan,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          BarqodyChrome.sidePad,
          0,
          BarqodyChrome.sidePad,
          28,
        ),
        sliver: SliverList.separated(
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _PointsListCard(
              card: card,
              cardBg: _cardBg,
              cardBorder: _cardBorder,
              muted: _muted,
              formatPoints: _formatInt,
              onTap: () => _openDetails(card.enrollment),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _activitySlivers() {
    final items = _activityItems;
    if (items.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyTab(
            title: 'No activity yet',
            subtitle:
                'Your stamp and points activity will show up here as you earn rewards.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          BarqodyChrome.sidePad,
          0,
          BarqodyChrome.sidePad,
          28,
        ),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ActivityListCard(
              item: item,
              cardBg: _cardBg,
              cardBorder: _cardBorder,
              muted: _muted,
              positiveGreen: _positiveGreen,
              dateLabel: _formatActivityDate(item.at),
            );
          },
        ),
      ),
    ];
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: WaUi.toolsTitleOf(
            size: 28,
            weight: FontWeight.w700,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: 13,
            color: const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
      ],
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
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
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
                              fontSize: 15,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: i == selected
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
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

class _StampListCard extends StatelessWidget {
  final RewardEnrollment enrollment;
  final Color cardBg;
  final Color cardBorder;
  final Color muted;
  final VoidCallback onTap;

  const _StampListCard({
    required this.enrollment,
    required this.cardBg,
    required this.cardBorder,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final title = program?.title.isNotEmpty == true
        ? program!.title
        : context.l10n.rewardProgram;
    final total = program?.stamps ?? 0;
    final filled = enrollment.stamps;
    final remaining = (total - filled).clamp(0, total);
    final subtitle = enrollment.isCompleted
        ? context.l10n.rewardUnlocked
        : remaining == 1
            ? '1 more purchase to unlock your reward.'
            : '$remaining more purchases to unlock your reward.';

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              _StampThumb(enrollment: enrollment),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        fontSize: 12,
                        color: muted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Text(
                        '$filled / $total Stamps',
                        style: WaUi.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
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

class _StampThumb extends StatelessWidget {
  final RewardEnrollment enrollment;

  const _StampThumb({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final theme = program?.theme ?? RewardTheme();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: program?.hasDesign == true
            ? LoyaltyCardDesignRenderer(
                design: program!.design!,
                filledStamps: enrollment.stamps,
                borderRadius: 12,
                shadows: const [],
              )
            : Container(
                color: theme.cardBackgroundColor,
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    if ((program?.logo ?? '').isNotEmpty ||
                        (program?.businessPhoto ?? '').isNotEmpty)
                      Expanded(
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              (program!.businessPhoto != null &&
                                      program.businessPhoto!.isNotEmpty)
                                  ? program.businessPhoto!
                                  : program.logo,
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.storefront_rounded,
                                size: 18,
                                color: theme.cardTextColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: theme.cardTextColor,
                        ),
                      ),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        (program?.stamps ?? 6).clamp(1, 6),
                        (i) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < enrollment.stamps
                                ? theme.stampColor
                                : theme.stampBorderColor.withValues(
                                    alpha: 0.35,
                                  ),
                            border: Border.all(
                              color: theme.stampBorderColor,
                              width: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PointsListCard extends StatelessWidget {
  final _CustomerPointsCard card;
  final Color cardBg;
  final Color cardBorder;
  final Color muted;
  final String Function(int) formatPoints;
  final VoidCallback onTap;

  const _PointsListCard({
    required this.card,
    required this.cardBg,
    required this.cardBorder,
    required this.muted,
    required this.formatPoints,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: Colors.white,
                  child: card.photoUrl.isNotEmpty
                      ? Image.network(
                          card.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.storefront_rounded,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: Colors.black,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      card.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Text(
                        '${formatPoints(card.points)} Points',
                        style: WaUi.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

class _ActivityListCard extends StatelessWidget {
  final _ActivityItem item;
  final Color cardBg;
  final Color cardBorder;
  final Color muted;
  final Color positiveGreen;
  final String dateLabel;

  const _ActivityListCard({
    required this.item,
    required this.cardBg,
    required this.cardBorder,
    required this.muted,
    required this.positiveGreen,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.amountLabel,
            style: WaUi.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: item.positive ? positiveGreen : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.merchant} · ${item.orderLabel}',
            style: WaUi.caption.copyWith(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: WaUi.caption.copyWith(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyTab({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 48, 36, 24),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(
              size: 17,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: BarqodyChrome.secondaryText,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            PillButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

class _CustomerPointsCard {
  final String name;
  final String description;
  final int points;
  final String photoUrl;
  final String? businessId;
  final RewardEnrollment enrollment;

  const _CustomerPointsCard({
    required this.name,
    required this.description,
    required this.points,
    required this.photoUrl,
    required this.businessId,
    required this.enrollment,
  });
}

class _ActivityItem {
  final String amountLabel;
  final bool positive;
  final String merchant;
  final String orderLabel;
  final DateTime at;

  const _ActivityItem({
    required this.amountLabel,
    required this.positive,
    required this.merchant,
    required this.orderLabel,
    required this.at,
  });
}

class _RewardsShimmer extends StatelessWidget {
  const _RewardsShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: const [
          ShimmerBox(width: double.infinity, height: 52, borderRadius: 10),
          SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 56,
                  borderRadius: 8,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 56,
                  borderRadius: 8,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 36, borderRadius: 8),
          SizedBox(height: 20),
          ShimmerBox(width: double.infinity, height: 48, borderRadius: 24),
          SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 88, borderRadius: 16),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 88, borderRadius: 16),
        ],
      ),
    );
  }
}

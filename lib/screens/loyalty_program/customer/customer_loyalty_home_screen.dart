import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/api_error_messages.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/connection_error_state.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/reward_card_stack_carousel.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

enum _RewardFilter { all, active, completed }

class CustomerLoyaltyHomeScreen extends StatefulWidget {
  const CustomerLoyaltyHomeScreen({super.key});

  @override
  State<CustomerLoyaltyHomeScreen> createState() =>
      _CustomerLoyaltyHomeScreenState();
}

class _CustomerLoyaltyHomeScreenState extends State<CustomerLoyaltyHomeScreen> {
  static const _swipeHintKey = 'my_rewards_swipe_hint_seen';

  List<RewardEnrollment> _enrollments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;
  _RewardFilter _filter = _RewardFilter.all;
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _showSwipeHint = !SharedPrefHelper.getBool(_swipeHintKey);
    _loadEnrollments();
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
        _currentIndex = 0;
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

  List<RewardEnrollment> get _filtered {
    switch (_filter) {
      case _RewardFilter.active:
        return _enrollments.where((e) => !e.isCompleted).toList();
      case _RewardFilter.completed:
        return _enrollments.where((e) => e.isCompleted).toList();
      case _RewardFilter.all:
        return _enrollments;
    }
  }

  RewardEnrollment? get _current {
    final list = _filtered;
    if (list.isEmpty) return null;
    return list[_currentIndex.clamp(0, list.length - 1)];
  }

  void _setFilter(_RewardFilter filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _currentIndex = 0;
    });
  }

  void _dismissSwipeHint() {
    if (!_showSwipeHint) return;
    SharedPrefHelper.putBool(_swipeHintKey, true);
    if (mounted) setState(() => _showSwipeHint = false);
  }

  void _openDetails(RewardEnrollment enrollment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerProgramDetailsScreen(enrollment: enrollment),
      ),
    );
  }

  void _openBusinessProfile() {
    final businessId = _current?.program?.businessId;
    if (businessId == null || businessId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannedProfileScreen(user: businessId),
      ),
    );
  }

  void _openScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  bool get _canOpenProfile {
    final id = _current?.program?.businessId;
    return id != null && id.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final current = _current;
    final activeCount = _enrollments.where((e) => !e.isCompleted).length;
    final completedCount = _enrollments.where((e) => e.isCompleted).length;
    final showBottomCta =
        !_isLoading && _errorMessage == null && current != null;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        surfaceTintColor: WaUi.toolsScaffold,
        title: Text(context.l10n.myRewards),
        actions: [
          if (current != null)
            IconButton(
              tooltip: context.l10n.details,
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => _openDetails(current),
            ),
        ],
      ),
      body: _isLoading
          ? const _RewardsShimmer()
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: WaUi.accent,
                        onRefresh: _loadEnrollments,
                        child: _enrollments.isEmpty
                            ? _buildEmptyState()
                            : CustomScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        8,
                                        0,
                                        0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            child: Text(
                                              context.l10n.yourRewards,
                                              style: WaUi.caption,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            child: Text(
                                              '$activeCount ${context.l10n.active} · $completedCount ${context.l10n.completed}',
                                              style: WaUi.listSubtitle,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: 34,
                                            child: ListView(
                                              scrollDirection: Axis.horizontal,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                              ),
                                              children: [
                                                WaPillFilterChip(
                                                  label: context.l10n.all,
                                                  selected: _filter ==
                                                      _RewardFilter.all,
                                                  onTap: () => _setFilter(
                                                    _RewardFilter.all,
                                                  ),
                                                ),
                                                WaPillFilterChip(
                                                  label: context.l10n.active,
                                                  selected: _filter ==
                                                      _RewardFilter.active,
                                                  onTap: () => _setFilter(
                                                    _RewardFilter.active,
                                                  ),
                                                ),
                                                WaPillFilterChip(
                                                  label:
                                                      context.l10n.completed,
                                                  selected: _filter ==
                                                      _RewardFilter
                                                          .completed,
                                                  onTap: () => _setFilter(
                                                    _RewardFilter.completed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (filtered.isEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                40,
                                                48,
                                                40,
                                                24,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  context.l10n
                                                      .noRewardProgramsYet,
                                                  textAlign: TextAlign.center,
                                                  style: WaUi.listSubtitle,
                                                ),
                                              ),
                                            )
                                          else
                                            RewardCardStackCarousel(
                                              key: ValueKey(
                                                '${_filter.name}_${filtered.length}',
                                              ),
                                              items: filtered
                                                  .map(
                                                    RewardCardStackItem
                                                        .fromEnrollment,
                                                  )
                                                  .toList(),
                                              initialIndex:
                                                  _currentIndex.clamp(
                                                0,
                                                filtered.length - 1,
                                              ),
                                              showPageIndicator: false,
                                              onPageChanged: (i) => setState(
                                                () => _currentIndex = i,
                                              ),
                                              onSwiped: _dismissSwipeHint,
                                              onCardTap: (i) => _openDetails(
                                                filtered[i],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (filtered.isNotEmpty)
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: _CardMetaSection(
                                        enrollment: current!,
                                        index: _currentIndex.clamp(
                                          0,
                                          filtered.length - 1,
                                        ),
                                        total: filtered.length,
                                        showSwipeHint: _showSwipeHint &&
                                            filtered.length > 1,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    if (showBottomCta)
                      Material(
                        color: WaUi.toolsScaffold,
                        child: SafeArea(
                          top: false,
                          maintainBottomViewPadding: true,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: WaPrimaryButton(
                              label: context.l10n.viewProfile,
                              icon: Icons.storefront_outlined,
                              onPressed: _canOpenProfile
                                  ? _openBusinessProfile
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 100, 32, 32),
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
          style: WaUi.listTitle,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n
              .whenABusinessEnrollsYouInTheirRewardProgramItWillAppearHere,
          textAlign: TextAlign.center,
          style: WaUi.listSubtitle,
        ),
        const SizedBox(height: 28),
        WaPrimaryButton(
          label: context.l10n.scanQRCode,
          icon: Icons.qr_code_scanner_rounded,
          onPressed: _openScan,
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: ConnectionErrorState(
        message: _errorMessage!,
        onRetry: _loadEnrollments,
      ),
    );
  }
}

class _CardMetaSection extends StatelessWidget {
  final RewardEnrollment enrollment;
  final int index;
  final int total;
  final bool showSwipeHint;

  const _CardMetaSection({
    required this.enrollment,
    required this.index,
    required this.total,
    required this.showSwipeHint,
  });

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final businessName = program?.displayBusinessName ?? '';
    final businessPhoto = program?.businessPhoto ?? program?.logo ?? '';
    final totalStamps = program?.stamps ?? 0;
    final filled = enrollment.stamps;
    final progress =
        totalStamps > 0 ? (filled / totalStamps).clamp(0.0, 1.0) : 0.0;
    final showBusiness = businessName.isNotEmpty && businessName != 'Business';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBusiness) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (businessPhoto.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      businessPhoto,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (totalStamps > 0) ...[
            Text(
              enrollment.isCompleted
                  ? context.l10n.rewardUnlocked
                  : context.l10n.stampsProgress(filled, totalStamps),
              textAlign: TextAlign.center,
              style: WaUi.caption,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: WaUi.divider,
                color: WaUi.buttonDark,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (total > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                final selected = i == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? WaUi.buttonDark : WaUi.chipBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '${index + 1} of $total',
              textAlign: TextAlign.center,
              style: WaUi.caption,
            ),
          ],
          if (showSwipeHint) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.swipeToBrowseCards,
              textAlign: TextAlign.center,
              style: WaUi.listSubtitle,
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardsShimmer extends StatelessWidget {
  const _RewardsShimmer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardW = (width - 40).clamp(260.0, 340.0);
    final cardH = (cardW * 1.35).clamp(300.0, 420.0);

    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const ShimmerBox(width: 90, height: 12, borderRadius: 6),
          const SizedBox(height: 8),
          const ShimmerBox(width: 160, height: 14, borderRadius: 6),
          const SizedBox(height: 16),
          Row(
            children: const [
              ShimmerBox(width: 56, height: 34, borderRadius: 99),
              SizedBox(width: 8),
              ShimmerBox(width: 72, height: 34, borderRadius: 99),
              SizedBox(width: 8),
              ShimmerBox(width: 96, height: 34, borderRadius: 99),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ShimmerBox(
              width: cardW,
              height: cardH,
              borderRadius: 22,
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: ShimmerBox(width: 120, height: 14, borderRadius: 6),
          ),
          const SizedBox(height: 10),
          const ShimmerBox(
            width: double.infinity,
            height: 4,
            borderRadius: 99,
          ),
          const SizedBox(height: 16),
          const Center(
            child: ShimmerBox(width: 64, height: 6, borderRadius: 99),
          ),
        ],
      ),
    );
  }
}

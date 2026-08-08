import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/reward_card_stack_carousel.dart';

class CustomerLoyaltyHomeScreen extends StatefulWidget {
  const CustomerLoyaltyHomeScreen({super.key});

  @override
  State<CustomerLoyaltyHomeScreen> createState() =>
      _CustomerLoyaltyHomeScreenState();
}

class _CustomerLoyaltyHomeScreenState extends State<CustomerLoyaltyHomeScreen> {
  List<RewardEnrollment> _enrollments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
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
      _errorMessage = res.message ?? context.l10n.failedToLoadPrograms;
    });
  }

  RewardEnrollment? get _current {
    if (_enrollments.isEmpty) return null;
    return _enrollments[_currentIndex.clamp(0, _enrollments.length - 1)];
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

  @override
  Widget build(BuildContext context) {
    final activeCount = _enrollments.where((e) => !e.isCompleted).length;
    final completedCount = _enrollments.where((e) => e.isCompleted).length;
    final current = _current;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        surfaceTintColor: WaUi.toolsScaffold,
        elevation: 0,
        iconTheme: const IconThemeData(color: WaUi.primaryText),
        title: Text(context.l10n.myRewards, style: WaUi.headline),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadEnrollments,
                  child: _enrollments.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.card_giftcard_outlined,
                                    size: 56,
                                    color: WaUi.secondaryText.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.l10n.noRewardProgramsYet,
                                    style: WaUi.listTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                    ),
                                    child: Text(
                                      context.l10n
                                          .whenABusinessEnrollsYouInTheirRewardProgramItWillAppearHere,
                                      textAlign: TextAlign.center,
                                      style: WaUi.listSubtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                context.l10n.yourRewards,
                                style: WaUi.caption,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '$activeCount ${context.l10n.active} · $completedCount ${context.l10n.completed}',
                                style: WaUi.listSubtitle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RewardCardStackCarousel(
                              key: ValueKey(_enrollments.length),
                              items: _enrollments
                                  .map(RewardCardStackItem.fromEnrollment)
                                  .toList(),
                              initialIndex: _currentIndex.clamp(
                                0,
                                _enrollments.length - 1,
                              ),
                              onPageChanged: (i) =>
                                  setState(() => _currentIndex = i),
                              onCardTap: (i) =>
                                  _openDetails(_enrollments[i]),
                            ),
                            const SizedBox(height: 20),
                            if (current != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _openDetails(current),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        label: Text(context.l10n.details),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: current.program
                                                        ?.businessId !=
                                                    null &&
                                                current.program!.businessId!
                                                    .isNotEmpty
                                            ? _openBusinessProfile
                                            : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: WaUi.buttonDark,
                                        ),
                                        icon: const Icon(
                                          Icons.storefront_outlined,
                                        ),
                                        label: Text(context.l10n.viewProfile),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: WaUi.body,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadEnrollments,
              style: TextButton.styleFrom(
                backgroundColor: WaUi.buttonDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WaUi.radiusPill),
                ),
                elevation: 0,
              ),
              child: Text(context.l10n.tryAgain, style: WaUi.promoButton),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

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
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = res.message ?? 'Failed to load programs';
    });
  }

  Map<String, List<RewardEnrollment>> _groupByBusiness() {
    final grouped = <String, List<RewardEnrollment>>{};
    for (final enrollment in _enrollments) {
      final key =
          enrollment.program?.businessId ??
          enrollment.program?.displayBusinessName ??
          'unknown';
      grouped.putIfAbsent(key, () => []).add(enrollment);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByBusiness();
    final activeCount = _enrollments.where((e) => !e.isCompleted).length;
    final completedCount = _enrollments.where((e) => e.isCompleted).length;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        surfaceTintColor: WaUi.toolsScaffold,
        elevation: 0,
        iconTheme: const IconThemeData(color: WaUi.primaryText),
        title: Text('My Rewards', style: WaUi.headline),
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
                                color: WaUi.secondaryText.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No reward programs yet',
                                style: WaUi.listTitle,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'When a business enrolls you in their reward program, it will appear here.',
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
                      padding: const EdgeInsets.only(bottom: 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: _SummaryCard(
                            businessCount: grouped.length,
                            activeCount: activeCount,
                            completedCount: completedCount,
                          ),
                        ),
                        const WaSectionHeader('Enrolled Businesses'),
                        ...grouped.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _BusinessSection(
                              enrollments: entry.value,
                              onProgramTap: (enrollment) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CustomerProgramDetailsScreen(
                                      enrollment: enrollment,
                                    ),
                                  ),
                                );
                              },
                            ),
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
              child: Text('Try again', style: WaUi.promoButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int businessCount;
  final int activeCount;
  final int completedCount;

  const _SummaryCard({
    required this.businessCount,
    required this.activeCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WaUi.buttonDark,
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Rewards',
            style: WaUi.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            '$businessCount ${businessCount == 1 ? 'Business' : 'Businesses'}',
            style: WaUi.toolsTitle.copyWith(color: Colors.white, fontSize: 30),
          ),
          const SizedBox(height: 6),
          Text(
            '$activeCount active · $completedCount completed',
            style: WaUi.listSubtitle.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _BusinessSection extends StatefulWidget {
  final List<RewardEnrollment> enrollments;
  final void Function(RewardEnrollment enrollment) onProgramTap;

  const _BusinessSection({
    required this.enrollments,
    required this.onProgramTap,
  });

  @override
  State<_BusinessSection> createState() => _BusinessSectionState();
}

class _BusinessSectionState extends State<_BusinessSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.enrollments.first.program;
    final businessName = program?.displayBusinessName ?? 'Business';
    final businessPhoto = program?.businessPhoto;

    return Container(
      decoration: WaUi.promoCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(WaUi.radiusSm),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: WaUi.navPill,
                          backgroundImage:
                              businessPhoto != null && businessPhoto.isNotEmpty
                              ? NetworkImage(businessPhoto)
                              : null,
                          child: businessPhoto == null || businessPhoto.isEmpty
                              ? Text(
                                  businessName.isNotEmpty
                                      ? businessName[0].toUpperCase()
                                      : '?',
                                  style: WaUi.avatarInitial,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(businessName, style: WaUi.chatName),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.enrollments.length} ${widget.enrollments.length == 1 ? 'program' : 'programs'}',
                                style: WaUi.listSubtitle,
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: WaUi.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ScannedProfileScreen(user: program!.businessId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(WaUi.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: WaUi.buttonDark,
                      borderRadius: BorderRadius.circular(WaUi.radiusPill),
                    ),
                    child: Text(
                      'View Profile',
                      style: WaUi.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: WaUi.divider),
            ...widget.enrollments.map(
              (e) => _ProgramTile(
                enrollment: e,
                onTap: () => widget.onProgramTap(e),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final RewardEnrollment enrollment;
  final VoidCallback onTap;

  const _ProgramTile({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final program = enrollment.program;
    final theme = program?.theme ?? RewardTheme();

    return Material(
      color: theme.cardBackgroundColor.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (program?.logo.isNotEmpty == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(WaUi.radiusSm),
                  child: Image.network(
                    program!.logo,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              if (program?.logo.isNotEmpty == true) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program?.title ?? 'Program',
                      style: WaUi.listTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${enrollment.stamps} / ${program?.stamps ?? '?'} stamps',
                      style: WaUi.listSubtitle,
                    ),
                  ],
                ),
              ),
              if (enrollment.isCompleted)
                const Icon(Icons.check_circle, color: WaUi.accent, size: 20)
              else
                const Icon(
                  Icons.chevron_right,
                  color: WaUi.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

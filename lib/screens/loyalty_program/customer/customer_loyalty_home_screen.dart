import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Rewards',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.card_giftcard_outlined,
                                size: 56,
                                color: Colors.black26,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reward programs yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'When a business enrolls you in their reward program, it will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _SummaryCard(
                          businessCount: grouped.length,
                          activeCount: activeCount,
                          completedCount: completedCount,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Enrolled Businesses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...grouped.entries.map(
                          (entry) => _BusinessSection(
                            enrollments: entry.value,
                            onProgramTap: (enrollment) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomerProgramDetailsScreen(
                                    enrollment: enrollment,
                                  ),
                                ),
                              );
                            },
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
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadEnrollments,
              child: const Text('Try again'),
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
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Rewards', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            '$businessCount ${businessCount == 1 ? 'Business' : 'Businesses'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$activeCount active · $completedCount completed',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _BusinessSection extends StatelessWidget {
  final List<RewardEnrollment> enrollments;
  final void Function(RewardEnrollment enrollment) onProgramTap;

  const _BusinessSection({
    required this.enrollments,
    required this.onProgramTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = enrollments.first.program;
    final businessName = program?.displayBusinessName ?? 'Business';
    final businessPhoto = program?.businessPhoto;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      businessPhoto != null && businessPhoto.isNotEmpty
                      ? NetworkImage(businessPhoto)
                      : null,
                  child: businessPhoto == null || businessPhoto.isEmpty
                      ? Text(
                          businessName.isNotEmpty
                              ? businessName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${enrollments.length} ${enrollments.length == 1 ? 'program' : 'programs'}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ScannedProfileScreen(user: program!.businessId),
                      ),
                    );
                  },
                  child: Container(
                    // height: 30,
                    // width: 100,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "View Profile",
                        style: TextStyle(
                          color: AppTheme.secondaryWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...enrollments.map(
            (e) => _ProgramTile(enrollment: e, onTap: () => onProgramTap(e)),
          ),
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withOpacity(0.08),
        ),
        child: Row(
          children: [
            if (program?.logo.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${enrollment.stamps} / ${program?.stamps ?? '?'} stamps',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (enrollment.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else
              const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

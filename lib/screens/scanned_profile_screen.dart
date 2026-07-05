import 'package:flutter/material.dart';
import 'package:tapni_app/helper/launcher.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';

Map<String, dynamic> _unwrapApiPayload(dynamic data) {
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }
  return {};
}

class ScannedProfileScreen extends StatefulWidget {
  final String? username;
  final String? user;

  const ScannedProfileScreen({super.key, this.username, this.user});

  @override
  State<ScannedProfileScreen> createState() => _ScannedProfileScreenState();
}

class _ScannedProfileScreenState extends State<ScannedProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasActivePrograms = false;
  bool _programsChecked = false;
  bool _isCustomerEnrolledInBusiness = false;
  bool _enrollmentStatusChecked = false;
  List<RewardEnrollment> _customerProgramEnrollments = [];
  bool _isEmployee = false;
  bool _employeeStatusChecked = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _checkBusinessPrograms();
  }

  Future<void> _loadCustomerEnrollmentStatus(String customerId) async {
    final isBusinessUser =
        Provider.of<ProfileProvider>(context, listen: false).isProUser;
    if (!isBusinessUser) {
      if (mounted) setState(() => _enrollmentStatusChecked = true);
      return;
    }

    final res = await RewardRepo().getCustomerBusinessStatus(customerId);
    if (!mounted) return;

    var isEnrolled = false;
    var programEnrollments = <RewardEnrollment>[];

    if (res.success && res.data != null) {
      final data = _unwrapApiPayload(res.data);
      isEnrolled = data['isBusinessEnrolled'] as bool? ?? false;
      final list = data['programEnrollments'] as List? ?? [];
      programEnrollments = list
          .map((e) => RewardEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    setState(() {
      _isCustomerEnrolledInBusiness = isEnrolled;
      _customerProgramEnrollments = programEnrollments;
      _enrollmentStatusChecked = true;
    });
  }

  Future<void> _loadEmployeeStatus(String employeeUserId) async {
    final isBusinessUser =
        Provider.of<ProfileProvider>(context, listen: false).isProUser;
    if (!isBusinessUser) {
      if (mounted) setState(() => _employeeStatusChecked = true);
      return;
    }

    final res = await AttendanceRepo().getEmployeeStatus(employeeUserId);
    if (!mounted) return;

    var isEmployee = false;
    if (res.success && res.data != null) {
      final data = _unwrapApiPayload(res.data);
      isEmployee = data['isEmployee'] as bool? ?? false;
    }

    setState(() {
      _isEmployee = isEmployee;
      _employeeStatusChecked = true;
    });
  }

  Future<void> _addAsEmployee(UserProfile profile) async {
    if (profile.id == null) return;

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeSettingsScreen(
          employeeUserId: profile.id,
          employeeName: profile.name,
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() => _isEmployee = true);
    }
  }

  Future<void> _checkBusinessPrograms() async {
    final isBusinessUser =
        Provider.of<ProfileProvider>(context, listen: false).isProUser;
    if (!isBusinessUser) {
      if (mounted) setState(() => _programsChecked = true);
      return;
    }

    final res = await RewardRepo().getPrograms();
    if (!mounted) return;

    var hasActive = false;
    if (res.success && res.data != null) {
      final list = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      hasActive = list.any((e) {
        final map = e as Map<String, dynamic>;
        return map['isActive'] as bool? ?? true;
      });
    }

    setState(() {
      _hasActivePrograms = hasActive;
      _programsChecked = true;
    });
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = widget.username != null && widget.username!.isNotEmpty
        ? await AuthRepo().profileByUsername(username: widget.username!, isScan: true)
        : await AuthRepo().profileById(id: widget.user!, isScan: true);

    if (!mounted) return;

    if (response.success && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (userJson != null) {
        final profile = UserProfile.fromApiJson(userJson);
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
        if (profile.id != null) {
          _loadCustomerEnrollmentStatus(profile.id!);
          _loadEmployeeStatus(profile.id!);
        } else {
          setState(() => _enrollmentStatusChecked = true);
          setState(() => _employeeStatusChecked = true);
        }
        // Automatically add scanned contact to the user's contact list
        if (mounted) {
          if (widget.username != null && widget.username!.isNotEmpty) {
            Provider.of<LeadsProvider>(
              context,
              listen: false,
            ).addScannedContact(widget.username!);
          }
        }
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? 'Profile not found.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.username ?? "Profile",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [_buildAppBarMenu()],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView()
            : _buildProfileView(_profile!),
      ),
    );
  }

  Widget _buildAppBarMenu() {
    if (_isLoading || _errorMessage != null || _profile == null) {
      return const SizedBox.shrink();
    }

    final isBusinessUser =
        Provider.of<ProfileProvider>(context, listen: false).isProUser;
    if (!isBusinessUser || !_employeeStatusChecked || _profile!.id == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Business options',
      onSelected: (value) {
        if (value == 'add_employee' && !_isEmployee) {
          _addAsEmployee(_profile!);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'add_employee',
          enabled: !_isEmployee,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _isEmployee
                  ? Icons.badge_outlined
                  : Icons.person_add_alt_1_outlined,
              color: _isEmployee ? Colors.green.shade700 : Colors.black87,
            ),
            title: Text(
              _isEmployee ? 'Already Employee' : 'Add as Employee',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isEmployee ? Colors.green.shade700 : Colors.black87,
              ),
            ),
            subtitle: Text(
              _isEmployee
                  ? 'This person is on your team'
                  : 'Add to your staff for attendance',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _fetchProfile,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    final isBusinessUser =
        Provider.of<ProfileProvider>(context, listen: false).isProUser;
    final showRewardsButton = _programsChecked &&
        _enrollmentStatusChecked &&
        isBusinessUser &&
        _hasActivePrograms &&
        profile.id != null;
    final rewardButtonLabel =
        _isCustomerEnrolledInBusiness ? 'Enrolled' : 'Not Enrolled';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Image.asset('assets/images/jpg/barqody_name.jpg', width: 120),
          const SizedBox(height: 20),
          _buildProfileAvatar(profile),
          const SizedBox(height: 20),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exchanging contact...')),
                  );
                  final res = await AuthRepo().exchangeContact(
                    username: widget.username,
                    id: widget.user,
                  );
                  if (mounted) {
                    if (res.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact exchanged successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            res.message ?? 'Failed to exchange contact',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.sync_alt),
                label: const Text('Exchange Contact'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              if (showRewardsButton) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _showRewardSheet(profile),
                  icon: Icon(
                    _isCustomerEnrolledInBusiness
                        ? Icons.check_circle_outline
                        : Icons.card_giftcard_outlined,
                    size: 18,
                  ),
                  label: Text(rewardButtonLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isCustomerEnrolledInBusiness
                        ? Colors.green.shade700
                        : Colors.black,
                    side: BorderSide(
                      color: _isCustomerEnrolledInBusiness
                          ? Colors.green.shade700
                          : Colors.black,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _buildLinkSection(profile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    final hasCover =
        profile.coverPhotoUrl != null &&
        profile.coverPhotoUrl!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          color: hasCover ? const Color(0xFFF5F5F5) : Colors.transparent,
          child: hasCover
              ? Image.network(profile.coverPhotoUrl!, fit: BoxFit.cover)
              : null,
        ),
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: hasCover ? 100 : 130,
                height: hasCover ? 100 : 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200
                  // color: const Color(0xFF1E2022),

                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.08),
                  //     blurRadius: 10,
                  //     offset: const Offset(0, 4),
                  //   ),
                  // ],
                ),
                child: ClipOval(
                  child:
                      profile.profilePhotoUrl != null &&
                          profile.profilePhotoUrl!.trim().isNotEmpty
                      ? Image.network(
                          profile.profilePhotoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSection(UserProfile profile) {
    final activeLinks = profile.socialLinks
        .where((link) => link.isActive && link.isPublic)
        .toList();

    if (activeLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: activeLinks.map((link) {
          return GestureDetector(
            onTap: () => Launcher.openLink(
              link,
              context,
              businessId: profile.id,
              businessName: profile.businessName ?? profile.name,
              businessCategory: profile.businessCategory,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  _buildLinkIcon(link),
                  const SizedBox(height: 8),
                  Text(
                    link.platformName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLinkIcon(SocialLink link) {
    final isCatalog = link.fieldType == 'menu_catalog' ||
        link.catalogItems != null ||
        link.url?.startsWith('catalog:') == true;
    final logo = link.logoUrl?.trim() ?? '';

    if (logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          logo,
          fit: BoxFit.contain,
          height: 130,
          width: 130,
          errorBuilder: (_, __, ___) => _linkIconFallback(isCatalog),
        ),
      );
    }

    return _linkIconFallback(isCatalog);
  }

  Widget _linkIconFallback(bool isCatalog) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isCatalog ? Icons.restaurant_menu : Icons.link,
        size: isCatalog ? 56 : 32,
        color: Colors.black87,
      ),
    );
  }

  void _showRewardSheet(UserProfile customer) async {
    final repo = RewardRepo();

    final programsFuture = repo.getPrograms();
    final statusFuture = repo.getCustomerBusinessStatus(customer.id!);
    final results = await Future.wait([programsFuture, statusFuture]);

    if (!mounted) return;

    final programsRes = results[0];
    final statusRes = results[1];

    List<RewardProgram> allPrograms = [];
    var isBusinessEnrolled = _isCustomerEnrolledInBusiness;
    List<RewardEnrollment> enrollments = List.from(_customerProgramEnrollments);

    if (programsRes.success && programsRes.data != null) {
      final list = programsRes.data is List
          ? programsRes.data as List
          : (programsRes.data['data'] as List? ?? []);
      allPrograms = list
          .map((e) => RewardProgram.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();
    }

    if (statusRes.success && statusRes.data != null) {
      final data = _unwrapApiPayload(statusRes.data);
      isBusinessEnrolled = data['isBusinessEnrolled'] as bool? ?? false;
      final list = data['programEnrollments'] as List? ?? [];
      enrollments = list
          .map((e) => RewardEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final enrolledProgramIds = enrollments.map((e) => e.programId).toSet();
    final notEnrolledPrograms = allPrograms
        .where((p) => !enrolledProgramIds.contains(p.id))
        .toList();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: isBusinessEnrolled ? 0.65 : 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (_, scrollCtrl) => _RewardSheetContent(
          customer: customer,
          isBusinessEnrolled: isBusinessEnrolled,
          enrollments: enrollments,
          notEnrolledPrograms: notEnrolledPrograms,
          repo: repo,
          scrollController: scrollCtrl,
          onEnrollmentUpdated: _onEnrollmentUpdated,
        ),
      ),
    );

    if (mounted) {
      await _loadCustomerEnrollmentStatus(customer.id!);
    }
  }

  void _onEnrollmentUpdated(bool isEnrolled, List<RewardEnrollment> enrollments) {
    if (!mounted) return;
    setState(() {
      _isCustomerEnrolledInBusiness = isEnrolled;
      _customerProgramEnrollments = enrollments;
    });
  }
}

// ─── Reward Bottom Sheet ──────────────────────────────────────────────────────
class _RewardSheetContent extends StatefulWidget {
  final UserProfile customer;
  final bool isBusinessEnrolled;
  final List<RewardEnrollment> enrollments;
  final List<RewardProgram> notEnrolledPrograms;
  final RewardRepo repo;
  final ScrollController scrollController;
  final void Function(bool isEnrolled, List<RewardEnrollment> enrollments)?
      onEnrollmentUpdated;

  const _RewardSheetContent({
    required this.customer,
    required this.isBusinessEnrolled,
    required this.enrollments,
    required this.notEnrolledPrograms,
    required this.repo,
    required this.scrollController,
    this.onEnrollmentUpdated,
  });

  @override
  State<_RewardSheetContent> createState() => _RewardSheetContentState();
}

class _RewardSheetContentState extends State<_RewardSheetContent> {
  late bool _isBusinessEnrolled;
  late List<RewardEnrollment> _enrollments;
  late List<RewardProgram> _notEnrolled;
  String? _enrollingId;
  bool _isEnrollingBusiness = false;

  @override
  void initState() {
    super.initState();
    _isBusinessEnrolled = widget.isBusinessEnrolled;
    _enrollments = widget.enrollments;
    _notEnrolled = widget.notEnrolledPrograms;
  }

  Future<void> _enrollInBusiness() async {
    setState(() => _isEnrollingBusiness = true);
    final res = await widget.repo.enrollCustomerInBusiness(widget.customer.id!);
    if (!mounted) return;
    setState(() => _isEnrollingBusiness = false);

    if (res.success) {
      setState(() => _isBusinessEnrolled = true);
      widget.onEnrollmentUpdated?.call(true, _enrollments);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer enrolled successfully')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to enroll customer')),
      );
    }
  }

  Future<void> _enrollProgram(RewardProgram program) async {
    setState(() => _enrollingId = program.id);
    final res = await widget.repo.enrollCustomer(
      program.id,
      widget.customer.id!,
    );
    if (!mounted) return;
    setState(() => _enrollingId = null);

    if (res.success && res.data != null) {
      final newEnrollment = RewardEnrollment.fromJson(
        res.data['data'] ?? res.data,
      );
      final enriched = RewardEnrollment(
        id: newEnrollment.id,
        program: program,
        programId: program.id,
        stamps: newEnrollment.stamps,
        status: newEnrollment.status,
      );
      setState(() {
        _isBusinessEnrolled = true;
        _enrollments = [..._enrollments, enriched];
        _notEnrolled = _notEnrolled.where((p) => p.id != program.id).toList();
      });
      widget.onEnrollmentUpdated?.call(true, _enrollments);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to add program')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    _isBusinessEnrolled
                        ? Icons.check_circle_outline
                        : Icons.card_giftcard_outlined,
                    color: _isBusinessEnrolled ? Colors.green.shade700 : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rewards for ${widget.customer.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _isBusinessEnrolled ? 'Enrolled' : 'Not Enrolled',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isBusinessEnrolled
                                ? Colors.green.shade700
                                : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: _isBusinessEnrolled
                    ? _buildEnrolledContent()
                    : _buildNotEnrolledContent(),
              ),
            ),
          ],
        ),
    );
  }

  List<Widget> _buildNotEnrolledContent() {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer is not enrolled yet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enroll ${widget.customer.name} in your business rewards, then assign programs below.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isEnrollingBusiness ? null : _enrollInBusiness,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isEnrollingBusiness
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enroll Customer'),
              ),
            ),
          ],
        ),
      ),
      if (_notEnrolled.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Business Programs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        ..._notEnrolled.map((p) => _availableTile(p, enrollLabel: 'Enroll')),
      ] else
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No active reward programs available.',
              style: TextStyle(color: Colors.black38),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildEnrolledContent() {
    return [
      if (_enrollments.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 6),
          child: Text(
            'Assigned Programs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        ..._enrollments.map((e) => _enrolledTile(e)),
      ] else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No programs assigned yet. Add programs below.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      if (_notEnrolled.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            'Add Program',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        ..._notEnrolled.map((p) => _availableTile(p, enrollLabel: 'Add')),
      ],
      if (_enrollments.isEmpty && _notEnrolled.isEmpty)
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No active reward programs available.',
              style: TextStyle(color: Colors.black38),
            ),
          ),
        ),
    ];
  }

  Widget _enrolledTile(RewardEnrollment e) {
    final prog = e.program;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddStampScreen(enrollment: e),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: prog?.theme.cardBackgroundColor ?? Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          if (prog?.logo.isNotEmpty == true)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(prog!.logo, width: 36, height: 36, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          if (prog?.logo.isNotEmpty == true) const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prog?.title ?? 'Program',
                  style: TextStyle(color: prog?.theme.cardTextColor ?? Colors.white, fontWeight: FontWeight.bold)),
              Text('${e.stamps} / ${prog?.stamps ?? '?'} stamps',
                  style: TextStyle(color: (prog?.theme.cardTextColor ?? Colors.white).withOpacity(0.6), fontSize: 12)),
            ],
          )),
          if (e.isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            Icon(Icons.chevron_right, color: (prog?.theme.cardTextColor ?? Colors.white).withOpacity(0.5)),
        ]),
      ),
    );
  }

  Widget _availableTile(RewardProgram program, {required String enrollLabel}) {
    final isLoading = _enrollingId == program.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        if (program.logo.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              program.logo,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        if (program.logo.isNotEmpty) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(program.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${program.stamps} stamps required',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: () => _enrollProgram(program),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(72, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(enrollLabel, style: const TextStyle(fontSize: 13)),
              ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/create_reward_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/enroll_customer_flow.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';

/// Figma `Program Detail` — stats grid, Recent Enrolled list, bottom actions.
class LoyaltyProgramDetailsScreen extends StatefulWidget {
  final String programId;
  const LoyaltyProgramDetailsScreen({super.key, required this.programId});

  @override
  State<LoyaltyProgramDetailsScreen> createState() =>
      _LoyaltyProgramDetailsScreenState();
}

class _LoyaltyProgramDetailsScreenState
    extends State<LoyaltyProgramDetailsScreen> {
  static const _cardFill = Color(0xFFF3F4F6);
  static const _cardRadius = 20.0;

  RewardProgram? _program;
  List<RewardEnrollment> _enrollments = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<RewardEnrollment> _parseEnrollments(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => RewardEnrollment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final res = await RewardRepo().getProgramById(widget.programId);
    if (!mounted) return;

    RewardProgram? program;
    var enrollments = <RewardEnrollment>[];

    if (res.success && res.data != null) {
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        program = RewardProgram.fromJson(map);
        enrollments = _parseEnrollments(map['recentEnrollments']);
      }
    }

    if (enrollments.isEmpty) {
      final er = await RewardRepo().getProgramEnrollments(widget.programId);
      if (!mounted) return;
      if (er.success && er.data != null) {
        final raw = er.data is Map ? er.data['data'] ?? er.data : er.data;
        enrollments = _parseEnrollments(raw);
      }
    }

    setState(() {
      _isLoading = false;
      _program = program;
      _enrollments = enrollments;
    });
  }

  Future<void> _openEnrollOptions() async {
    final program = _program;
    if (program == null) return;

    final choice = await showAppModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetMessengerScope(
        child: SheetScaffold(
          body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHeader(title: 'Enroll Customer'),
                  _EnrollOptionTile(
                    iconAsset: 'assets/images/png/pd-scan-icon.png',
                    title: 'Scan QR',
                    subtitle: 'Scan a customer BarQody QR code',
                    onTap: () => Navigator.pop(ctx, 'scan'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
                  _EnrollOptionTile(
                    iconAsset: 'assets/images/png/username-img.png',
                    title: 'Search username',
                    subtitle: 'Find and enroll by name or @username',
                    onTap: () => Navigator.pop(ctx, 'username'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'scan') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ScanScreen(enrollInProgram: program),
        ),
      );
    } else if (choice == 'username') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => FindUserScreen(
            title: 'Enroll by Username',
            onUserSelected: (user) async {
              if (user.id.trim().isEmpty) return;
              final nav = Navigator.of(context);
              final ok = await enrollCustomerAndOpenStamp(
                context: context,
                program: program,
                customerId: user.id,
                customerName: user.name.isNotEmpty ? user.name : null,
                customerUsername: user.username,
                customerPhoto: user.profilePhoto,
              );
              if (ok && context.mounted) {
                nav.pop(); // leave FindUserScreen
              }
            },
          ),
        ),
      );
    }
    if (mounted) _load();
  }

  Future<void> _editSettings() async {
    final p = _program!;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRewardScreen(existing: p),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _customizeCard() async {
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
      changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LoyaltyTemplateGalleryScreen(existing: p),
        ),
      );
    }
    if (changed == true) _load();
  }

  Future<void> _openEnrollment(RewardEnrollment enrollment) async {
    final withProgram = enrollment.program != null
        ? enrollment
        : enrollment.copyWith(program: _program);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStampScreen(
          enrollment: withProgram,
          customerName: enrollment.customerName,
          customerUsername: enrollment.customerUsername,
          customerPhoto: enrollment.customerPhoto,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Program Detail',
              trailing: CircleAssetButton(
                asset: 'assets/images/png/pd-scan-icon.png',
                iconSize: 20,
                onTap: _openEnrollOptions,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : _program == null
                      ? Center(
                          child: Text(
                            context.l10n.programNotFound,
                            style: WaUi.bodyMedium,
                          ),
                        )
                      : _buildContent(side),
            ),
            if (_program != null) _buildBottomActions(side),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(double side) {
    // Figma: Customize Card (outline) | Edit Setting (filled)
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, 8, side, 16),
        child: Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Customize Card',
                filled: false,
                onPressed: _customizeCard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                label: 'Edit Setting',
                onPressed: _editSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double side) {
    final m = AuthScale.of(context);
    final stats = _program?.stats;
    final enrolled = stats?.totalEnrollments ?? _enrollments.length;
    final stamps = stats?.totalStampsGiven ?? 0;
    final rewards = stats?.rewardsGiven ?? 0;
    final visits = stats?.visits ?? 0;
    final gap = m.v(12).clamp(10.0, 14.0);

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 0, side, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '$enrolled',
                label: 'Customer Enrolled',
                asset: 'assets/images/png/pd-stat-enrolled.png',
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatTile(
                value: '$stamps',
                label: 'Stamps Earned',
                asset: 'assets/images/png/pd-stat-stamps.png',
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '$rewards',
                label: 'Rewards Given',
                asset: 'assets/images/png/pd-stat-rewards.png',
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatTile(
                value: '$visits',
                label: 'Visits',
                asset: 'assets/images/png/pd-stat-visits.png',
              ),
            ),
          ],
        ),
        SizedBox(height: m.v(16).clamp(12.0, 20.0)),
        _RecentEnrolledCard(
          count: enrolled,
          enrollments: _enrollments,
          onOpen: _openEnrollment,
        ),
      ],
    );
  }
}

class _EnrollOptionTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EnrollOptionTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: m.s(20).clamp(16.0, 24.0),
          vertical: m.v(16).clamp(14.0, 18.0),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                iconAsset,
                width: 22,
                height: 22,
                color: Colors.black,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: m.s(14).clamp(12.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WaUi.body.copyWith(
                      fontSize: m.s(16).clamp(15.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(4).clamp(2.0, 6.0)),
                  Text(
                    subtitle,
                    style: WaUi.body.copyWith(
                      fontSize: m.s(13).clamp(12.0, 14.0),
                      color: BarqodyChrome.secondaryText,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String asset;

  const _StatTile({
    required this.value,
    required this.label,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final valueSize = m.s(28).clamp(24.0, 32.0);
    final labelSize = m.s(13).clamp(12.0, 14.0);
    final iconSize = m.s(36).clamp(32.0, 40.0);
    final pad = m.s(16).clamp(14.0, 18.0);
    final tileH = m.v(112).clamp(100.0, 124.0);

    return SizedBox(
      height: tileH,
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: _LoyaltyProgramDetailsScreenState._cardFill,
          borderRadius: BorderRadius.circular(
            _LoyaltyProgramDetailsScreenState._cardRadius,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                asset,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(right: iconSize * 0.35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: WaUi.toolsTitleOf(
                        size: valueSize,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: m.v(4).clamp(2.0, 6.0)),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.body.copyWith(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w400,
                        color: BarqodyChrome.secondaryText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentEnrolledCard extends StatelessWidget {
  final int count;
  final List<RewardEnrollment> enrollments;
  final void Function(RewardEnrollment) onOpen;

  const _RecentEnrolledCard({
    required this.count,
    required this.enrollments,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final titleSize = m.s(17).clamp(15.0, 18.0);
    final countSize = m.s(18).clamp(16.0, 20.0);
    final subSize = m.s(13).clamp(12.0, 14.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _LoyaltyProgramDetailsScreenState._cardFill,
        borderRadius: BorderRadius.circular(
          _LoyaltyProgramDetailsScreenState._cardRadius,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        m.s(16).clamp(14.0, 18.0),
        m.s(16).clamp(14.0, 18.0),
        m.s(16).clamp(14.0, 18.0),
        m.s(8).clamp(6.0, 12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Enrolled',
                      style: WaUi.toolsTitleOf(
                        size: titleSize,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: m.v(4).clamp(2.0, 6.0)),
                    Text(
                      'Currently active team members',
                      style: WaUi.body.copyWith(
                        fontSize: subSize,
                        color: BarqodyChrome.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: WaUi.toolsTitleOf(
                  size: countSize,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: m.v(12).clamp(8.0, 16.0)),
          if (enrollments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'No customers enrolled yet. Scan a QR or search a username to enroll and add stamps.',
                style: WaUi.body.copyWith(
                  fontSize: subSize,
                  color: BarqodyChrome.secondaryText,
                  height: 1.4,
                ),
              ),
            )
          else
            ...[
              for (var i = 0; i < enrollments.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                _EnrollmentRow(
                  enrollment: enrollments[i],
                  onOpen: () => onOpen(enrollments[i]),
                ),
              ],
            ],
        ],
      ),
    );
  }
}

class _EnrollmentRow extends StatelessWidget {
  final RewardEnrollment enrollment;
  final VoidCallback onOpen;

  const _EnrollmentRow({
    required this.enrollment,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final name = enrollment.customerName?.trim().isNotEmpty == true
        ? enrollment.customerName!
        : (enrollment.customerUsername?.trim().isNotEmpty == true
            ? '@${enrollment.customerUsername}'
            : 'Customer');
    final subtitle = enrollment.enrolledByLabel?.trim().isNotEmpty == true
        ? enrollment.enrolledByLabel!
        : 'Enrolled By You';
    final avatarR = m.s(22).clamp(20.0, 24.0);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: m.v(12).clamp(10.0, 14.0)),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarR,
              backgroundColor: Colors.black,
              backgroundImage: enrollment.customerPhoto != null &&
                      enrollment.customerPhoto!.isNotEmpty
                  ? NetworkImage(enrollment.customerPhoto!)
                  : null,
              child: enrollment.customerPhoto == null ||
                      enrollment.customerPhoto!.isEmpty
                  ? Icon(
                      Icons.person,
                      color: Colors.white,
                      size: avatarR,
                    )
                  : null,
            ),
            SizedBox(width: m.s(12).clamp(10.0, 14.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: m.s(15).clamp(14.0, 16.0),
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(2).clamp(1.0, 4.0)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.body.copyWith(
                      fontSize: m.s(12).clamp(11.0, 13.0),
                      color: BarqodyChrome.secondaryText,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              offset: const Offset(0, 36),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'stamp') onOpen();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'stamp',
                  child: Text(
                    context.l10n.addStamp,
                    style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: m.s(22).clamp(20.0, 24.0),
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/customer_detail_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

class AddStampScreen extends StatefulWidget {
  final RewardEnrollment enrollment;
  final String? customerName;
  final String? customerUsername;
  final String? customerPhoto;

  AddStampScreen({
    super.key,
    required this.enrollment,
    this.customerName,
    this.customerUsername,
    this.customerPhoto,
  });

  @override
  State<AddStampScreen> createState() => _AddStampScreenState();
}

class _AddStampScreenState extends State<AddStampScreen> {
  late RewardEnrollment _enrollment;
  bool _isLoading = false;
  bool _justCompleted = false;

  @override
  void initState() {
    super.initState();
    _enrollment = widget.enrollment;
  }

  Future<void> _addStamp() async {
    if (_isLoading || _enrollment.isCompleted) return;
    setState(() => _isLoading = true);
    final res = await RewardRepo().addStamp(_enrollment.id);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final updated = RewardEnrollment.fromJson(res.data['data'] ?? res.data);
      setState(() {
        _enrollment = updated.copyWith(
          customerName: updated.customerName ?? _displayName,
          customerUsername: updated.customerUsername ?? _displayUsername,
          customerPhoto: updated.customerPhoto ?? _displayPhoto,
        );
        _justCompleted = updated.isCompleted;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToAddStamp)),
      );
    }
  }

  String? get _displayName =>
      widget.customerName ?? _enrollment.customerName;

  String? get _displayUsername =>
      widget.customerUsername ?? _enrollment.customerUsername;

  String? get _displayPhoto =>
      widget.customerPhoto ?? _enrollment.customerPhoto;

  bool get _hasProfile =>
      (_displayName?.trim().isNotEmpty == true) ||
      (_displayUsername?.trim().isNotEmpty == true);

  @override
  Widget build(BuildContext context) {
    final program = _enrollment.program;
    final totalStamps = program?.stamps ?? 10;
    final currentStamps = _enrollment.stamps;
    final completed = _justCompleted || _enrollment.isCompleted;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: 'User'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  8,
                  BarqodyChrome.sidePad,
                  16,
                ),
                children: [
                  if (program?.hasDesign == true)
                    LoyaltyCardDesignRenderer(
                      design: program!.design!,
                      filledStamps: currentStamps,
                      borderRadius: 22,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: program?.theme.cardBackgroundColor ?? Colors.black,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (program != null) ...[
                            Text(
                              program.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: program.theme.cardTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            context.l10n.stampsProgress(
                              currentStamps,
                              totalStamps,
                            ),
                            style: TextStyle(
                              color: program?.theme.cardTextColor ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: List.generate(totalStamps, (i) {
                              return RewardStampSlot(
                                filled: i < currentStamps,
                                theme: program?.theme ?? RewardTheme(),
                                animated: true,
                                stampIconUrl: program?.stampIcon,
                                unstampIconUrl: program?.unstampIcon,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  if (completed) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1B8A4A).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/png/congrats.png',
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.celebration_outlined,
                              color: Color(0xFF1B8A4A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.l10n.rewardCompleted,
                              style: WaUi.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B8A4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'User Profile',
                    style: WaUi.sectionHeader.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: BarqodyChrome.fieldFill,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _hasProfile
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailsScreen(),
                                ),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.black,
                              backgroundImage: _displayPhoto != null &&
                                      _displayPhoto!.isNotEmpty
                                  ? NetworkImage(_displayPhoto!)
                                  : null,
                              child: _displayPhoto == null ||
                                      _displayPhoto!.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName?.trim().isNotEmpty == true
                                        ? _displayName!
                                        : context.l10n.customerDetails,
                                    style: WaUi.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_displayUsername?.trim().isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${_displayUsername!.replaceFirst(RegExp(r'^@'), '')}',
                                      style: WaUi.caption.copyWith(
                                        color: BarqodyChrome.secondaryText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_hasProfile)
                              Icon(
                                Icons.chevron_right_rounded,
                                color: BarqodyChrome.secondaryText,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                0,
                BarqodyChrome.sidePad,
                16,
              ),
              child: PillButton(
                label: completed
                    ? context.l10n.cardCompleted
                    : context.l10n.addStamp,
                enabled: !completed && !_isLoading,
                onPressed: _addStamp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

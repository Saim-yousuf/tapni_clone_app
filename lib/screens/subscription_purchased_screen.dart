import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/quick_add_links_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class SubscriptionPurchasedScreen extends StatefulWidget {
  const SubscriptionPurchasedScreen({
    super.key,
    required this.planName,
    required this.planLabel,
    required this.amount,
    required this.currency,
    this.transactionId = '',
    this.startDate,
    this.endDate,
    this.fromRegistration = false,
  });

  final String planName;
  final String planLabel;
  final double amount;
  final String currency;
  final String transactionId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool fromRegistration;

  @override
  State<SubscriptionPurchasedScreen> createState() =>
      _SubscriptionPurchasedScreenState();
}

class _SubscriptionPurchasedScreenState
    extends State<SubscriptionPurchasedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _ringCtrl;
  late final Animation<double> _enterFade;
  late final Animation<double> _enterScale;
  late final Animation<double> _pulseScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _enterFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOut,
    );
    _enterScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _enterCtrl, curve: AppMotion.easeOut),
    );

    // Soft continuous bounce on the badge.
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    // Expanding ring that fades out every loop (no reverse).
    _ringScale = Tween<double>(begin: 0.95, end: 1.48).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _ringFade = Tween<double>(begin: 0.42, end: 0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _enterCtrl.forward();
      if (!mounted) return;
      _bounceCtrl.repeat(reverse: true);
      _ringCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _bounceCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  String _money(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _date(DateTime? value) {
    if (value == null) return '--';
    return '${value.day}/${value.month}/${value.year}';
  }

  String get _txnDisplay {
    final raw = widget.transactionId.trim();
    if (raw.isEmpty) return '—';
    if (raw.startsWith('BQ-')) return raw;
    if (raw.startsWith('#')) return raw;
    // Never show Stripe / Mongo / mock provider ids.
    if (raw.toLowerCase().startsWith('pi_') ||
        raw.toLowerCase().startsWith('ch_') ||
        raw.toLowerCase().startsWith('mock_') ||
        RegExp(r'^[a-f0-9]{24}$', caseSensitive: false).hasMatch(raw)) {
      return '—';
    }
    if (raw.length <= 16) return raw.startsWith('#') ? raw : raw;
    return '—';
  }

  Future<void> _onDone(BuildContext context) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.upgradeToPro();
    await profileProvider.fetchProfile();
    if (!context.mounted) return;

    if (widget.fromRegistration) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const QuickAddLinksScreen()),
        (_) => false,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value, bool bold})>[
      if (_txnDisplay != '—')
        (label: 'Reference', value: _txnDisplay, bold: false),
      (label: 'Plan', value: widget.planName, bold: false),
      (label: 'Billing', value: widget.planLabel, bold: false),
      (label: 'Valid until', value: _date(widget.endDate), bold: false),
      (
        label: 'Purchase amount',
        value: '${widget.currency} ${_money(widget.amount)}',
        bold: true,
      ),
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onDone(context);
      },
      child: Scaffold(
        backgroundColor: AuthUi.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BarqodyTitleBar(
                title: 'Purchased',
                onBack: () => _onDone(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    BarqodyChrome.sidePad,
                    28,
                    BarqodyChrome.sidePad,
                    20,
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _enterCtrl,
                          _bounceCtrl,
                          _ringCtrl,
                        ]),
                        builder: (context, child) {
                          final badgeScale =
                              _enterScale.value * _pulseScale.value;
                          final ringOn = _enterCtrl.isCompleted;
                          return FadeTransition(
                            opacity: _enterFade,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Opacity(
                                  opacity: ringOn ? _ringFade.value : 0,
                                  child: Transform.scale(
                                    scale: _ringScale.value,
                                    child: Container(
                                      width: 108,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: ringOn
                                      ? (_ringFade.value * 0.7)
                                      : 0,
                                  child: Transform.scale(
                                    scale: 0.85 +
                                        (_ringScale.value - 0.95) * 0.75,
                                    child: Container(
                                      width: 108,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black
                                              .withValues(alpha: 0.10),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.scale(
                                  scale: badgeScale,
                                  child: child,
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/png/check-icon-1.png',
                            width: 34,
                            height: 34,
                            color: Colors.white,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.check_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      AppAppear(
                        index: 0,
                        child: Text(
                          'Business Activated',
                          textAlign: TextAlign.center,
                          style: AppFonts.textStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AuthUi.textPrimary,
                            height: 1.15,
                            letterSpacing: -0.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppAppear(
                        index: 1,
                        child: Text(
                          '${widget.planLabel} plan is now active on your account.',
                          textAlign: TextAlign.center,
                          style: AppFonts.textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AuthUi.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppAppear(
                        index: 2,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          decoration: BoxDecoration(
                            color: AuthUi.fieldFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AuthUi.border),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < rows.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AuthUi.border,
                                  ),
                                AppAppear(
                                  index: i + 3,
                                  child: _DetailRow(
                                    label: rows[i].label,
                                    value: rows[i].value,
                                    emphasizeValue: rows[i].bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  8,
                  BarqodyChrome.sidePad,
                  16,
                ),
                child: AppAppear(
                  index: 8,
                  child: AuthPrimaryPillButton(
                    label: 'Done',
                    onPressed: () => _onDone(context),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppFonts.textStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AuthUi.textMuted,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.textStyle(
                fontSize: emphasizeValue ? 16 : 14,
                fontWeight:
                    emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                color: AuthUi.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/complete_profile_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    Key? key,
    required this.phone,
    this.debugOtp,
    this.addAccount = false,
    this.country,
  }) : super(key: key);

  final String phone;
  final String? debugOtp;
  final bool addAccount;
  final String? country;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String? _debugOtp;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _debugOtp = widget.debugOtp;
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
        return;
      }
      if (mounted) setState(() => _secondsLeft -= 1);
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _goToApp() async {
    final subProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    await subProvider.checkSubscriptionStatus();
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    await profileProvider.fetchProfile();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShell()),
      (_) => false,
    );
  }

  Future<void> _handleVerify() async {
    final code = _otpCode;
    if (code.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.pleaseEnter6DigitCode,
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          backgroundColor: WaUi.primaryText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      authProvider.setLoading(true);
      final result = await authProvider.verifyOtp(
        widget.phone,
        code,
        context,
        addAccount: widget.addAccount,
      );
      if (!mounted) return;

      if (result.loggedIn) {
        await _goToApp();
        return;
      }

      if (result.success && result.isNewUser) {
        final token = result.verificationToken;
        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.verificationTokenMissing,
                style: WaUi.body.copyWith(color: Colors.white),
              ),
              backgroundColor: WaUi.primaryText,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              phone: result.phone ?? widget.phone,
              verificationToken: token,
              country: widget.country,
            ),
          ),
        );
      }
    } finally {
      authProvider.setLoading(false);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      authProvider.setLoading(true);
      final result = await authProvider.sendOtp(widget.phone, context);
      if (!mounted) return;
      if (!result.success) return;
      setState(() => _debugOtp = result.otp);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      _startResendTimer();
    } finally {
      authProvider.setLoading(false);
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpCode.length == _otpLength) {
      _handleVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: WaUi.primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.verifyingYourNumber,
                      textAlign: TextAlign.center,
                      style: WaUi.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        style: WaUi.body.copyWith(color: WaUi.secondaryText),
                        children: [
                          TextSpan(text: '${context.l10n.enterTheCodeSentTo} '),
                          TextSpan(
                            text: widget.phone,
                            style: WaUi.bodyMedium.copyWith(
                              color: WaUi.primaryText,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.l10n.wrongNumber,
                        style: WaUi.bodyMedium.copyWith(color: AppTheme.primaryBlack),
                      ),
                    ),
                    if (_debugOtp != null && _debugOtp!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(WaUi.radiusMd),
                          border: Border.all(
                            color: AppTheme.primaryBlack.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.l10n.forTesting,
                              style: WaUi.caption.copyWith(
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _debugOtp!,
                              style: WaUi.headline.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                                color: WaUi.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_otpLength, (index) {
                        return Container(
                          width: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: WaUi.headline.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: AppTheme.primaryBlack,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            decoration: WaUi.fieldDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              radius: 8,
                            ).copyWith(counterText: ''),
                            onChanged: (value) => _onOtpChanged(index, value),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      context.l10n.enter6DigitCode,
                      style: WaUi.caption,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: (_secondsLeft > 0 || authProvider.isLoading)
                          ? null
                          : _handleResend,
                      child: Text(
                        _secondsLeft > 0
                            ? context.l10n.resendCodeIn(
                                '0:${_secondsLeft.toString().padLeft(2, '0')}',
                              )
                            : context.l10n.resendCode,
                        style: WaUi.bodyMedium.copyWith(
                          color: (_secondsLeft > 0 || authProvider.isLoading)
                              ? WaUi.secondaryText
                              : AppTheme.primaryBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: WaPrimaryButton(
                label: context.l10n.next,
                loading: authProvider.isLoading,
                onPressed: authProvider.isLoading ? null : _handleVerify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

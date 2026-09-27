import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/choose_profile_type_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

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
  int _activeIndex = 0;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _debugOtp = widget.debugOtp;
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    for (var i = 0; i < _otpLength; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() => _activeIndex = i);
        }
      });
    }
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
    if (_verifying) return;
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
      _verifying = true;
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
            builder: (_) => ChooseProfileTypeScreen(
              phone: result.phone ?? widget.phone,
              verificationToken: token,
              country: widget.country,
            ),
          ),
        );
      }
    } finally {
      _verifying = false;
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
      _activeIndex = 0;
      _focusNodes.first.requestFocus();
      _startResendTimer();
    } finally {
      authProvider.setLoading(false);
    }
  }

  void _onKeyTap(String digit) {
    if (_activeIndex >= _otpLength) return;
    setState(() {
      _controllers[_activeIndex].text = digit;
      if (_activeIndex < _otpLength - 1) {
        _activeIndex += 1;
        _focusNodes[_activeIndex].requestFocus();
      }
    });
    if (_otpCode.length == _otpLength) {
      _handleVerify();
    }
  }

  void _onBackspace() {
    setState(() {
      if (_controllers[_activeIndex].text.isNotEmpty) {
        _controllers[_activeIndex].clear();
      } else if (_activeIndex > 0) {
        _activeIndex -= 1;
        _controllers[_activeIndex].clear();
        _focusNodes[_activeIndex].requestFocus();
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      // Paste support
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text =
            i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, _otpLength - 1);
      setState(() => _activeIndex = next);
      _focusNodes[next].requestFocus();
      if (digits.length >= _otpLength) _handleVerify();
      return;
    }
    if (value.length == 1 && index < _otpLength - 1) {
      setState(() => _activeIndex = index + 1);
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      setState(() => _activeIndex = index - 1);
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
      backgroundColor: AuthUi.bg,
      appBar: AppBar(
        backgroundColor: AuthUi.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AuthBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('VERIFY', style: AuthUi.screenTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AuthUi.horizontalPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.verifyingYourNumber,
                    style: AuthUi.sectionTitle.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: AuthUi.body,
                      children: [
                        TextSpan(text: '${context.l10n.enterTheCodeSentTo} '),
                        TextSpan(
                          text: widget.phone,
                          style: WaUi.bodyMedium.copyWith(
                            color: AuthUi.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.wrongNumber,
                      style: WaUi.bodyMedium.copyWith(
                        color: AuthUi.textPrimary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (_debugOtp != null && _debugOtp!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AuthUi.fieldFill,
                        borderRadius: BorderRadius.circular(AuthUi.fieldRadius),
                        border: Border.all(color: AuthUi.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.forTesting,
                            style: WaUi.caption.copyWith(
                              color: AuthUi.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _debugOtp!,
                            style: WaUi.headline.copyWith(
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                              color: AuthUi.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      final filled = _controllers[index].text.isNotEmpty;
                      final active = _activeIndex == index;
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: filled && !active
                                ? AuthUi.fieldFill
                                : AuthUi.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? AuthUi.borderFocused
                                  : (filled
                                      ? Colors.transparent
                                      : AuthUi.border),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            showCursor: active,
                            style: WaUi.headline.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: AuthUi.textPrimary,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.only(bottom: 4),
                            ),
                            onTap: () => setState(() => _activeIndex = index),
                            onChanged: (value) => _onOtpChanged(index, value),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  AuthPillButton(
                    label: 'Verify',
                    loading: authProvider.isLoading,
                    onPressed:
                        authProvider.isLoading ? null : _handleVerify,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: (_secondsLeft > 0 || authProvider.isLoading)
                          ? null
                          : _handleResend,
                      child: Text.rich(
                        TextSpan(
                          style: AuthUi.body.copyWith(fontSize: 14),
                          children: [
                            const TextSpan(text: "Didn't receive the code? "),
                            TextSpan(
                              text: context.l10n.resendCode,
                              style: TextStyle(
                                color: (_secondsLeft > 0 ||
                                        authProvider.isLoading)
                                    ? AuthUi.textMuted
                                    : AuthUi.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (_secondsLeft > 0) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        context.l10n.resendCodeIn(
                          '0:${_secondsLeft.toString().padLeft(2, '0')}',
                        ),
                        style: AuthUi.body.copyWith(
                          fontSize: 13,
                          color: AuthUi.textMuted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _NumericKeypad(
            onDigit: _onKeyTap,
            onBackspace: _onBackspace,
          ),
        ],
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: AuthUi.keypadBg,
      padding: EdgeInsets.fromLTRB(8, 10, 8, bottom > 0 ? bottom : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'del'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: row.map((key) {
                  if (key.isEmpty) {
                    return const Expanded(child: SizedBox(height: 46));
                  }
                  if (key == 'del') {
                    return Expanded(
                      child: _KeyCap(
                        onTap: onBackspace,
                        child: const Icon(
                          Icons.backspace_outlined,
                          size: 22,
                          color: AuthUi.textPrimary,
                        ),
                      ),
                    );
                  }
                  return Expanded(
                    child: _KeyCap(
                      onTap: () => onDigit(key),
                      child: Text(
                        key,
                        style: WaUi.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AuthUi.keyBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 46,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

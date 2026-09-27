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
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _debugOtp = widget.debugOtp;
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (i) {
      final node = FocusNode();
      node.onKeyEvent = (focusNode, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.backspace) {
          return KeyEventResult.ignored;
        }
        if (_controllers[i].text.isEmpty && i > 0) {
          _controllers[i - 1].clear();
          _focusNodes[i - 1].requestFocus();
          setState(() {});
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
      return node;
    });
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
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
      _focusNodes.first.requestFocus();
      _startResendTimer();
    } finally {
      authProvider.setLoading(false);
    }
  }

  void _onDigitChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Paste / SMS autofill of full code into one box
    if (digit.length > 1) {
      final chars = digit.split('');
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < chars.length ? chars[i] : '';
      }
      if (chars.length >= _otpLength) {
        _focusNodes[_otpLength - 1].unfocus();
        setState(() {});
        _handleVerify();
      } else {
        _focusNodes[chars.length.clamp(0, _otpLength - 1)].requestFocus();
        setState(() {});
      }
      return;
    }

    if (_controllers[index].text != digit) {
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }

    if (digit.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_otpCode.length == _otpLength) {
      _handleVerify();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canResend = _secondsLeft <= 0 && !authProvider.isLoading;

    return Scaffold(
      backgroundColor: AuthUi.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AuthUi.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
        leading: AuthBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'VERIFY',
          style: AuthUi.screenTitle.copyWith(
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Number',
                style: AuthUi.heroTitle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: AuthUi.body.copyWith(
                    fontSize: 15,
                    height: 1.4,
                    color: AuthUi.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        color: AuthUi.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Change',
                  style: WaUi.bodyMedium.copyWith(
                    color: AuthUi.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: AuthUi.textPrimary,
                  ),
                ),
              ),
              if (_debugOtp != null && _debugOtp!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AuthUi.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${context.l10n.forTesting}: ',
                        style: WaUi.caption.copyWith(
                          color: AuthUi.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _debugOtp!,
                        style: WaUi.bodyMedium.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: AuthUi.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final boxW =
                      ((constraints.maxWidth - gap * (_otpLength - 1)) /
                              _otpLength)
                          .clamp(40.0, 52.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      final filled = _controllers[index].text.isNotEmpty;
                      final active = _focusNodes[index].hasFocus;
                      return SizedBox(
                        width: boxW,
                        height: boxW + 4,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: filled && !active
                                ? AuthUi.fieldFill
                                : AuthUi.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? AuthUi.borderFocused
                                  : (filled
                                      ? Colors.transparent
                                      : const Color(0xFFE0E0E0)),
                              width: active ? 2.2 : 1.2,
                            ),
                          ),
                          child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              textInputAction: index == _otpLength - 1
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              style: WaUi.headline.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AuthUi.textPrimary,
                              ),
                              cursorColor: AuthUi.textPrimary,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                              ),
                              onChanged: (value) =>
                                  _onDigitChanged(index, value),
                              onTap: () {
                                _controllers[index].selection =
                                    TextSelection(
                                  baseOffset: 0,
                                  extentOffset:
                                      _controllers[index].text.length,
                                );
                              },
                            ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 28),
              AuthPillButton(
                label: 'Verify',
                loading: authProvider.isLoading,
                onPressed: authProvider.isLoading ? null : _handleVerify,
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: canResend ? _handleResend : null,
                  child: Text.rich(
                    TextSpan(
                      style: AuthUi.body.copyWith(
                        fontSize: 14,
                        color: AuthUi.textMuted,
                      ),
                      children: [
                        const TextSpan(text: "Didn't receive the code? "),
                        TextSpan(
                          text: 'Resend Code',
                          style: TextStyle(
                            color: canResend
                                ? AuthUi.textPrimary
                                : AuthUi.textMuted,
                            fontWeight: FontWeight.w700,
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
                    'Resend available in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: AuthUi.body.copyWith(
                      fontSize: 13,
                      color: AuthUi.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

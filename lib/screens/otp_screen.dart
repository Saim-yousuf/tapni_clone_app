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
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
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
  int _secondsLeft = _resendSeconds;
  Timer? _timer;
  bool _verifying = false;
  int _cursorIndex = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    for (var i = 0; i < _otpLength; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && mounted) {
          setState(() => _cursorIndex = i);
        }
      });
    }
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final debug = widget.debugOtp?.replaceAll(RegExp(r'[^0-9]'), '');
      if (debug != null && debug.isNotEmpty) {
        _fillDebugOtp(debug);
      } else {
        _focusNodes.first.requestFocus();
      }
    });
  }

  /// Testing OTP from API — fill boxes (no banner). Does not auto-submit.
  void _fillDebugOtp(String digits) {
    final chars = digits.replaceAll(RegExp(r'[^0-9]'), '').split('');
    if (chars.isEmpty) return;
    for (var i = 0; i < _otpLength; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }
    final next = chars.length >= _otpLength
        ? _otpLength - 1
        : chars.length.clamp(0, _otpLength - 1);
    _cursorIndex = next;
    _focusNodes[next].requestFocus();
    setState(() {});
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
      AppPageRoute(builder: (_) => MainShell()),
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
            style: AppFonts.textStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: AuthUi.textPrimary,
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
                style: AppFonts.textStyle(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: AuthUi.textPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.of(context).push(
          AppPageRoute(
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
      _startResendTimer();
      final debug = result.otp?.replaceAll(RegExp(r'[^0-9]'), '');
      if (debug != null && debug.isNotEmpty) {
        _fillDebugOtp(debug);
      } else {
        setState(() => _cursorIndex = 0);
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
      }
    } finally {
      authProvider.setLoading(false);
    }
  }

  void _applyDigits(String digits) {
    final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;

    if (clean.length > 1) {
      final chars = clean.split('');
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < chars.length ? chars[i] : '';
      }
      if (chars.length >= _otpLength) {
        _cursorIndex = _otpLength - 1;
        _focusNodes[_otpLength - 1].requestFocus();
        setState(() {});
        _handleVerify();
      } else {
        _cursorIndex = chars.length.clamp(0, _otpLength - 1);
        _focusNodes[_cursorIndex].requestFocus();
        setState(() {});
      }
      return;
    }

    final i = _cursorIndex.clamp(0, _otpLength - 1);
    _controllers[i].text = clean;
    if (i < _otpLength - 1) {
      _cursorIndex = i + 1;
      _focusNodes[_cursorIndex].requestFocus();
    } else {
      _focusNodes[i].requestFocus();
    }
    setState(() {});
    if (_otpCode.length == _otpLength) {
      _handleVerify();
    }
  }

  void _onKeypadDigit(String digit) => _applyDigits(digit);

  void _onKeypadBackspace() {
    var i = _cursorIndex.clamp(0, _otpLength - 1);
    if (_controllers[i].text.isEmpty && i > 0) {
      i -= 1;
    }
    _controllers[i].clear();
    _cursorIndex = i;
    _focusNodes[i].requestFocus();
    setState(() {});
  }

  void _onDigitChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit.length > 1) {
      _applyDigits(digit);
      return;
    }
    if (_controllers[index].text != digit) {
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }
    if (digit.isNotEmpty && index < _otpLength - 1) {
      _cursorIndex = index + 1;
      _focusNodes[index + 1].requestFocus();
    } else {
      _cursorIndex = index;
    }
    if (_otpCode.length == _otpLength) {
      _handleVerify();
    } else {
      setState(() {});
    }
  }

  TextStyle _text(
    AuthScale m, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AuthUi.textPrimary,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return AppFonts.textStyle(
      fontSize: m.s(size),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canResend = _secondsLeft <= 0 && !authProvider.isLoading;
    final m = AuthScale.of(context);

    return Scaffold(
      backgroundColor: AuthUi.bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthAppBarTitle(
              'VERIFY',
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            // Same rhythm as Login: top-aligned content, keypad pinned bottom.
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  m.padH,
                  m.v(40),
                  m.padH,
                  m.v(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Number',
                      style: _text(
                        m,
                        size: AuthUi.heroTitleSize,
                        weight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: m.v(10)),
                    Text.rich(
                      TextSpan(
                        style: _text(
                          m,
                          size: AuthUi.bodySize,
                          color: AuthUi.textSecondary,
                          height: 1.45,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to '),
                          TextSpan(
                            text: widget.phone,
                            style: _text(
                              m,
                              size: AuthUi.bodySize,
                              weight: FontWeight.w700,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: m.v(8)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Change',
                        style: _text(
                          m,
                          size: AuthUi.bodySize,
                          weight: FontWeight.w700,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AuthUi.textPrimary,
                          decorationThickness: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: m.v(40)),
                    _OtpBoxes(
                      length: _otpLength,
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      cursorIndex: _cursorIndex,
                      onChanged: _onDigitChanged,
                      onBoxTap: (i) {
                        _cursorIndex = i;
                        _focusNodes[i].requestFocus();
                        setState(() {});
                      },
                      scale: m,
                    ),
                    SizedBox(height: m.v(28)),
                    AuthPrimaryPillButton(
                      label: 'Verify',
                      loading: authProvider.isLoading,
                      onPressed:
                          authProvider.isLoading ? null : _handleVerify,
                    ),
                    SizedBox(height: m.v(18)),
                    Center(
                      child: GestureDetector(
                        onTap: canResend ? _handleResend : null,
                        behavior: HitTestBehavior.opaque,
                        child: Text.rich(
                          TextSpan(
                            style: _text(
                              m,
                              size: 14,
                              color: AuthUi.textSecondary,
                            ),
                            children: [
                              const TextSpan(
                                text: "Didn't receive the code? ",
                              ),
                              TextSpan(
                                text: 'Resend Code',
                                style: _text(
                                  m,
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AuthUi.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_secondsLeft > 0) ...[
                      SizedBox(height: m.v(6)),
                      Center(
                        child: Text(
                          'Resend available in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                          style: _text(
                            m,
                            size: 13,
                            color: AuthUi.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AuthNumericKeypad(
              onDigit: _onKeypadDigit,
              onBackspace: _onKeypadBackspace,
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.length,
    required this.controllers,
    required this.focusNodes,
    required this.cursorIndex,
    required this.onChanged,
    required this.onBoxTap,
    required this.scale,
  });

  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final int cursorIndex;
  final void Function(int index, String value) onChanged;
  final ValueChanged<int> onBoxTap;
  final AuthScale scale;

  @override
  Widget build(BuildContext context) {
    final m = scale;

    // Figma: gap ≈ 1/4 of box side → 6*box + 5*(box/4) = width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxW = constraints.maxWidth / 7.25;
        final gap = boxW / 4;
        final radius = m.s(10);

        return Row(
          children: List.generate(length * 2 - 1, (slot) {
            if (slot.isOdd) return SizedBox(width: gap);
            final index = slot ~/ 2;
            final filled = controllers[index].text.isNotEmpty;
            final active = cursorIndex == index;

            final Color bg;
            final Color borderColor;
            final double borderW;
            if (active) {
              bg = AuthUi.bg;
              borderColor = AuthUi.borderFocused;
              borderW = AuthUi.focusBorderWidth;
            } else if (filled) {
              bg = AuthUi.fieldFill;
              borderColor = AuthUi.border;
              borderW = 1;
            } else {
              bg = AuthUi.bg;
              borderColor = AuthUi.border;
              borderW = 1;
            }

            return SizedBox(
              width: boxW,
              height: boxW,
              child: GestureDetector(
                onTap: () => onBoxTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: borderColor, width: borderW),
                  ),
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    readOnly: true,
                    showCursor: true,
                    enableInteractiveSelection: false,
                    keyboardType: TextInputType.none,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    style: AppFonts.textStyle(
                      fontSize: m.s(22),
                      fontWeight: FontWeight.w700,
                      color: AuthUi.textPrimary,
                      height: 1.1,
                    ),
                    cursorColor: AuthUi.textPrimary,
                    cursorWidth: 1.6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      isCollapsed: true,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    onChanged: (value) => onChanged(index, value),
                    onTap: () => onBoxTap(index),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

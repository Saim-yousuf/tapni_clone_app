import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/otp_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/country_picker_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key, this.addAccount = false}) : super(key: key);

  final bool addAccount;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  CountryDialCode _country = defaultCountryDialCode;
  bool _alreadyOnDevice = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String _normalizedPhone() {
    return PhoneUtils.normalize(
      _phoneController.text,
      countryCode: _country.code,
    );
  }

  void _checkAlreadyOnDevice() {
    final phone = _normalizedPhone();
    final already = PhoneUtils.digitsOnly(phone).length >= 10 &&
        context.read<AuthProvider>().isAlreadyOnThisDevice(phone: phone);
    if (already != _alreadyOnDevice) {
      setState(() => _alreadyOnDevice = already);
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.required;
    }
    if (value.replaceAll(RegExp(r'\D'), '').length < 7) {
      return context.l10n.tooShort;
    }
    if (_alreadyOnDevice) {
      return context.l10n.accountAlreadyLoggedInOnDevice;
    }
    return null;
  }

  Future<void> _handleContinue() async {
    final err = _validatePhone(_phoneController.text);
    setState(() => _phoneError = err);
    if (err != null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = _normalizedPhone();

    if (!PhoneUtils.isValid(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.pleaseEnterValidPhoneNumber,
            style: AppFonts.textStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: AuthUi.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (authProvider.isAlreadyOnThisDevice(phone: phone)) {
      setState(() {
        _alreadyOnDevice = true;
        _phoneError = context.l10n.accountAlreadyLoggedInOnDevice;
      });
      return;
    }

    try {
      authProvider.setLoading(true);
      final result = await authProvider.sendOtp(phone, context);
      if (!mounted) return;
      if (!result.success) return;

      Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => OtpScreen(
            phone: result.phone ?? phone,
            debugOtp: result.otp,
            addAccount: widget.addAccount,
            country: regionKeyForDialCountry(_country),
          ),
        ),
      );
    } finally {
      authProvider.setLoading(false);
    }
  }

  Future<void> _pickCountry() async {
    final selected = await showCountryPickerSheet(
      context,
      selectedIso: _country.iso,
    );
    if (selected != null) {
      setState(() => _country = selected);
      _checkAlreadyOnDevice();
    }
  }

  Future<void> _openLegal(String path) async {
    final uri = Uri.parse('${Constants.appDomain}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final phoneFocused = _phoneFocus.hasFocus;
    final m = AuthScale.of(context);

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthAppBarTitle('LOGIN'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    m.padH,
                    m.v(40),
                    m.padH,
                    m.v(24),
                  ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.welcomeBack,
                                textAlign: TextAlign.left,
                                style: _text(
                                  m,
                                  size: 32,
                                  weight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              SizedBox(height: m.v(10)),
                              Text(
                                context.l10n.barqodyWillSendOtp,
                                textAlign: TextAlign.left,
                                style: _text(
                                  m,
                                  size: 15,
                                  color: AuthUi.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              SizedBox(height: m.v(40)),
                              Text(
                                '${context.l10n.country} / REGION'
                                    .toUpperCase(),
                                textAlign: TextAlign.left,
                                style: _text(
                                  m,
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: AuthUi.textMuted,
                                  letterSpacing: 0.85,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: m.v(10)),
                              _CountryField(
                                height: m.fieldH,
                                radius: m.radius,
                                country: _country,
                                textStyle: _text(m, size: 15),
                                onTap: _pickCountry,
                                flagSize: m.s(22),
                                chevronSize: m.s(20),
                                padH: m.s(14),
                              ),
                              SizedBox(height: m.v(18)),
                              Text(
                                context.l10n.phoneNumber.toUpperCase(),
                                textAlign: TextAlign.left,
                                style: _text(
                                  m,
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: AuthUi.textMuted,
                                  letterSpacing: 0.85,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: m.v(10)),
                              _PhoneField(
                                height: m.fieldH,
                                radius: m.radius,
                                focused: phoneFocused,
                                dialCode: _country.code,
                                dialStyle: _text(
                                  m,
                                  size: 15,
                                  weight: FontWeight.w500,
                                ),
                                inputStyle: _text(m, size: 15),
                                hintStyle: _text(
                                  m,
                                  size: 15,
                                  color: AuthUi.textMuted,
                                ),
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                onDialTap: _pickCountry,
                                onChanged: (_) {
                                  _checkAlreadyOnDevice();
                                  if (_phoneError != null) {
                                    setState(() => _phoneError = null);
                                  }
                                },
                                onSubmitted: (_) => _handleContinue(),
                                padH: m.s(14),
                                dividerH: m.s(20),
                              ),
                              if (_phoneError != null) ...[
                                SizedBox(height: m.v(8)),
                                Text(
                                  _phoneError!,
                                  style: _text(
                                    m,
                                    size: 12,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                              SizedBox(height: m.v(32)),
                              AuthPrimaryPillButton(
                                label: context.l10n.continueLabel,
                                loading: authProvider.isLoading,
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleContinue,
                              ),
                              SizedBox(height: m.v(16)),
                              AuthOutlinedPillButton(
                                label: context.l10n.logInWithQRCode,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    AppPageRoute(
                                      builder: (_) => QrLoginScreen(
                                        addAccount: widget.addAccount,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: m.v(28)),
                              Text.rich(
                                TextSpan(
                                  style: _text(
                                    m,
                                    size: 12,
                                    color: AuthUi.textSecondary,
                                    height: 1.45,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${context.l10n.byContinuingYouAgreeTo} ',
                                    ),
                                    WidgetSpan(
                                      alignment:
                                          PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: GestureDetector(
                                        onTap: () => _openLegal('/terms'),
                                        child: Text(
                                          context.l10n.termsOfService,
                                          style: _text(
                                            m,
                                            size: 12,
                                            weight: FontWeight.w700,
                                            height: 1.45,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AuthUi.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Force 2 lines (Figma):
                                    // line1: … Terms of Service
                                    // line2: and Privacy Policy.
                                    TextSpan(
                                      text:
                                          '\n${context.l10n.andConjunction} ',
                                    ),
                                    WidgetSpan(
                                      alignment:
                                          PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: GestureDetector(
                                        onTap: () => _openLegal('/privacy'),
                                        child: Text(
                                          context.l10n.privacyPolicy,
                                          style: _text(
                                            m,
                                            size: 12,
                                            weight: FontWeight.w700,
                                            height: 1.45,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AuthUi.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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

class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.height,
    required this.radius,
    required this.country,
    required this.textStyle,
    required this.onTap,
    required this.flagSize,
    required this.chevronSize,
    required this.padH,
  });

  final double height;
  final double radius;
  final CountryDialCode country;
  final TextStyle textStyle;
  final VoidCallback onTap;
  final double flagSize;
  final double chevronSize;
  final double padH;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuthUi.bg,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: padH),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AuthUi.border, width: 1),
          ),
          child: Row(
            children: [
              Text(
                country.flagEmoji,
                style: TextStyle(fontSize: flagSize, height: 1),
              ),
              SizedBox(width: padH * 0.7),
              Expanded(
                child: Text(
                  '${country.name} (${country.code})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: chevronSize,
                color: AuthUi.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.height,
    required this.radius,
    required this.focused,
    required this.dialCode,
    required this.dialStyle,
    required this.inputStyle,
    required this.hintStyle,
    required this.controller,
    required this.focusNode,
    required this.onDialTap,
    required this.onChanged,
    required this.onSubmitted,
    required this.padH,
    required this.dividerH,
  });

  final double height;
  final double radius;
  final bool focused;
  final String dialCode;
  final TextStyle dialStyle;
  final TextStyle inputStyle;
  final TextStyle hintStyle;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onDialTap;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final double padH;
  final double dividerH;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: height,
      decoration: BoxDecoration(
        color: AuthUi.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: focused ? AuthUi.borderFocused : AuthUi.border,
          width: focused ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onDialTap,
            child: Padding(
              padding: EdgeInsets.only(left: padH, right: padH * 0.7),
              child: Text(dialCode, style: dialStyle),
            ),
          ),
          Container(
            width: 1,
            height: dividerH,
            color: AuthUi.border,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH * 0.85),
              // Theme's InputDecorationTheme draws a nested outline —
              // fully override so only the outer field border shows.
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                style: inputStyle,
                cursorColor: AuthUi.textPrimary,
                cursorWidth: 1.5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  hintText: '(555) 123-4567',
                  hintStyle: hintStyle,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

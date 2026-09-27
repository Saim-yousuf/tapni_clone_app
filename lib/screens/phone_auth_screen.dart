import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/otp_screen.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
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

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
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

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = _normalizedPhone();

    if (!PhoneUtils.isValid(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.pleaseEnterValidPhoneNumber,
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          backgroundColor: WaUi.primaryText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (authProvider.isAlreadyOnThisDevice(phone: phone)) {
      setState(() => _alreadyOnDevice = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.accountAlreadyLoggedInOnDevice,
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          backgroundColor: WaUi.primaryText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      authProvider.setLoading(true);
      final result = await authProvider.sendOtp(phone, context);
      if (!mounted) return;
      if (!result.success) return;

      Navigator.of(context).push(
        MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final phoneFocused = _phoneFocus.hasFocus;

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'LOGIN',
                  style: AuthUi.screenTitle,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuthUi.horizontalPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.welcomeBack,
                        style: AuthUi.heroTitle.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.barqodyWillSendOtp,
                        style: AuthUi.body,
                      ),
                      const SizedBox(height: 28),
                      AuthFieldLabel(
                        '${context.l10n.country} / REGION',
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickCountry,
                        borderRadius:
                            BorderRadius.circular(AuthUi.fieldRadius),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AuthUi.bg,
                            borderRadius:
                                BorderRadius.circular(AuthUi.fieldRadius),
                            border: Border.all(color: AuthUi.border),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _country.flagEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_country.name} (${_country.code})',
                                  style: WaUi.bodyMedium.copyWith(
                                    color: AuthUi.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AuthUi.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFieldLabel(context.l10n.phoneNumber),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: AuthUi.bg,
                          borderRadius:
                              BorderRadius.circular(AuthUi.fieldRadius),
                          border: Border.all(
                            color: phoneFocused
                                ? AuthUi.borderFocused
                                : AuthUi.border,
                            width: phoneFocused ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _pickCountry,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 14,
                                  right: 10,
                                  top: 14,
                                  bottom: 14,
                                ),
                                child: Text(
                                  _country.code,
                                  style: WaUi.bodyMedium.copyWith(
                                    fontSize: 15,
                                    color: AuthUi.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 22,
                              color: AuthUi.border,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                style: WaUi.bodyMedium.copyWith(fontSize: 16),
                                cursorColor: AuthUi.textPrimary,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(15),
                                ],
                                onChanged: (_) => _checkAlreadyOnDevice(),
                                onFieldSubmitted: (_) => _handleContinue(),
                                decoration: InputDecoration(
                                  hintText: context.l10n.phoneNumber2,
                                  hintStyle: WaUi.body.copyWith(
                                    color: AuthUi.textMuted,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  errorText: _alreadyOnDevice
                                      ? context
                                          .l10n.accountAlreadyLoggedInOnDevice
                                      : null,
                                  errorMaxLines: 2,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return context.l10n.required;
                                  }
                                  if (value
                                          .replaceAll(RegExp(r'\D'), '')
                                          .length <
                                      7) {
                                    return context.l10n.tooShort;
                                  }
                                  if (_alreadyOnDevice) {
                                    return context
                                        .l10n.accountAlreadyLoggedInOnDevice;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QrLoginScreen(
                                  addAccount: widget.addAccount,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            context.l10n.logInWithQRCode,
                            style: WaUi.bodyMedium.copyWith(
                              color: AuthUi.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AuthPillButton(
                        label: context.l10n.continueLabel,
                        loading: authProvider.isLoading,
                        onPressed:
                            authProvider.isLoading ? null : _handleContinue,
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          style: AuthUi.body.copyWith(fontSize: 12),
                          children: [
                            TextSpan(
                              text: '${context.l10n.byContinuingYouAgreeTo} ',
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => _openLegal('/terms'),
                                child: Text(
                                  context.l10n.termsOfService,
                                  style: AuthUi.body.copyWith(
                                    fontSize: 12,
                                    color: AuthUi.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' ${context.l10n.andConjunction} ',
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => _openLegal('/privacy'),
                                child: Text(
                                  context.l10n.privacyPolicy,
                                  style: AuthUi.body.copyWith(
                                    fontSize: 12,
                                    color: AuthUi.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
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

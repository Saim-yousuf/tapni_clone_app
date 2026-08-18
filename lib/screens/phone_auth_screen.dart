import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/otp_screen.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/country_picker_sheet.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key, this.addAccount = false}) : super(key: key);

  final bool addAccount;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  CountryDialCode _country = defaultCountryDialCode;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = PhoneUtils.normalize(
      _phoneController.text,
      countryCode: _country.code,
    );

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
    }
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return WaUi.fieldDecoration(hintText: hint);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      Text(
                        context.l10n.enterYourPhoneNumber,
                        textAlign: TextAlign.center,
                        style: WaUi.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.barqodyWillSendOtp,
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(color: WaUi.secondaryText),
                      ),
                      const SizedBox(height: 36),
                      InkWell(
                        onTap: _pickCountry,
                        child: InputDecorator(
                          decoration: WaUi.fieldDecoration(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _country.name,
                                  textAlign: TextAlign.center,
                                  style: WaUi.bodyMedium.copyWith(
                                    color: AppTheme.primaryBlack,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: WaUi.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _pickCountry,
                            child: SizedBox(
                              width: 92,
                              child: InputDecorator(
                                decoration: WaUi.fieldDecoration(),
                                child: Text(
                                  _country.code,
                                  style: WaUi.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              style: WaUi.bodyMedium.copyWith(fontSize: 16),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15),
                              ],
                              onFieldSubmitted: (_) => _handleContinue(),
                              decoration: _fieldDecoration(
                                hint: context.l10n.phoneNumber2,
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
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      TextButton(
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
                          style: WaUi.bodyMedium.copyWith(color: AppTheme.primaryBlack),
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
                  onPressed:
                      authProvider.isLoading ? null : _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            'Please enter a valid phone number',
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
          ),
        ),
      );
    } finally {
      authProvider.setLoading(false);
    }
  }

  Future<void> _pickCountry() async {
    final selected = await Navigator.of(context).push<CountryDialCode>(
      MaterialPageRoute(
        builder: (_) => _CountryPickerScreen(selectedIso: _country.iso),
      ),
    );
    if (selected != null) {
      setState(() => _country = selected);
    }
  }

  InputDecoration _underlineDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: WaUi.body.copyWith(color: WaUi.secondaryText),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: WaUi.divider, width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: WaUi.divider, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppTheme.primaryBlack, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      isDense: true,
    );
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
                        'Enter your phone number',
                        textAlign: TextAlign.center,
                        style: WaUi.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Barqody will send an OTP to verify your number.',
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(color: WaUi.secondaryText),
                      ),
                      const SizedBox(height: 36),
                      InkWell(
                        onTap: _pickCountry,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(bottom: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: WaUi.divider, width: 1),
                            ),
                          ),
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
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _pickCountry,
                            child: SizedBox(
                              width: 80,
                              child: Container(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 12,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: WaUi.divider,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _country.code,
                                  style: WaUi.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
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
                              decoration: _underlineDecoration(
                                hint: 'phone number',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (value
                                        .replaceAll(RegExp(r'\D'), '')
                                        .length <
                                    7) {
                                  return 'Too short';
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
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        authProvider.isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primaryBlack.withValues(
                        alpha: 0.5,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(WaUi.radiusPill),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Next',
                            style: WaUi.promoButton.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _CountryPickerScreen extends StatefulWidget {
  const _CountryPickerScreen({required this.selectedIso});

  final String selectedIso;

  @override
  State<_CountryPickerScreen> createState() => _CountryPickerScreenState();
}

class _CountryPickerScreenState extends State<_CountryPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryDialCode> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kCountryDialCodes;
    return kCountryDialCodes.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.contains(q) ||
          c.iso.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final countries = _filtered;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Choose a country', style: WaUi.headline),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              style: WaUi.body,
              cursorColor: AppTheme.primaryBlack,
              decoration: InputDecoration(
                hintText: 'Search country',
                hintStyle: WaUi.body.copyWith(color: WaUi.secondaryText),
                prefixIcon: const Icon(Icons.search, color: WaUi.secondaryText),
                filled: true,
                fillColor: WaUi.navPill,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaUi.radiusPill),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: countries.isEmpty
                ? Center(
                    child: Text('No countries found', style: WaUi.caption),
                  )
                : ListView.separated(
                    itemCount: countries.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: WaUi.divider,
                    ),
                    itemBuilder: (context, index) {
                      final c = countries[index];
                      final selected = c.iso == widget.selectedIso;
                      return ListTile(
                        title: Text(c.name, style: WaUi.listTitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.code, style: WaUi.listSubtitle),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check,
                                color: AppTheme.primaryBlack,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

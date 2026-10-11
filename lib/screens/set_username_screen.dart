import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/username_policy_models.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/username_claim_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class SetUsernameScreen extends StatefulWidget {
  SetUsernameScreen({super.key});

  @override
  State<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  static const _heading = 'Choose a unique username for your profile';
  static const _hint = 'e.g. your_username';
  static const _fieldRadius = 12.0;
  static const _sidePad = 26.0;
  static const _labelColor = Color(0xFFA3A7B0);

  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepo();
  late final TextEditingController _usernameController;
  late final String _initialUsername;
  Timer? _debounce;
  UsernameCheckResult? _availability;
  bool _checking = false;
  String _lastChecked = '';
  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    _initialUsername = (profile.username ?? '').toLowerCase();
    _usernameController = TextEditingController(text: _initialUsername);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    final username = (value ?? '').trim().toLowerCase();
    if (username.isEmpty) {
      return context.l10n.pleaseEnterAUsername;
    }
    if (username.length < 3) {
      return context.l10n.usernameMustBeAtLeast3Characters;
    }
    if (username.length > 30) {
      return context.l10n.usernameMustBeAtMost30Characters;
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(username)) {
      return context.l10n.useLettersNumbersUnderscoresOrHyphensOnly;
    }
    return null;
  }

  void _scheduleAvailabilityCheck(String value) {
    _debounce?.cancel();
    final username = value.trim().toLowerCase();

    if (username == _initialUsername) {
      setState(() {
        _availability = null;
        _checking = false;
      });
      return;
    }

    final formatError = _validateUsername(username);
    if (formatError != null || username.length < 3) {
      setState(() {
        _availability = UsernameCheckResult(
          status: UsernameAvailabilityStatus.invalid,
          username: username,
        );
        _checking = false;
      });
      return;
    }

    setState(() {
      _checking = true;
      _availability = UsernameCheckResult(
        status: UsernameAvailabilityStatus.checking,
        username: username,
      );
    });

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _checkAvailability(username);
    });
  }

  Future<void> _checkAvailability(String username) async {
    _lastChecked = username;
    final response = await _authRepo.checkUsernameAvailability(username: username);
    if (!mounted || _lastChecked != username) return;

    if (!response.success || response.data is! Map) {
      setState(() {
        _checking = false;
        _availability = UsernameCheckResult(
          status: UsernameAvailabilityStatus.invalid,
          username: username,
        );
      });
      return;
    }

    setState(() {
      _checking = false;
      _availability = UsernameCheckResult.fromApi(
        Map<String, dynamic>.from(response.data as Map),
        username,
      );
    });
  }

  Future<void> _openClaimScreen() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (_validateUsername(username) != null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsernameClaimScreen(username: username),
      ),
    );
  }

  Future<void> _saveUsername() async {
    if (_checking) return;
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim().toLowerCase();
    if (username == _initialUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.thisIsAlreadyYourUsername,
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WaUi.primaryText,
        ),
      );
      return;
    }

    if (_availability != null && !_availability!.canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _availabilityMessage(_availability!),
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WaUi.primaryText,
        ),
      );
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final response = await profileProvider.updateUsername(
      username: username,
      context: context,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? context.l10n.usernameUpdatedSuccessfully
              : response.message ?? context.l10n.unableToUpdateUsernameTryAgain,
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WaUi.primaryText,
      ),
    );

    if (response.success) {
      Navigator.of(context).pop();
    }
  }

  String _availabilityMessage(UsernameCheckResult result) {
    switch (result.status) {
      case UsernameAvailabilityStatus.available:
        return context.l10n.usernameAvailable;
      case UsernameAvailabilityStatus.taken:
        return context.l10n.usernameAlreadyTaken;
      case UsernameAvailabilityStatus.unavailable:
        return context.l10n.usernameUnavailable;
      case UsernameAvailabilityStatus.checking:
        return context.l10n.checkingUsername;
      case UsernameAvailabilityStatus.invalid:
        return context.l10n.useLettersNumbersUnderscoresOrHyphensOnly;
      case UsernameAvailabilityStatus.idle:
        return '';
    }
  }

  Color _availabilityColor(UsernameCheckResult result) {
    switch (result.status) {
      case UsernameAvailabilityStatus.available:
        return const Color(0xFF2E7D32);
      case UsernameAvailabilityStatus.taken:
      case UsernameAvailabilityStatus.unavailable:
        return const Color(0xFFC62828);
      case UsernameAvailabilityStatus.checking:
        return BarqodyChrome.secondaryText;
      default:
        return BarqodyChrome.secondaryText;
    }
  }

  IconData? _availabilityIcon(UsernameCheckResult result) {
    switch (result.status) {
      case UsernameAvailabilityStatus.available:
        return Icons.check_circle_outline;
      case UsernameAvailabilityStatus.taken:
      case UsernameAvailabilityStatus.unavailable:
        return Icons.block_outlined;
      case UsernameAvailabilityStatus.checking:
        return null;
      default:
        return null;
    }
  }

  Widget? _buildAvailabilityBanner() {
    final result = _availability;
    if (result == null) return null;

    final message = _availabilityMessage(result);
    if (message.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.status == UsernameAvailabilityStatus.checking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BarqodyChrome.secondaryText,
              ),
            )
          else if (_availabilityIcon(result) != null)
            Icon(
              _availabilityIcon(result),
              size: 18,
              color: _availabilityColor(result),
            ),
          if (result.status == UsernameAvailabilityStatus.checking ||
              _availabilityIcon(result) != null)
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: WaUi.label.copyWith(color: _availabilityColor(result)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewUsername = _usernameController.text.trim().isEmpty
        ? 'your_username'
        : _usernameController.text.trim().toLowerCase();
    final showClaim = _availability?.canClaim == true;
    final domain = Constants.appDomain
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: Colors.black, width: 1),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              BarqodyTitleBar(title: context.l10n.username),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(_sidePad, 64, _sidePad, 24),
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/png/username-img.png',
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          height: 118,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 52),
                    Text(
                      _heading,
                      textAlign: TextAlign.center,
                      style: AppFonts.textStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 52),
                    Text(
                      context.l10n.username.toUpperCase(),
                      style: AppFonts.textStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _labelColor,
                        letterSpacing: 0.85,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.username],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_-]'),
                        ),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AuthUi.fieldFill,
                        hintText: _hint,
                        hintStyle: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AuthUi.textMuted,
                          height: 1.2,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: fieldBorder,
                        enabledBorder: fieldBorder,
                        focusedBorder: fieldBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_fieldRadius),
                          borderSide: const BorderSide(
                            color: Color(0xFFC62828),
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_fieldRadius),
                          borderSide: const BorderSide(
                            color: Color(0xFFC62828),
                            width: 1,
                          ),
                        ),
                      ),
                      validator: _validateUsername,
                      onChanged: (value) {
                        setState(() {});
                        _scheduleAvailabilityCheck(value);
                      },
                      onFieldSubmitted: (_) => _saveUsername(),
                    ),
                    _buildAvailabilityBanner() ?? const SizedBox.shrink(),
                    const SizedBox(height: 32),
                    Text(
                      'https://$domain/$previewUsername',
                      textAlign: TextAlign.center,
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    if (showClaim) ...[
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.claimUsernameIfUnavailable,
                        textAlign: TextAlign.center,
                        style: WaUi.label.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _checking ? null : _openClaimScreen,
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: Text(context.l10n.claimThisUsername),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: PillButton(
                  label: context.l10n.save,
                  enabled: !_checking,
                  onPressed: _saveUsername,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

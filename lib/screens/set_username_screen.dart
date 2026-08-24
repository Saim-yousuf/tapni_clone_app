import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/username_policy_models.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/my_username_claims_screen.dart';
import 'package:tapni_app/screens/username_claim_screen.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class SetUsernameScreen extends StatefulWidget {
  SetUsernameScreen({super.key});

  @override
  State<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
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
        return WaUi.secondaryText;
      default:
        return WaUi.secondaryText;
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
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WaUi.secondaryText,
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
        ? 'username'
        : _usernameController.text.trim().toLowerCase();
    final showClaim = _availability?.canClaim == true;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: WaUi.primaryText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.username, style: WaUi.headline),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyUsernameClaimsScreen(),
                ),
              );
            },
            child: Text(
              context.l10n.viewMyClaims,
              style: WaUi.bodyMedium.copyWith(color: WaUi.accent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                context.l10n.chooseAUniqueUsernameForYourProfileLink,
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
              const SizedBox(height: 24),
              Text(context.l10n.username, style: WaUi.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.username],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                  LengthLimitingTextInputFormatter(30),
                ],
                style: WaUi.body,
                decoration: WaUi.fieldDecoration(
                  hintText: context.l10n.yourname,
                  prefixIcon: const Icon(Icons.alternate_email, size: 22),
                ),
                validator: _validateUsername,
                onChanged: (value) {
                  setState(() {});
                  _scheduleAvailabilityCheck(value);
                },
                onFieldSubmitted: (_) => _saveUsername(),
              ),
              _buildAvailabilityBanner() ?? const SizedBox.shrink(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: WaUi.fieldBox,
                child: Text(
                  '${Constants.appDomain}/$previewUsername',
                  style: WaUi.bodyMedium.copyWith(color: WaUi.secondaryText),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.n330CharactersLettersNumbersUnderscoresAndHyphensOnly,
                style: WaUi.label,
              ),
              if (showClaim) ...[
                const SizedBox(height: 16),
                Text(
                  context.l10n.claimUsernameIfUnavailable,
                  style: WaUi.label.copyWith(color: WaUi.secondaryText),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checking ? null : _openClaimScreen,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: Text(context.l10n.claimThisUsername),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WaUi.accent,
                    side: BorderSide(color: WaUi.accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: context.l10n.saveUsername,
                isLoading: _checking,
                onTap: _saveUsername,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

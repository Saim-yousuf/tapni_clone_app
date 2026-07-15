import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class SetUsernameScreen extends StatefulWidget {
  SetUsernameScreen({super.key});

  @override
  State<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final String _initialUsername;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    _initialUsername = (profile.username ?? '').toLowerCase();
    _usernameController = TextEditingController(text: _initialUsername);
  }

  @override
  void dispose() {
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

  Future<void> _saveUsername() async {
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

  @override
  Widget build(BuildContext context) {
    final previewUsername = _usernameController.text.trim().isEmpty
        ? 'username'
        : _usernameController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          color: WaUi.primaryText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.username, style: WaUi.headline),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                context.l10n.chooseAUniqueUsernameForYourProfileLink,
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
              SizedBox(height: 24),
              Text(
                context.l10n.username,
                style: WaUi.title,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                autofillHints: [AutofillHints.username],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                  LengthLimitingTextInputFormatter(30),
                ],
                style: WaUi.body,
                decoration: InputDecoration(
                  hintText: context.l10n.yourname,
                  prefixIcon: Icon(Icons.alternate_email, size: 22),
                  prefixIconColor: WaUi.secondaryText,
                  filled: true,
                  fillColor: WaUi.navBarBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: const BorderSide(color: WaUi.primaryText),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: _validateUsername,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _saveUsername(),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: WaUi.navBarBg,
                  borderRadius: BorderRadius.circular(WaUi.radiusMd),
                ),
                child: Text(
                  '${Constants.appDomain}/$previewUsername',
                  style: WaUi.bodyMedium.copyWith(color: WaUi.secondaryText),
                ),
              ),
              SizedBox(height: 12),
              Text(
                context.l10n.n330CharactersLettersNumbersUnderscoresAndHyphensOnly,
                style: WaUi.label,
              ),
              SizedBox(height: 32),
              CustomButton(
                text: context.l10n.saveUsername,
                onTap: _saveUsername,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

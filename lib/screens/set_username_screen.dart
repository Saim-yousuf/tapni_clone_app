import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class SetUsernameScreen extends StatefulWidget {
  const SetUsernameScreen({super.key});

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
      return 'Please enter a username';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 30) {
      return 'Username must be at most 30 characters';
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(username)) {
      return 'Use letters, numbers, underscores or hyphens only';
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
            'This is already your username.',
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
              ? 'Username updated successfully!'
              : response.message ?? 'Unable to update username. Try again.',
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: WaUi.primaryText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Username', style: WaUi.headline),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Choose a unique username for your profile link.',
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
              const SizedBox(height: 24),
              Text(
                'Username',
                style: WaUi.title,
              ),
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
                decoration: InputDecoration(
                  hintText: 'yourname',
                  prefixIcon: const Icon(Icons.alternate_email, size: 22),
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
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: _validateUsername,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _saveUsername(),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
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
              const SizedBox(height: 12),
              Text(
                '3–30 characters. Letters, numbers, underscores and hyphens only.',
                style: WaUi.label,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Save Username',
                onTap: _saveUsername,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

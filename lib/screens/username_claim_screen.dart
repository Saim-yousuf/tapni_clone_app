import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class UsernameClaimScreen extends StatefulWidget {
  final String username;

  const UsernameClaimScreen({super.key, required this.username});

  @override
  State<UsernameClaimScreen> createState() => _UsernameClaimScreenState();
}

class _UsernameClaimScreenState extends State<UsernameClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _emailController = TextEditingController();
  final _authRepo = AuthRepo();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateReason(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 10) {
      return context.l10n.claimReasonMinLength;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return context.l10n.pleaseEnterAValidEmailAddress;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final response = await _authRepo.submitUsernameClaim(
      username: widget.username,
      reason: _reasonController.text,
      businessEmail: _emailController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? context.l10n.claimSubmittedSuccess
              : response.message ?? context.l10n.tryAgain,
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WaUi.primaryText,
      ),
    );

    if (response.success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: WaUi.primaryText,
          onPressed: () => Navigator.of(context).pop()),
        title: Text(context.l10n.claimUsernameTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                context.l10n.claimUsernameSubtitle,
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: WaUi.fieldBox,
                child: Text(
                  '@${widget.username}',
                  style: WaUi.title.copyWith(color: WaUi.primaryText),
                ),
              ),
              const SizedBox(height: 20),
              Text(context.l10n.claimReasonHint, style: WaUi.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                style: WaUi.body,
                decoration: WaUi.fieldDecoration(
                  hintText: context.l10n.claimReasonHint,
                ),
                validator: _validateReason,
              ),
              const SizedBox(height: 16),
              Text(context.l10n.businessEmailOptional, style: WaUi.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                style: WaUi.body,
                decoration: WaUi.fieldDecoration(
                  hintText: 'name@company.com',
                  prefixIcon: const Icon(Icons.mail_outline, size: 22),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: context.l10n.submitClaim,
                isLoading: _submitting,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/quick_add_links_screen.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    Key? key,
    required this.phone,
    required this.verificationToken,
    this.country,
  }) : super(key: key);

  final String phone;
  final String verificationToken;
  final String? country;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _profileImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await pickSingleFile();
    if (picked?.file == null) return;
    setState(() => _profileImage = picked!.file);
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      authProvider.setLoading(true);

      String? profilePhotoBase64;
      if (_profileImage != null) {
        profilePhotoBase64 = await fileToBase64(_profileImage!);
      }

      final country = widget.country ??
          regionKeyFromPhone(
            widget.phone,
            regionOptions: Constants.countries,
          );
      final success = await authProvider.completePhoneSignup(
        widget.phone,
        widget.verificationToken,
        _nameController.text.trim(),
        context,
        country: country,
        profilePhoto: profilePhotoBase64,
      );
      if (!success || !mounted) return;

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
        MaterialPageRoute(
          builder: (_) => QuickAddLinksScreen(phone: widget.phone),
        ),
        (_) => false,
      );
    } finally {
      authProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AuthUi.bg,
      appBar: AppBar(
        backgroundColor: AuthUi.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AuthBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.profileInfo,
          style: AuthUi.screenTitle.copyWith(letterSpacing: 0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuthUi.horizontalPad,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.pleaseProvideNameAndPhoto,
                        textAlign: TextAlign.center,
                        style: AuthUi.body,
                      ),
                      const SizedBox(height: 36),
                      GestureDetector(
                        onTap:
                            authProvider.isLoading ? null : _pickProfilePhoto,
                        child: Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            color: AuthUi.fieldFill,
                            shape: BoxShape.circle,
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      AuthUi.iconCamera,
                                      width: 40,
                                      height: 40,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 36,
                                        color: AuthUi.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      context.l10n.addPhoto,
                                      style: AuthUi.body.copyWith(
                                        color: AuthUi.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 36),
                      AuthFieldLabel('YOUR NAME'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        style: WaUi.bodyMedium.copyWith(fontSize: 16),
                        cursorColor: AuthUi.textPrimary,
                        onFieldSubmitted: (_) => _handleContinue(),
                        decoration: InputDecoration(
                          hintText: context.l10n.typeYourNameHere,
                          hintStyle: WaUi.body.copyWith(
                            color: AuthUi.textMuted,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: AuthUi.fieldFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: AuthUi.borderFocused,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: Color(0xFFE53935),
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: Color(0xFFE53935),
                              width: 1.2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.pleaseEnterYourName;
                          }
                          if (value.trim().length < 2) {
                            return context.l10n.nameIsTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.phone,
                          style: AuthUi.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuthUi.horizontalPad,
                  8,
                  AuthUi.horizontalPad,
                  20,
                ),
                child: AuthPillButton(
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

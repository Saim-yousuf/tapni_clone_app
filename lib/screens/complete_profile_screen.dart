import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

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
          builder: (_) => const ContactsSyncScreen(isOnboarding: true),
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
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.profileInfo,
                        textAlign: TextAlign.center,
                        style: WaUi.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.pleaseProvideNameAndPhoto,
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(color: WaUi.secondaryText),
                      ),
                      const SizedBox(height: 36),
                      GestureDetector(
                        onTap: authProvider.isLoading ? null : _pickProfilePhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: WaUi.navPill,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: WaUi.promoIconFg,
                                    )
                                  : null,
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlack,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_library_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed:
                            authProvider.isLoading ? null : _pickProfilePhoto,
                        child: Text(
                          _profileImage == null
                              ? context.l10n.addPhoto
                              : context.l10n.changePhoto,
                          style: WaUi.bodyMedium.copyWith(
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        style: WaUi.bodyMedium.copyWith(fontSize: 16),
                        cursorColor: AppTheme.primaryBlack,
                        onFieldSubmitted: (_) => _handleContinue(),
                        decoration: InputDecoration(
                          hintText: context.l10n.typeYourNameHere,
                          hintStyle: WaUi.body.copyWith(
                            color: WaUi.secondaryText,
                          ),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: WaUi.divider),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: WaUi.divider),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryBlack,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
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
                          style: WaUi.caption,
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
                      disabledBackgroundColor:
                          AppTheme.primaryBlack.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(WaUi.radiusPill),
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
                            context.l10n.next,
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

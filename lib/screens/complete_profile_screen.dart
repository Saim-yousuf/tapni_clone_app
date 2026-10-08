import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/quick_add_links_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
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
  final _nameFocus = FocusNode();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
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
        AppPageRoute(
          builder: (_) => const QuickAddLinksScreen(),
        ),
        (_) => false,
      );
    } finally {
      authProvider.setLoading(false);
    }
  }

  TextStyle _text(
    AuthScale m, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AuthUi.textPrimary,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return AppFonts.textStyle(
      fontSize: m.s(size),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final m = AuthScale.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final nameFocused = _nameFocus.hasFocus;

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthAppBarTitle(
                'Profile info',
                showBack: true,
                allCaps: false,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    m.padH,
                    m.v(8),
                    m.padH,
                    m.v(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Please provide your name and an optional\nprofile photo',
                        textAlign: TextAlign.center,
                        style: _text(
                          m,
                          size: AuthUi.bodySize,
                          color: AuthUi.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: m.v(40)),
                      GestureDetector(
                        onTap:
                            authProvider.isLoading ? null : _pickProfilePhoto,
                        child: Container(
                          width: m.s(148),
                          height: m.s(148),
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
                                      width: m.s(40),
                                      height: m.s(40),
                                      color: AuthUi.textPrimary,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.photo_camera_outlined,
                                        size: m.s(36),
                                        color: AuthUi.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: m.s(10)),
                                    Text(
                                      'Add Photo',
                                      style: _text(
                                        m,
                                        size: 14,
                                        color: AuthUi.textSecondary,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: m.v(40)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'YOUR NAME',
                          style: _text(
                            m,
                            size: AuthUi.labelSize,
                            weight: FontWeight.w600,
                            color: AuthUi.textMuted,
                            letterSpacing: 0.85,
                          ),
                        ),
                      ),
                      SizedBox(height: m.v(10)),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(m.s(16)),
                          border: Border.all(
                            color: nameFocused
                                ? AuthUi.borderFocused
                                : const Color(0xFFE5E7EB),
                            width: nameFocused ? AuthUi.focusBorderWidth : 1,
                          ),
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          style: _text(m, size: 15),
                          cursorColor: AuthUi.textPrimary,
                          onFieldSubmitted: (_) => _handleContinue(),
                          onTap: () => setState(() {}),
                          onChanged: (_) {},
                          decoration: InputDecoration(
                            hintText: 'Enter your name or business name',
                            hintStyle: _text(
                              m,
                              size: 15,
                              color: const Color(0xFF6B7280),
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: m.s(16),
                              vertical: m.s(16),
                            ),
                            isDense: true,
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
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  m.padH,
                  m.v(8),
                  m.padH,
                  m.v(16) + (bottom > 0 ? 0 : m.v(8)),
                ),
                child: AuthPrimaryPillButton(
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/text_helper.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class SettingWidgets {
  static void showSettingSheet(BuildContext context) {
    _showTapniAccountBottomSheet(context);
  }
}

String _accountIdentity({
  required String phone,
  required String email,
  String? storedPhone,
  String? storedEmail,
}) {
  final p = phone.trim().isNotEmpty ? phone.trim() : (storedPhone ?? '').trim();
  if (p.isNotEmpty) return p;
  final e = email.trim().isNotEmpty ? email.trim() : (storedEmail ?? '').trim();
  if (e.isNotEmpty) return e;
  return '';
}

void _generalBottomSheet(BuildContext context) {
  final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final profile = profileProvider.profile;
  final active = authProvider.activeAccount;
  final phoneDisplay = _accountIdentity(
    phone: profile.phone,
    email: '',
    storedPhone: active?.phone,
  );
  final emailDisplay = profile.email.trim().isNotEmpty
      ? profile.email.trim()
      : (active?.email.trim() ?? '');

  final nameController = TextEditingController(text: profile.name);
  final emailController = TextEditingController(text: emailDisplay);
  final phoneBasedRegion = regionKeyFromPhone(
    phoneDisplay,
    regionOptions: Constants.countries,
  );
  String? selectedRegion;
  final saved = profile.country?.trim();
  if (saved != null &&
      saved.isNotEmpty &&
      Constants.countries.contains(saved)) {
    selectedRegion = saved;
  } else {
    selectedRegion = phoneBasedRegion;
  }
  final formKey = GlobalKey<FormState>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: WaUi.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: WaUi.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(WaUi.radiusLg),
              ),
            ),
            child: Form(
              key: formKey,
              child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WaUi.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        color: WaUi.primaryText,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/png/barqody_name.png',
                            height: 70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Text(context.l10n.general, style: WaUi.headline),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    context.l10n.manageYourPersonalDetailsOtherPreferences,
                    style: WaUi.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.personalDetails,
                          style: WaUi.sectionHeader,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          style: WaUi.body,
                          decoration: InputDecoration(
                            hintText: context.l10n.name,
                            hintStyle: WaUi.body.copyWith(
                              color: WaUi.secondaryText,
                            ),
                            fillColor: WaUi.navPill,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.l10n.pleaseEnterYourName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (phoneDisplay.isNotEmpty) ...[
                          _buildReadOnlyField(
                            context,
                            label: context.l10n.phone,
                            value: phoneDisplay,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: WaUi.body,
                          decoration: InputDecoration(
                            hintText: context.l10n.emailAddress,
                            hintStyle: WaUi.body.copyWith(
                              color: WaUi.secondaryText,
                            ),
                            fillColor: WaUi.navPill,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return null;
                            if (!email.contains('@') || !email.contains('.')) {
                              return context.l10n.pleaseEnterAValidEmailAddress;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(context.l10n.region, style: WaUi.sectionHeader),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          context: context,
                          value: selectedRegion,
                          items: Constants.countries,
                          onChanged: (val) {
                            setState(() => selectedRegion = val);
                          },
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlack,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  WaUi.radiusPill,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              final provider = Provider.of<ProfileProvider>(
                                context,
                                listen: false,
                              );

                              final response = await provider.updateProfile(
                                name: nameController.text.trim(),
                                designation: profile.designation,
                                company: profile.company,
                                bio: profile.bio,
                                phone: profile.phone.isNotEmpty
                                    ? profile.phone
                                    : phoneDisplay,
                                email: emailController.text.trim(),
                                website: profile.website,
                                links: profile.socialLinks,
                                country: selectedRegion,
                                context: context,
                              );
                              if (response.success) {
                                provider.setEditingProfile(false);
                                provider.onSaveTriggered = null;
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response.success
                                        ? context
                                            .l10n.profileUpdatedSuccessfully
                                        : response.message ??
                                            context.l10n
                                                .unableToSaveProfileTryAgain,
                                    style: WaUi.body.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppTheme.primaryBlack,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              context.l10n.save2,
                              style: WaUi.promoButton.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildReadOnlyField(
  BuildContext context, {
  required String label,
  required String value,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: WaUi.navPill,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: WaUi.caption),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: Text(value, style: WaUi.bodyMedium)),
            Text(
              context.l10n.readOnly,
              style: WaUi.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required BuildContext context,
  required String? value,
  required List<String> items,
  required void Function(String?)? onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: WaUi.navPill,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(context.l10n.selectRegion, style: WaUi.body),
        isExpanded: true,
        style: WaUi.body,
        icon: const Icon(Icons.keyboard_arrow_down, color: WaUi.secondaryText),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.capitalizeFirst(), style: WaUi.body),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

void _showTapniAccountBottomSheet(BuildContext context) {
  final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
  final active =
      Provider.of<AuthProvider>(context, listen: false).activeAccount;
  final identity = _accountIdentity(
    phone: profile.phone,
    email: profile.email,
    storedPhone: active?.phone,
    storedEmail: active?.email,
  );
  final displayName = profile.name.trim().isNotEmpty
      ? profile.name.trim()
      : (active?.name.trim().isNotEmpty == true
          ? active!.name.trim()
          : context.l10n.account);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: WaUi.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
    ),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: WaUi.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WaUi.radiusLg),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WaUi.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Image.asset('assets/images/png/barqody_name.png', height: 70),
            const SizedBox(height: 12),
            Text(context.l10n.welcomeToAccountCenter, style: WaUi.headline),
            const SizedBox(height: 6),
            Text(displayName, style: WaUi.bodyMedium),
            if (identity.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(identity, style: WaUi.caption),
            ],
            const SizedBox(height: 28),
            _buildMenuItem(Icons.person_outline, context.l10n.general, () {
              Navigator.pop(context);
              _generalBottomSheet(context);
            }),
            _buildMenuItem(Icons.security, context.l10n.security, () {}),
            _buildMenuItem(Icons.credit_card, context.l10n.billing, () {}),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(context.l10n.version101, style: WaUi.caption),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildMenuItem(IconData icon, String title, void Function()? onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        color: WaUi.navPill,
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlack),
        ),
        title: Text(title, style: WaUi.listTitle),
        trailing: const Icon(Icons.chevron_right, color: WaUi.secondaryText),
        onTap: onTap,
      ),
    ),
  );
}

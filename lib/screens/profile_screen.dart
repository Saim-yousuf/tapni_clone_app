import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/helper/launcher.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/progress_score_card.dart';
import 'package:tapni_app/screens/qr_code_sheet.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/go_bussiness_button.dart';
import 'package:tapni_app/widgets/links_widget.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/templates_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  File? profileImageFile;
  File? coverImageFile;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).profile;
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _enterEditMode(ProfileProvider profileProvider) {
    final profile = profileProvider.profile;
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    profileProvider.setEditingProfile(true);
    profileProvider.onSaveTriggered = () => _saveProfile(profileProvider);
  }

  void _saveProfile(ProfileProvider profileProvider) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final profile = profileProvider.profile;
    final response = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      designation: profile.designation,
      company: profile.company,
      bio: _bioController.text.trim(),
      phone: profile.phone,
      email: profile.email,
      website: profile.website,
      links: profile.socialLinks,
      profileImage: profileImageFile,
      coverImage: coverImageFile,
      context: context,
    );

    if (response.success) {
      profileProvider.setEditingProfile(false);
      profileProvider.onSaveTriggered = null;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'Profile updated successfully!'
              : response.message ?? 'Unable to save profile. Try again.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    final isEditing = profileProvider.isEditingProfile;

    // Maintain current save trigger in case provider changes
    if (isEditing) {
      profileProvider.onSaveTriggered = () => _saveProfile(profileProvider);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Card'),
        actions: const [
          NotificationIconButton(),
          GoBussinessButton(),
        ],
      ),
      body: SafeArea(
        child: isEditing
            ? _buildEditMode(profileProvider, profile)
            : _buildViewMode(profileProvider, profile),
      ),
    );
  }

  Widget _buildViewMode(ProfileProvider profileProvider, UserProfile profile) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Image.asset(
              'assets/images/jpg/barqody_name.jpg',
              width: 120,
              // height: 120,
            ),
            const SizedBox(height: 20),

            ProfileScoreCard(),
            // if (profile.isPro == false)
            //   GestureDetector(
            //     onTap: () {
            //       showModalBottomSheet(
            //         context: context,
            //         isScrollControlled: true,
            //         backgroundColor: Colors.transparent,
            //         builder: (context) => const ProUpgradeSheet(),
            //       );
            //     },
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 16,
            //       ),
            //       decoration: BoxDecoration(
            //         gradient: LinearGradient(
            //           colors: isDark
            //               ? [const Color(0xFF2C1E14), const Color(0xFF16100B)]
            //               : [const Color(0xFFFFF7F0), const Color(0xFFFFF0E5)],
            //           begin: Alignment.topLeft,
            //           end: Alignment.bottomRight,
            //         ),
            //         borderRadius: BorderRadius.circular(16),
            //         border: Border.all(
            //           color: isDark
            //               ? const Color(0xFF4C3625)
            //               : const Color(0xFFFFD1B3),
            //           width: 1.2,
            //         ),
            //       ),
            //       child: Row(
            //         children: [
            //           Container(
            //             padding: const EdgeInsets.all(8),
            //             decoration: BoxDecoration(
            //               color: const Color(0xFFFF9500).withOpacity(0.12),
            //               shape: BoxShape.circle,
            //             ),
            //             child: const Icon(
            //               Icons.star_rounded,
            //               color: Color(0xFFFF9500),
            //               size: 24,
            //             ),
            //           ),
            //           const SizedBox(width: 14),
            //           Expanded(
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 Text(
            //                   'Upgrade to Business PRO',
            //                   style: theme.textTheme.titleMedium?.copyWith(
            //                     fontWeight: FontWeight.w900,
            //                     fontSize: 15,
            //                     color: isDark ? Colors.white : Colors.black87,
            //                     letterSpacing: -0.2,
            //                   ),
            //                 ),
            //                 const SizedBox(height: 2),
            //                 Text(
            //                   'Customize your profile, unlock PRO templates & links, and get unlimited access premium features.',
            //                   style: TextStyle(
            //                     fontSize: 12,
            //                     color: isDark ? Colors.white60 : Colors.black54,
            //                     height: 1.3,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //           const SizedBox(width: 8),
            //           Icon(
            //             Icons.chevron_right_rounded,
            //             color: isDark ? Colors.white38 : Colors.black38,
            //             size: 20,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),

            const SizedBox(height: 20),
            _buildProfileAvatar(profile),
            const SizedBox(height: 20),
            Text(
              profile.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 30),
            _buildLinkSection(
              profile,
              isEditable: false,
              profileProvider: profileProvider,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: () => _enterEditMode(profileProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfff3f3f3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                child: const Text(
                  'Edit profile',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                SharingProfileSheet.show(context);
              },
              child: GlassCard(
                customBgColor: Colors.black.withOpacity(0.02),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.accentGold.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE CARD',
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Text(
                          //   '${profile.designation} at ${profile.company}',
                          //   style: theme.textTheme.bodyMedium?.copyWith(
                          //     color: AppTheme.textGreyLight,
                          //   ),
                          // ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 16,
                                color: AppTheme.accentGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to share QR code',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Spacer(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode(ProfileProvider profileProvider, UserProfile profile) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Username & edit pencil visual
                Row(
                  children: [
                    Text(
                      '${Constants.appDomain}/${profile.username ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Logo
            const SizedBox(height: 10),
            Center(
              child: Image.asset(
                "assets/images/jpg/barqody_name.jpg",
                // width: 100,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // Cover and Profile Stack
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Card
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: coverImageFile != null
                        ? Image.file(
                            coverImageFile!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFFF5F5F5)),
                          )
                        : profile.coverPhotoUrl != null &&
                              profile.coverPhotoUrl!.isNotEmpty
                        ? Image.network(
                            profile.coverPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFFF5F5F5)),
                          )
                        : null,
                  ),
                ),
                // Edit Cover Pencil Icon
                Positioned(
                  bottom: 55,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      if (profile.isPro == false) {
                        SubcriptionSheet.show(context);
                        return;
                      }
                      pickFile().then((file) {
                        if (file != null) {
                          setState(() {
                            coverImageFile = file.file;
                          });
                        }
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                // Overlapping Avatar
                Center(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 120),
                      child: GestureDetector(
                        onTap: () {
                          print('AVATAR TAPPED');
                          pickFile().then((file) {
                            if (file != null)
                              setState(() => profileImageFile = file.file);
                          });
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E2022),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: profileImageFile != null
                                    ? Image.file(
                                        profileImageFile!,
                                        fit: BoxFit.cover,
                                      )
                                    : profile.profilePhotoUrl != null &&
                                          profile.profilePhotoUrl!.isNotEmpty
                                    ? Image.network(
                                        profile.profilePhotoUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          profile.name.isNotEmpty
                                              ? profile.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            // Pencil icon
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15), // Wait for overlapping avatar
            // Name Field input
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                fillColor: const Color(0xFFF3F3F3),
                filled: true,
                hintText: 'Enter your name',
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name cannot be empty'
                  : null,
            ),

            const SizedBox(height: 10),

            // Bio Field input
            TextFormField(
              controller: _bioController,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                fillColor: const Color(0xFFF3F3F3),
                filled: true,
                hintText: 'Write something about you or your brand',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF3F3F3),
              ),
              child: Column(
                children: [
                  const Center(
                    child: Text(
                      'Add links to your profile below ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Links Section Grid
                  _buildLinkSection(
                    profile,
                    isEditable: true,
                    profileProvider: profileProvider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Templates Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TemplatesSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F3F3),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Templates',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(
              height: 80,
            ), // extra scrolling offset for FAB bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    bool isCover =
        (profile.coverPhotoUrl != null &&
        profile.coverPhotoUrl!.trim().isNotEmpty);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // COVER PHOTO (always check separately)
        Container(
          height: 220,
          width: double.infinity,
          color: isCover ? const Color(0xFFF5F5F5) : Colors.transparent,
          child: isCover
              ? Image.network(profile.coverPhotoUrl!, fit: BoxFit.cover)
              : null,
        ),

        // PROFILE PHOTO OR INITIAL
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: isCover ? 100 : 130,
                height: isCover ? 100 : 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // border: Border.all(color: Colors.white, width: 4),
                  color: const Color(0xFF1E2022),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ], // image: DecorationImage(
                  //   image: NetworkImage(profile.profilePhotoUrl!),
                  //   fit: BoxFit.cover,
                  // ),
                ),
                child: ClipOval(
                  child:
                      profile.profilePhotoUrl != null &&
                          profile.profilePhotoUrl!.trim().isNotEmpty
                      ? Image.network(
                          profile.profilePhotoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSection(
    UserProfile profile, {
    required bool isEditable,
    required ProfileProvider profileProvider,
  }) {
    final activeLinks = profile.socialLinks
        .where((link) => link.isActive)
        .toList();

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          ...activeLinks.map((link) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: isEditable
                      ? () => LinkSheet().showExistingLinkBottomSheet(
                          context,
                          link,
                          profileProvider,
                        )
                      : () {
                          Launcher.openLink(link, context);

                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     content: Text('Opening: ${link.fullUrl}'),
                          //     behavior: SnackBarBehavior.floating,
                          //   ),
                          // );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            link.logoUrl ?? "",
                            fit: BoxFit.contain,
                            height: 130,
                            width: 130,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.link, size: 32),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          link.platformName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isEditable)
                  Positioned(
                    top: -4,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => LinkSheet().showExistingLinkBottomSheet(
                        context,
                        link,
                        profileProvider,
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          if (isEditable)
            GestureDetector(
              onTap: () =>
                  LinkSheet().showAddLinkBottomSheet(context, profileProvider),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 70, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

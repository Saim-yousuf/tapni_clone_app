import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/links_widget.dart';
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
      body: SafeArea(
        child: isEditing
            ? _buildEditMode(profileProvider, profile)
            : _buildViewMode(profileProvider, profile),
      ),
    );
  }

  Widget _buildViewMode(ProfileProvider profileProvider, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const Text(
            'tapni',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileAvatar(profile),
          const SizedBox(height: 10),
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
          const SizedBox(height: 80),
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
          Spacer(),
          const SizedBox(height: 40),
        ],
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
                      'tapni.com/${profile.username ?? 'tltqfl43'}',
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
                // Go PRO button
                if (profile.isPro == false)
                  InkWell(
                    onTap: () {
                      SubcriptionSheet.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Go ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'BUSINESS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Logo
            const Center(
              child: Text(
                'tapni',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
            ),

            const SizedBox(height: 15),

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
                      'Drag & Drop links to reorder',
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // COVER PHOTO (always check separately)
        Container(
          height: 220,
          width: double.infinity,
          color: const Color(0xFFF5F5F5),
          child: coverImageFile != null
              ? Image.file(coverImageFile!, fit: BoxFit.cover)
              : (profile.coverPhotoUrl != null &&
                    profile.coverPhotoUrl!.trim().isNotEmpty)
              ? Image.network(profile.coverPhotoUrl!, fit: BoxFit.cover)
              : null,
        ),

        // PROFILE PHOTO OR INITIAL
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child:
              profile.profilePhotoUrl != null &&
                  profile.profilePhotoUrl!.trim().isNotEmpty
              ? Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black),
                    image: DecorationImage(
                      image: NetworkImage(profile.profilePhotoUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E2022),
                    border: Border.all(color: Colors.black),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening: ${link.fullUrl}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              link.logoUrl ?? "",
                              fit: BoxFit.contain,
                              height: 130,
                              width: 130,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.link, size: 32),
                            ),
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

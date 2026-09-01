import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/helper/launcher.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/connectivity_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/progress_score_card.dart';
import 'package:tapni_app/screens/qr_code_sheet.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/links_widget.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/connection_error_state.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/verified_name.dart';
import 'package:tapni_app/widgets/profile_empty_state.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _profileStrengthCardPrefKey = 'profile_strength_card_shown_count';
  static const _maxProfileStrengthCardShows = 2;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  File? profileImageFile;
  File? coverImageFile;
  bool _showProfileStrengthCard = false;
  bool _didResolveStrengthCard = false;
  bool _isReorderingLink = false;
  int _lastReconnectTick = 0;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);

    // Safety net if splash bootstrap hasn't started fetch yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      if (!provider.hasLoadedProfile && !provider.isLoading) {
        provider.fetchProfile();
      }
      if (provider.linkCatalog.isEmpty && !provider.isLinkCatalogLoading) {
        provider.fetchLinkCatalog();
      }
    });
  }

  void _maybeResolveStrengthCard(ProfileProvider profileProvider) {
    if (_didResolveStrengthCard || !profileProvider.hasFetchedProfile) {
      return;
    }
    _didResolveStrengthCard = true;
    _showProfileStrengthCard = _resolveProfileStrengthCardVisibility(
      profileProvider,
    );
  }

  bool _resolveProfileStrengthCardVisibility(
    ProfileProvider profileProvider,
  ) {
    if (profileProvider.score >= 100) {
      return false;
    }

    final shownCount = SharedPrefHelper.getInt(_profileStrengthCardPrefKey);
    if (shownCount >= _maxProfileStrengthCardShows) {
      return false;
    }

    final shouldShow = Random().nextDouble() < 0.4;
    if (shouldShow) {
      SharedPrefHelper.putInt(_profileStrengthCardPrefKey, shownCount + 1);
    }
    return shouldShow;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncControllersFromProfile(UserProfile profile) {
    if (_nameController.text != profile.name) {
      _nameController.text = profile.name;
    }
    if (_bioController.text != profile.bio) {
      _bioController.text = profile.bio;
    }
  }

  void _exitEditMode(ProfileProvider profileProvider) {
    final profile = profileProvider.profile;
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    profileImageFile = null;
    coverImageFile = null;
    profileProvider.setEditingProfile(false);
    profileProvider.onSaveTriggered = null;
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
              ? context.l10n.profileUpdatedSuccessfully
              : response.message ?? context.l10n.unableToSaveProfileTryAgain,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final connectivity = context.watch<ConnectivityProvider>();
    final profile = profileProvider.profile;
    final isEditing = profileProvider.isEditingProfile;
    final showShimmer = !profileProvider.hasLoadedProfile &&
        profileProvider.isLoading &&
        connectivity.isOnline;
    final showLoadError = !profileProvider.isLoading &&
        !profileProvider.hasLoadedProfile &&
        ((connectivity.initialized && connectivity.isOffline) ||
            profileProvider.hasFetchedProfile);

    if (connectivity.reconnectTick != _lastReconnectTick) {
      _lastReconnectTick = connectivity.reconnectTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = Provider.of<ProfileProvider>(context, listen: false);
        provider.fetchProfile();
        provider.fetchLinkCatalog();
      });
    }

    if (!showShimmer && !showLoadError) {
      _syncControllersFromProfile(profile);
      _maybeResolveStrengthCard(profileProvider);
    }

    // Maintain current save trigger in case provider changes
    if (isEditing) {
      profileProvider.onSaveTriggered = () => _saveProfile(profileProvider);
    }

    return PopScope(
      canPop: !isEditing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !isEditing) return;
        _exitEditMode(profileProvider);
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actionsPadding: const EdgeInsets.only(right: 8),
        title: Image.asset(
          'assets/images/png/barqody_name.png',
          height: 72,
          fit: BoxFit.contain,
        ),
        actions: [
          NotificationIconButton(),
        ],
      ),
      body: SafeArea(
        child: showShimmer
            ? const ProfileScreenShimmer()
            : showLoadError
                ? Center(
                    child: ConnectionErrorState(
                      message: context.l10n.noInternetConnection,
                      onRetry: () {
                        profileProvider.fetchProfile();
                        profileProvider.fetchLinkCatalog();
                      },
                    ),
                  )
                : isEditing
                    ? _buildEditMode(profileProvider, profile)
                    : _buildViewMode(profileProvider, profile),
      ),
    ),
    );
  }

  Widget _buildViewMode(ProfileProvider profileProvider, UserProfile profile) {
    final theme = Theme.of(context);
    final activeCard = profileProvider.activeCardDisplay;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_showProfileStrengthCard) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: ProfileScoreCard(),
            ),
            const SizedBox(height: 20),
          ],
          _buildProfileAvatar(profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: VerifiedName(
              name: profile.name,
              verified: profile.isPro,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildLinkSection(
              profile,
              isEditable: false,
              profileProvider: profileProvider,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Column(
              children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _enterEditMode(profileProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  context.l10n.editProfile2,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                SharingProfileSheet.show(context);
              },
              child: GlassCard(
                customBgColor: Colors.black.withOpacity(0.02),
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.accentGold.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(context.l10n.activeCARD,
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            activeCard.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGreyLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeCard.name,
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
                          SizedBox(height: 8),
                          Text(
                            '${activeCard.template.name} template',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 16,
                                color: AppTheme.accentGold,
                              ),
                              SizedBox(width: 6),
                              Text(
                                context.l10n.tapToShareQRCode,
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
          const SizedBox(height: 70),
        
        
        ],
      ),
    );
  }

  Widget _buildEditMode(ProfileProvider profileProvider, UserProfile profile) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: _isReorderingLink
            ? const NeverScrollableScrollPhysics()
            : null,
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
                      style: TextStyle(
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
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
                      margin: EdgeInsets.only(top: 120),
                      child: GestureDetector(
                        onTap: () {
                          print(context.l10n.avatarTAPPED);
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
                                color: Color(0xFF1E2022),
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
                                          style: TextStyle(
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
                                child: Icon(
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

            SizedBox(height: 15), // Wait for overlapping avatar
            // Name Field input
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: WaUi.fieldDecoration(
                hintText: context.l10n.enterYourName,
                radius: 16,
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.nameCannotBeEmpty
                  : null,
            ),

            SizedBox(height: 10),

            // Bio Field input
            TextFormField(
              controller: _bioController,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: WaUi.fieldDecoration(
                hintText: context.l10n.writeSomethingAboutYouOrYourBrand,
                radius: 16,
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
              ),
            ),

            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xFFF3F3F3),
              ),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          context.l10n.addLinksToYourProfileBelow2,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (profile.socialLinks.any((l) => l.isActive)) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.holdAndDragToReorderLinks,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Links Section Grid
                  _buildLinkSection(
                    profile,
                    isEditable: true,
                    profileProvider: profileProvider,
                  ),
                ],
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

  Widget _avatarInitials(UserProfile profile, bool compact) {
    final name = profile.name.trim();
    if (name.isEmpty) {
      return Center(
        child: Icon(
          Icons.person_rounded,
          size: compact ? 44 : 52,
          color: Colors.white,
        ),
      );
    }
    return Center(
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 36 : 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    final isCover =
        (profile.coverPhotoUrl != null &&
        profile.coverPhotoUrl!.trim().isNotEmpty);
    const avatarSize = 110.0;
    final avatar = Container(
      width: isCover ? avatarSize : 130,
      height: isCover ? avatarSize : 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E2022),
        border: isCover
            ? Border.all(color: Colors.white, width: 3.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: profile.profilePhotoUrl != null &&
                profile.profilePhotoUrl!.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profile.profilePhotoUrl!.trim(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, _, _) => _avatarInitials(profile, isCover),
                placeholder: (_, _) => _avatarInitials(profile, isCover),
              )
            : _avatarInitials(profile, isCover),
      ),
    );

    // No cover photo: skip the tall empty cover area to avoid white space.
    if (!isCover) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: avatar),
      );
    }

    // Full-bleed cover + WhatsApp-style avatar sitting lower over the cover edge.
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xFFF5F5F5),
                child: CachedNetworkImage(
                  imageUrl: profile.coverPhotoUrl!.trim(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Color(0xFFF5F5F5),
                  ),
                  placeholder: (_, _) => const ColoredBox(
                    color: Color(0xFFF5F5F5),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -48,
              left: 0,
              right: 0,
              child: Center(child: avatar),
            ),
          ],
        ),
        const SizedBox(height: 60),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const spacing = 12.0;
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        // Keep original ~130 look; only shrink if needed to fit 3 per row
        final iconSize = cellWidth > 130 ? 130.0 : cellWidth;
        final radius = 24.0 * (iconSize / 130.0);

        if (activeLinks.isEmpty && !isEditable) {
          return ProfileEmptyState(
            icon: Icons.apps_outlined,
            title: context.l10n.appsEmpty,
            subtitle: context.l10n.appsEmptySubtitle,
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            if (isEditable)
              SizedBox(
                width: cellWidth,
                child: Center(
                  child: GestureDetector(
                    onTap: () => LinkSheet()
                        .showAddLinkBottomSheet(context, profileProvider),
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: iconSize * 0.54,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ...activeLinks.asMap().entries.map((entry) {
              final index = entry.key;
              final link = entry.value;
              final cell = _buildLinkCell(
                link: link,
                cellWidth: cellWidth,
                iconSize: iconSize,
                radius: radius,
                isEditable: isEditable,
                profileProvider: profileProvider,
              );

              if (!isEditable) {
                return SizedBox(width: cellWidth, child: cell);
              }

              return SizedBox(
                width: cellWidth,
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (details) => details.data != index,
                  onAcceptWithDetails: (details) {
                    HapticFeedback.selectionClick();
                    profileProvider.reorderSocialLinks(details.data, index);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    return AnimatedScale(
                      scale: isDropTarget ? 0.92 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: LongPressDraggable<int>(
                        data: index,
                        delay: const Duration(milliseconds: 180),
                        hapticFeedbackOnStart: true,
                        onDragStarted: () {
                          setState(() => _isReorderingLink = true);
                        },
                        onDragEnd: (_) {
                          setState(() => _isReorderingLink = false);
                        },
                        feedback: Material(
                          color: Colors.transparent,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(radius),
                          child: SizedBox(
                            width: cellWidth,
                            child: Opacity(
                              opacity: 0.92,
                              child: _buildLinkCell(
                                link: link,
                                cellWidth: cellWidth,
                                iconSize: iconSize,
                                radius: radius,
                                isEditable: true,
                                profileProvider: profileProvider,
                                showEditBadge: false,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.28,
                          child: cell,
                        ),
                        child: cell,
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLinkCell({
    required SocialLink link,
    required double cellWidth,
    required double iconSize,
    required double radius,
    required bool isEditable,
    required ProfileProvider profileProvider,
    bool showEditBadge = true,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        GestureDetector(
          onTap: isEditable
              ? () => LinkSheet().showExistingLinkBottomSheet(
                  context,
                  link,
                  profileProvider,
                )
              : () {
                  Launcher.openLink(
                    link,
                    context,
                    isGalleryOwner: true,
                  );
                },
          child: Column(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius - 1),
                  child: LinkPlatformIcon(
                    link: link,
                    size: iconSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                link.platformName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (isEditable) ...[
                const SizedBox(height: 2),
                const Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: Colors.black38,
                ),
              ],
            ],
          ),
        ),
        if (isEditable && showEditBadge)
          Positioned(
            top: -4,
            right: (cellWidth - iconSize) / 2 - 2,
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
  }
}

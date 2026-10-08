import 'dart:io';
import 'dart:math';
import 'dart:ui' show ImageFilter;

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
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/links_widget.dart';
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
  /// 0 = sheet at rest (avatar visible), 1 = sheet fully up.
  /// ValueNotifier avoids setState rebuilds that reset DraggableScrollableSheet.
  final ValueNotifier<double> _sheetExpandProgress = ValueNotifier<double>(0);
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _sheetInitialSize = 0.6;
  double _sheetMaxSize = 0.92;

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
    _sheetExpandProgress.dispose();
    _sheetController.dispose();
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

  Future<void> _pickCoverPhoto(UserProfile profile) async {
    if (profile.isPro == false) {
      SubcriptionSheet.show(context);
      return;
    }
    final file = await pickFile();
    if (!mounted || file == null) return;
    setState(() => coverImageFile = file.file);
  }

  Future<void> _pickProfilePhoto() async {
    final file = await pickFile();
    if (!mounted || file == null) return;
    setState(() => profileImageFile = file.file);
  }

  static const _editPencilAsset = 'assets/images/png/edit-icon-1.png';

  Widget _editCircleButton({
    required VoidCallback onTap,
    double size = 40,
    double iconSize = 16,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Image.asset(
                _editPencilAsset,
                width: iconSize,
                height: iconSize,
                color: Colors.black,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.edit_outlined,
                  size: iconSize,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
        body: SafeArea(
          // Cover is edge-to-edge under status bar (view + edit match screenshot).
          top: showShimmer || showLoadError,
          child: Column(
            children: [
              if (!isEditing && (showShimmer || showLoadError))
                _buildProfileTopBar(profileProvider),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTopBar(
    ProfileProvider profileProvider, {
    bool overlayOnCover = false,
    bool showClose = false,
    VoidCallback? onClose,
  }) {
    final topInset = overlayOnCover ? MediaQuery.paddingOf(context).top : 0.0;
    const padH = 25.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padH,
        topInset + 6,
        padH - 8,
        overlayOnCover ? 0 : 4,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/png/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'BARQODY',
                style: WaUi.toolsTitleOf(
                  size: 24,
                  weight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (showClose)
              IconButton(
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: Colors.black,
                ),
              )
            else
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _enterEditMode(profileProvider);
                  } else if (value == 'share') {
                    SharingProfileSheet.show(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.l10n.editProfile2),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(context.l10n.shareCard),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 22,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _collapseProfileSheet() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      _sheetInitialSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _sheetExpandProgress.value = 0;
  }

  Widget _buildViewMode(ProfileProvider profileProvider, UserProfile profile) {
    final bio = profile.bio.trim();
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    const padH = 25.0;

    // Cover 270 at rest; after scroll 100 stays visible.
    // Missing cover uses [ProfileCoverPlaceholder] at the same size.
    const coverHeight = 270.0;
    const collapsedCoverVisible = 100.0;
    const sheetOverlapOnCover = 28.0;
    const avatarSize = 118.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        if (h <= 0) return const SizedBox.shrink();

        final coverH = min(coverHeight, h * 0.48);
        // Sheet sits on cover bottom.
        final sheetTop = coverH - sheetOverlapOnCover;
        final initial = ((h - sheetTop) / h).clamp(0.40, 0.90).toDouble();
        final minSize = initial;
        // Fully expanded: exactly 100px cover remains visible.
        final maxSize = ((h - collapsedCoverVisible) / h)
            .clamp(initial + 0.04, 0.96)
            .toDouble();
        _sheetInitialSize = initial;
        _sheetMaxSize = maxSize;

        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            final range = _sheetMaxSize - _sheetInitialSize;
            if (range <= 0) return false;
            final next = ((notification.extent - _sheetInitialSize) / range)
                .clamp(0.0, 1.0);
            if ((next - _sheetExpandProgress.value).abs() > 0.01) {
              _sheetExpandProgress.value = next;
            }
            return false;
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _sheetExpandProgress,
                builder: (_, expand, __) {
                  final t = expand.clamp(0.0, 1.0);
                  final extent = initial + t * (maxSize - initial);
                  final visibleH = t <= 0.001
                      ? coverH
                      : (h * (1.0 - extent))
                          .clamp(collapsedCoverVisible, coverH)
                          .toDouble();
                  // Keep cover visible — only light blur on scroll (no white wash).
                  final blur = t * 16.0;
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: visibleH,
                    child: _buildCoverBackdrop(
                      profile,
                      topBar: _buildProfileTopBar(
                        profileProvider,
                        overlayOnCover: true,
                        showClose: t > 0.12,
                        onClose: _collapseProfileSheet,
                      ),
                      blurSigma: blur,
                      height: visibleH,
                      expandProgress: t,
                    ),
                  );
                },
              ),
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: initial,
                minChildSize: minSize,
                maxChildSize: maxSize,
                expand: true,
                snap: true,
                snapSizes: <double>{
                  minSize,
                  initial,
                  maxSize,
                }.toList()
                  ..sort(),
                builder: (context, scrollController) {
                  return Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(BarqodyChrome.sheetRadius),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder<double>(
                        valueListenable: _sheetExpandProgress,
                        builder: (context, expand, _) {
                          final t = expand.clamp(0.0, 1.0);
                          // Sheet up → hide avatar, name, bio together.
                          final headerOpacity =
                              (1.0 - t * 1.25).clamp(0.0, 1.0);
                          final showHeader = headerOpacity > 0.02;
                          // Avatar hangs above sheet; only lower half needs space,
                          // then a tight gap before the name.
                          const avatarTopOffset = 6.0;
                          final avatarInSheet = (avatarSize / 2 - avatarTopOffset)
                              .clamp(0.0, avatarSize);
                          final headerBlockHeight = showHeader
                              ? (avatarInSheet + 8) * headerOpacity
                              : 20.0;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 15),
                                  Center(
                                    child: Container(
                                      width: 80,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1D1D6),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: headerBlockHeight),
                                  Expanded(
                                    child: ListView(
                                      controller: scrollController,
                                      // Needed so sheet can expand even when
                                      // content is shorter than the viewport.
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                        parent: ClampingScrollPhysics(),
                                      ),
                                      // Clear curved bottom nav + center FAB (~74).
                                      padding: EdgeInsets.only(
                                        bottom: 130 + bottomPad,
                                      ),
                                      children: [
                                        if (_showProfileStrengthCard) ...[
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              padH,
                                              0,
                                              padH,
                                              12,
                                            ),
                                            child: const ProfileScoreCard(),
                                          ),
                                        ],
                                        if (showHeader)
                                          Opacity(
                                            opacity: headerOpacity,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: padH,
                                              ),
                                              child: Column(
                                                children: [
                                                  VerifiedName(
                                                    name: profile.name
                                                        .toUpperCase(),
                                                    verified: profile.isPro,
                                                    badgeSize: 20,
                                                    style: WaUi.toolsTitleOf(
                                                      size: 22,
                                                      weight: FontWeight.w800,
                                                      color: Colors.black,
                                                      letterSpacing: 0.15,
                                                    ),
                                                  ),
                                                  if (bio.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      bio,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          WaUi.body.copyWith(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.35,
                                                        color: const Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        SizedBox(height: 28 * headerOpacity),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: padH,
                                          ),
                                          child: _buildLinkSection(
                                            profile,
                                            isEditable: false,
                                            profileProvider: profileProvider,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            padH,
                                            32,
                                            padH,
                                            16,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _ProfileActionPill(
                                                  label: context.l10n.shareCard,
                                                  filled: false,
                                                  onTap: () =>
                                                      SharingProfileSheet.show(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _ProfileActionPill(
                                                  label:
                                                      context.l10n.editProfile2,
                                                  filled: true,
                                                  onTap: () => _enterEditMode(
                                                    profileProvider,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (showHeader)
                                Positioned(
                                  top: -avatarSize / 2 + avatarTopOffset,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: headerOpacity,
                                      child: Center(
                                        child: _buildAvatarCircle(
                                          profile,
                                          size: avatarSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverBackdrop(
    UserProfile profile, {
    Widget? topBar,
    double blurSigma = 0,
    double expandProgress = 0,
    required double height,
  }) {
    final coverUrl = profile.coverPhotoUrl?.trim();
    final hasCoverUrl = coverUrl != null && coverUrl.isNotEmpty;

    // Fit the cover into the currently visible band only (no cut-off peek).
    final coverImage = SizedBox(
      width: double.infinity,
      height: height,
      child: hasCoverUrl
          ? ColoredBox(
              color: const Color(0xFFE8EEF2),
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                alignment: Alignment.center,
                errorWidget: (_, _, _) =>
                    const ProfileCoverPlaceholder(),
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFE8EEF2),
                ),
              ),
            )
          : ProfileCoverPlaceholder(height: height),
    );

    final t = expandProgress.clamp(0.0, 1.0);
    // Thin top gradient only (keeps BARQODY readable) — not a full white sheet.
    final topScrim = 0.18 + t * 0.22;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (blurSigma > 0.5)
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
                tileMode: TileMode.clamp,
              ),
              child: coverImage,
            )
          else
            coverImage,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 56,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: topScrim),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (topBar != null)
            Positioned(top: 0, left: 0, right: 0, child: topBar),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(UserProfile profile, {required double size}) {
    final hasPhoto = profile.profilePhotoUrl != null &&
        profile.profilePhotoUrl!.trim().isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: profile.profilePhotoUrl!.trim(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, _, _) => _avatarInitials(profile, true),
                placeholder: (_, _) => _avatarInitials(profile, true),
              )
            : ColoredBox(
                color: const Color(0xFF1E2022),
                child: _avatarInitials(profile, true),
              ),
      ),
    );
  }

  Widget _buildEditMode(ProfileProvider profileProvider, UserProfile profile) {
    final topInset = MediaQuery.paddingOf(context).top;
    // Screenshot cover ~35% of a 844pt canvas ≈ 284 (same as view mode).
    const coverHeight = 284.0;
    const avatarSize = 118.0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: _isReorderingLink
            ? const NeverScrollableScrollPhysics()
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stack height includes avatar overhang so taps on badge work.
            SizedBox(
              height: coverHeight + avatarSize / 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: coverHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _pickCoverPhoto(profile),
                      child: ColoredBox(
                        color: const Color(0xFFE8F1F8),
                        child: coverImageFile != null
                            ? Image.file(coverImageFile!, fit: BoxFit.cover)
                            : profile.coverPhotoUrl != null &&
                                    profile.coverPhotoUrl!.isNotEmpty
                                ? Image.network(
                                    profile.coverPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(
                                      color: Color(0xFFE8F1F8),
                                    ),
                                  )
                                : null,
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + 6,
                    left: 16,
                    right: 16,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleBackButton(
                              onTap: () => _exitEditMode(profileProvider),
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              context.l10n.editProfile,
                              textAlign: TextAlign.center,
                              style: WaUi.toolsTitleOf(
                                size: 20,
                                weight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.1,
                              ),
                            ),
                          ),
                          // Screenshot: pencil on cover = edit cover (save is FAB ✓).
                          _editCircleButton(
                            onTap: () => _pickCoverPhoto(profile),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: coverHeight - avatarSize / 2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _pickProfilePhoto,
                        child: SizedBox(
                          width: avatarSize,
                          height: avatarSize,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1E2022),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.10),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
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
                                              profile.profilePhotoUrl!
                                                  .isNotEmpty
                                          ? Image.network(
                                              profile.profilePhotoUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Center(
                                              child: Text(
                                                profile.name.isNotEmpty
                                                    ? profile.name[0]
                                                        .toUpperCase()
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
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.10),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        _editPencilAsset,
                                        width: 12,
                                        height: 12,
                                        color: Colors.black87,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.edit_outlined,
                                          size: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
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
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.start,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      hintText: 'Enter your name or business name',
                      hintStyle: WaUi.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.l10n.nameCannotBeEmpty
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.top,
                    maxLines: 4,
                    minLines: 3,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      hintText: 'Tell us a little about yourself',
                      hintStyle: WaUi.body.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: const Color(0xFFF5F5F5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.addLinksToYourProfileBelow2.trim(),
                          textAlign: TextAlign.center,
                          style: WaUi.body.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.holdAndDragToReorderLinks,
                          textAlign: TextAlign.center,
                          style: WaUi.caption.copyWith(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildLinkSection(
                          profile,
                          isEditable: true,
                          profileProvider: profileProvider,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
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

  Widget _buildProfileAvatar(UserProfile profile, {Widget? topBar}) {
    final isCover =
        (profile.coverPhotoUrl != null &&
        profile.coverPhotoUrl!.trim().isNotEmpty);
    // Figma cover height: 284.
    const coverHeight = 284.0;
    const avatarSize = 118.0;
    final avatar = Container(
      width: isCover ? avatarSize : 130,
      height: isCover ? avatarSize : 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
            : ColoredBox(
                color: const Color(0xFF1E2022),
                child: _avatarInitials(profile, isCover),
              ),
      ),
    );

    // No cover photo: skip the tall empty cover area to avoid white space.
    if (!isCover) {
      return Column(
        children: [
          if (topBar != null) topBar,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: avatar),
          ),
        ],
      );
    }

    // Full-bleed cover + light scrim (dark covers keep BARQODY / menu readable).
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: coverHeight,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xFFF5F5F5),
                child: CachedNetworkImage(
                  imageUrl: profile.coverPhotoUrl!.trim(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: coverHeight,
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Color(0xFFF5F5F5),
                  ),
                  placeholder: (_, _) => const ColoredBox(
                    color: Color(0xFFF5F5F5),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
              ),
            ),
            if (topBar != null)
              Positioned(top: 0, left: 0, right: 0, child: topBar),
            Positioned(
              bottom: -avatarSize / 2,
              left: 0,
              right: 0,
              child: Center(child: avatar),
            ),
          ],
        ),
        SizedBox(height: avatarSize / 2 + 14),
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
        // Screenshot: equal 3-col tiles, gap 21 / row 41, radius 16.
        const spacing = 21.0;
        const runSpacing = 41.0;
        const radius = 16.0;
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        // Fill cell so every app tile is identical size (no 112 cap).
        final iconSize = cellWidth;

        if (activeLinks.isEmpty && !isEditable) {
          return ProfileEmptyState(
            icon: Icons.apps_outlined,
            title: context.l10n.appsEmpty,
            subtitle: context.l10n.appsEmptySubtitle,
          );
        }

        // Label row height under tiles (screenshot: compact label, no drag icon).
        const labelSlotHeight = 22.0;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.start,
          children: [
            if (isEditable)
              SizedBox(
                width: cellWidth,
                child: GestureDetector(
                  onTap: () => LinkSheet()
                      .showAddLinkBottomSheet(context, profileProvider),
                  child: Column(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/png/add.png',
                            width: iconSize * 0.75,
                            height: iconSize * 0.75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.add,
                              size: iconSize * 0.72,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: labelSlotHeight),
                    ],
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
  }) {
    // Screenshot: filled logos edge-to-edge (no grey ring). Tap still edits.
    return GestureDetector(
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
      child: SizedBox(
        width: cellWidth,
        child: Column(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: LinkPlatformIcon(
                    link: link,
                    size: iconSize,
                    fit: BoxFit.cover,
                  ),
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
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill CTA matching profile Figma: equal size, stadium shape, soft shadow.
/// Height matches login Continue ([AuthUi.buttonHeight] via [AuthScale.buttonH]).
class _ProfileActionPill extends StatelessWidget {
  const _ProfileActionPill({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = AuthScale.of(context).buttonH;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(h / 2),
        child: Ink(
          height: h,
          decoration: BoxDecoration(
            color: filled ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(h / 2),
            border: filled
                ? null
                : Border.all(color: Colors.black, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: filled ? 0.18 : 0.10),
                blurRadius: filled ? 10 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: AuthScale.of(context).s(AuthUi.buttonLabelSize),
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : Colors.black,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

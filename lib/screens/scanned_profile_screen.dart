import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/helper/launcher.dart';
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/verified_name.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/repository/follow_repo.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/add_stamp_screen.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/profile_reviews_section.dart';
import 'package:tapni_app/widgets/profile_empty_state.dart';
import 'package:tapni_app/widgets/explore_detail_shimmers.dart';
import 'package:tapni_app/widgets/user_cards_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

Map<String, dynamic> _unwrapApiPayload(dynamic data) {
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }
  return {};
}

class ScannedProfileScreen extends StatefulWidget {
  final String? username;
  final String? user;
  final String? cardId;

  const ScannedProfileScreen({
    super.key,
    this.username,
    this.user,
    this.cardId,
  });

  @override
  State<ScannedProfileScreen> createState() => _ScannedProfileScreenState();
}

class _ScannedProfileScreenState extends State<ScannedProfileScreen> {
  UserProfile? _profile;
  UserCustomCard? _scannedCard;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasActivePrograms = false;
  bool _programsChecked = false;
  bool _isCustomerEnrolledInBusiness = false;
  bool _enrollmentStatusChecked = false;
  List<RewardEnrollment> _customerProgramEnrollments = [];
  bool _followBusy = false;
  final ValueNotifier<double> _sheetExpandProgress = ValueNotifier<double>(0);
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _sheetInitialSize = 0.6;
  double _sheetMaxSize = 0.92;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _checkBusinessPrograms();
  }

  @override
  void dispose() {
    _sheetExpandProgress.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  bool _isOwnProfile(UserProfile profile) {
    final me = Provider.of<ProfileProvider>(context, listen: false).profile;
    final myId = me.id?.trim();
    final theirId = profile.id?.trim();
    if (myId != null &&
        myId.isNotEmpty &&
        theirId != null &&
        theirId.isNotEmpty &&
        myId == theirId) {
      return true;
    }

    final myUsername = me.username?.trim().toLowerCase();
    final theirUsername = profile.username?.trim().toLowerCase();
    if (myUsername != null &&
        myUsername.isNotEmpty &&
        theirUsername != null &&
        theirUsername.isNotEmpty &&
        myUsername == theirUsername) {
      return true;
    }

    final argUsername = widget.username?.trim().toLowerCase();
    if (myUsername != null &&
        myUsername.isNotEmpty &&
        argUsername != null &&
        argUsername.isNotEmpty &&
        myUsername == argUsername) {
      return true;
    }

    final argUserId = widget.user?.trim();
    if (myId != null &&
        myId.isNotEmpty &&
        argUserId != null &&
        argUserId.isNotEmpty &&
        myId == argUserId) {
      return true;
    }

    return false;
  }

  void _openMyCard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  Future<void> _loadCustomerEnrollmentStatus(String customerId) async {
    final isBusinessUser = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).isProUser;
    if (!isBusinessUser) {
      if (mounted) setState(() => _enrollmentStatusChecked = true);
      return;
    }

    final res = await RewardRepo().getCustomerBusinessStatus(customerId);
    if (!mounted) return;

    var isEnrolled = false;
    var programEnrollments = <RewardEnrollment>[];

    if (res.success && res.data != null) {
      final data = _unwrapApiPayload(res.data);
      isEnrolled = data['isBusinessEnrolled'] as bool? ?? false;
      final list = data['programEnrollments'] as List? ?? [];
      programEnrollments = list
          .map((e) => RewardEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    setState(() {
      _isCustomerEnrolledInBusiness = isEnrolled;
      _customerProgramEnrollments = programEnrollments;
      _enrollmentStatusChecked = true;
    });
  }

  Future<void> _checkBusinessPrograms() async {
    final isBusinessUser = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).isProUser;
    if (!isBusinessUser) {
      if (mounted) setState(() => _programsChecked = true);
      return;
    }

    final res = await RewardRepo().getPrograms();
    if (!mounted) return;

    var hasActive = false;
    if (res.success && res.data != null) {
      final list = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      hasActive = list.any((e) {
        final map = e as Map<String, dynamic>;
        return map['isActive'] as bool? ?? true;
      });
    }

    setState(() {
      _hasActivePrograms = hasActive;
      _programsChecked = true;
    });
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = widget.username != null && widget.username!.isNotEmpty
        ? await AuthRepo().profileByUsername(
            username: widget.username!,
            isScan: true,
            cardId: widget.cardId,
          )
        : await AuthRepo().profileById(
            id: widget.user!,
            isScan: true,
            cardId: widget.cardId,
          );

    if (!mounted) return;

    if (response.success && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (userJson != null) {
        userJson['canView'] = data['canView'] ?? userJson['canView'] ?? true;
        userJson['followStatus'] =
            data['followStatus'] ?? userJson['followStatus'] ?? 'none';
        final profile = UserProfile.fromApiJson(userJson);
        UserCustomCard? scannedCard;
        if (widget.cardId != null && widget.cardId!.isNotEmpty) {
          for (final card in profile.customCards) {
            if (card.id == widget.cardId) {
              scannedCard = card;
              break;
            }
          }
        }
        final isOwn = _isOwnProfile(profile);
        setState(() {
          _profile = profile;
          _scannedCard = scannedCard;
          _isLoading = false;
          if (isOwn) {
            _programsChecked = true;
            _enrollmentStatusChecked = true;
          }
        });
        if (isOwn) return;

        if (!profile.canView) {
          setState(() {
            _programsChecked = true;
            _enrollmentStatusChecked = true;
          });
          return;
        }

        if (profile.id != null) {
          _loadCustomerEnrollmentStatus(profile.id!);
        } else {
          setState(() => _enrollmentStatusChecked = true);
        }
        // Automatically add scanned contact to the user's contact list
        if (mounted) {
          if (widget.username != null && widget.username!.isNotEmpty) {
            Provider.of<LeadsProvider>(
              context,
              listen: false,
            ).addScannedContact(widget.username!);
          }
        }
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? context.l10n.profileNotFound;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showChrome =
        !_isLoading && _errorMessage == null && _profile != null;
    final systemUi = AppTheme.systemUiFor(Theme.of(context).brightness);
    final overlayStyle = showChrome
        ? systemUi.copyWith(statusBarColor: Colors.transparent)
        : systemUi;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: !showChrome,
          child: _isLoading
              ? const ScannedProfileShimmer()
              : _errorMessage != null
                  ? Column(
                      children: [
                        _buildSimpleTopBar(),
                        Expanded(child: _buildErrorView()),
                      ],
                    )
                  : _buildProfileView(_profile!),
        ),
      ),
    );
  }

  /// Matches Contacts (`WaChatsHeader` / search) horizontal inset.
  static const double _padH = 25.0;

  Widget _buildSimpleTopBar() {
    final m = AuthScale.of(context);
    final title = (widget.username ?? context.l10n.profile).trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: 4),
      child: SizedBox(
        height: m.appBarH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuthAppBarTitle.titleStyle(m),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: AuthBackButton(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _collapseSheet() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      _sheetInitialSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _sheetExpandProgress.value = 0;
  }

  Future<void> _shareProfile(UserProfile profile) async {
    final username =
        (profile.username?.trim().isNotEmpty == true
            ? profile.username!.trim()
            : widget.username?.trim()) ??
        '';
    if (username.isEmpty) return;

    final card = _scannedCard;
    final url = card != null
        ? card.profileUrl(username)
        : '${Constants.appDomain}/$username';

    await Share.share(
      context.l10n.checkOutThisProfile(url),
      subject: context.l10n.shareProfile,
    );
  }

  PopupMenuItem<String> _menuRow({
    required String value,
    required String label,
    required Widget icon,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 22, height: 22, child: Center(child: icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _overflowMenuItems(UserProfile profile) {
    if (_isOwnProfile(profile)) return const [];

    final canUnfollow =
        profile.followStatus == 'following' && (profile.id ?? '').isNotEmpty;
    final canView = profile.canView;

    return [
      if (canView) ...[
        _menuRow(
          value: 'share_link',
          label: context.l10n.shareLink,
          icon: Image.asset(
            'assets/images/png/arrow-up-icon.png',
            width: 18,
            height: 18,
            color: Colors.black,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.ios_share_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
        _menuRow(
          value: 'exchange',
          label: context.l10n.exchangeContact,
          icon: const Icon(
            Icons.sync_alt_rounded,
            size: 20,
            color: Colors.black,
          ),
        ),
        _menuRow(
          value: 'business_card',
          label: 'Business Card',
          icon: Image.asset(
            'assets/images/png/card-icon.png',
            width: 18,
            height: 18,
            color: Colors.black,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.credit_card_outlined,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
      ],
      if (canUnfollow)
        _menuRow(
          value: 'unfollow',
          label: context.l10n.removeAccess,
          icon: const Icon(
            Icons.person_remove_outlined,
            size: 20,
            color: Colors.black,
          ),
        ),
    ];
  }

  void _onOverflowSelected(String value, UserProfile profile) {
    if (value == 'exchange') {
      _exchangeContact();
    } else if (value == 'business_card') {
      // Wait for the popup route to close — opening a sheet in the same
      // frame freezes the navigator under an already-draggable profile sheet.
      final target = profile;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        UserCardsSheet.show(context, profile: target);
      });
    } else if (value == 'share_link') {
      _shareProfile(profile);
    } else if (value == 'unfollow') {
      _cancelFollowRequest(profile);
    }
  }

  String _displayUsername(UserProfile profile) {
    final fromProfile = profile.username?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    final fromArg = widget.username?.trim();
    if (fromArg != null && fromArg.isNotEmpty) return fromArg;
    return context.l10n.profile;
  }

  Widget _buildScannedTopBar(
    UserProfile profile, {
    bool overlayOnCover = false,
    bool showClose = false,
    VoidCallback? onClose,
  }) {
    // SafeArea top is off in chrome mode so cover can go edge-to-edge;
    // always pad the bar by the status-bar inset.
    final topInset = MediaQuery.paddingOf(context).top;
    final m = AuthScale.of(context);
    final menuItems = _overflowMenuItems(profile);
    final username = _displayUsername(profile);

    Widget? trailing;
    if (showClose) {
      trailing = IconButton(
        onPressed: onClose,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: const Icon(
          Icons.close_rounded,
          size: 24,
          color: Colors.black,
        ),
      );
    } else if (menuItems.isNotEmpty) {
      trailing = PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 8),
        tooltip: context.l10n.businessOptions,
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.white,
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        onSelected: (value) => _onOverflowSelected(value, profile),
        itemBuilder: (_) => menuItems,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: Colors.black,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _padH,
        topInset + 6,
        _padH,
        overlayOnCover ? 0 : 4,
      ),
      child: SizedBox(
        height: m.appBarH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                username.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuthAppBarTitle.titleStyle(m),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: AuthBackButton(),
            ),
            if (trailing != null)
              Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFollowRequest(UserProfile profile) async {
    final userId = profile.id;
    if (userId == null || userId.isEmpty || _followBusy) return;
    setState(() => _followBusy = true);
    final res = await FollowRepo().requestFollow(userId: userId);
    if (!mounted) return;
    setState(() {
      _followBusy = false;
      if (res.success) {
        final status = (res.data is Map ? res.data['followStatus'] : null)
            ?.toString();
        _profile = profile.copyWith(followStatus: status ?? 'requested');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? context.l10n.followRequestSent
              : (res.message ?? context.l10n.couldNotSendFollowRequest),
        ),
      ),
    );
  }

  Future<void> _cancelFollowRequest(UserProfile profile) async {
    final userId = profile.id;
    if (userId == null || userId.isEmpty || _followBusy) return;
    setState(() => _followBusy = true);
    final res = await FollowRepo().unfollow(userId: userId);
    if (!mounted) return;
    if (res.success && profile.canView) {
      setState(() => _followBusy = false);
      await _fetchProfile();
      return;
    }
    setState(() {
      _followBusy = false;
      if (res.success) {
        _profile = profile.copyWith(followStatus: 'none', canView: false);
      }
    });
  }

  Widget _buildPrivateProfileView(
    UserProfile profile,
    String displayName,
    String? photoUrl,
  ) {
    final requested = profile.followStatus == 'requested';
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        _buildScannedTopBar(profile),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(_padH, 24, _padH, 24 + bottomPad),
            child: Column(
              children: [
                _buildAvatarCircle(
                  displayName: displayName,
                  photoUrl: photoUrl,
                  size: 118,
                ),
                const SizedBox(height: 16),
                VerifiedName(
                  name: displayName.toUpperCase(),
                  verified: profile.isPro,
                  badgeSize: 20,
                  style: WaUi.toolsTitleOf(
                    size: 22,
                    weight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.15,
                  ),
                ),
                if ((profile.username ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: WaUi.body.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 42,
                  color: Colors.black54,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.thisProfileIsPrivate,
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.privateProfileHint,
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                if (_followBusy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else
                  _ScannedActionPill(
                    label: requested
                        ? context.l10n.requested
                        : context.l10n.requestToView,
                    filled: !requested,
                    onTap: () {
                      if (requested) {
                        _cancelFollowRequest(profile);
                      } else {
                        _sendFollowRequest(profile);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.black38),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: _fetchProfile,
              child: Text(context.l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exchangeContact() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.exchangingContact)),
    );
    final res = await AuthRepo().exchangeContact(
      username: widget.username,
      id: widget.user,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? context.l10n.contactExchangedSuccessfully
              : (res.message ?? context.l10n.failedToExchangeContact),
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    final isOwn = _isOwnProfile(profile);
    final card = _scannedCard;
    final displayName = card?.displayName.isNotEmpty == true
        ? card!.displayName
        : profile.name;
    final displayBio = card?.bio?.isNotEmpty == true ? card!.bio! : profile.bio;
    final displayPhoto = card?.profilePhotoUrl ?? profile.profilePhotoUrl;
    final displayCover = card?.coverPhotoUrl ?? profile.coverPhotoUrl;

    if (!isOwn && !profile.canView) {
      return _buildPrivateProfileView(profile, displayName, displayPhoto);
    }

    final bio = displayBio.trim();
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    const padH = _padH;
    final coverUrl = displayCover?.trim();
    final hasCoverUrl = coverUrl != null && coverUrl.isNotEmpty;

    const coverHeight = 270.0;
    const collapsedCoverVisible = 100.0;
    const sheetOverlapOnCover = 28.0;
    const avatarSize = 118.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        if (h <= 0) return const SizedBox.shrink();

        final coverH = min(coverHeight, h * 0.48);
        final sheetTop = coverH - sheetOverlapOnCover;
        final initial = ((h - sheetTop) / h).clamp(0.40, 0.90).toDouble();
        final minSize = initial;
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
                  final blur = t * 16.0;
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: visibleH,
                    child: _buildCoverBackdrop(
                      coverUrl: hasCoverUrl ? coverUrl : null,
                      topBar: _buildScannedTopBar(
                        profile,
                        overlayOnCover: true,
                        showClose: t > 0.12,
                        onClose: _collapseSheet,
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
                snapSizes: <double>{minSize, initial, maxSize}.toList()
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
                          final headerOpacity =
                              (1.0 - t * 1.25).clamp(0.0, 1.0);
                          final showHeader = headerOpacity > 0.02;
                          const avatarTopOffset = 6.0;
                          final avatarInSheet =
                              (avatarSize / 2 - avatarTopOffset)
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
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                        parent: ClampingScrollPhysics(),
                                      ),
                                      padding: EdgeInsets.only(
                                        bottom: 32 + bottomPad,
                                      ),
                                      children: [
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
                                                    name: displayName
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
                                                  if (Constants
                                                          .reviewsEnabled &&
                                                      profile.reviewCount >
                                                          0) ...[
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Icon(
                                                          Icons.star_rounded,
                                                          size: 18,
                                                          color: Color(
                                                            0xFFF5A623,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${profile.avgRating.toStringAsFixed(1)} (${profile.reviewCount})',
                                                          style: WaUi.body
                                                              .copyWith(
                                                            fontSize: 13,
                                                            color: const Color(
                                                              0xFF6B7280,
                                                            ),
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  if (bio.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      bio,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: WaUi.body.copyWith(
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
                                            card,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            padH,
                                            32,
                                            padH,
                                            8,
                                          ),
                                          child: isOwn
                                              ? Column(
                                                  children: [
                                                    Text(
                                                      context.l10n.thisIsYou,
                                                      style:
                                                          WaUi.toolsTitleOf(
                                                        size: 16,
                                                        weight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      context.l10n
                                                          .viewingOwnProfile,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: WaUi.body.copyWith(
                                                        fontSize: 13,
                                                        color: const Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _ScannedActionPill(
                                                            label: context
                                                                .l10n
                                                                .shareCard,
                                                            filled: false,
                                                            onTap: () =>
                                                                _shareProfile(
                                                              profile,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child:
                                                              _ScannedActionPill(
                                                            label: context
                                                                .l10n
                                                                .openMyCard,
                                                            filled: true,
                                                            onTap: _openMyCard,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : _ScannedActionPill(
                                                  label: context
                                                      .l10n.exchangeContact,
                                                  filled: true,
                                                  onTap: _exchangeContact,
                                                ),
                                        ),
                                        if (Constants.reviewsEnabled &&
                                            ((profile.businessName ?? '')
                                                    .trim()
                                                    .isNotEmpty ||
                                                profile.reviewCount > 0 ||
                                                !isOwn))
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              padH,
                                              16,
                                              padH,
                                              0,
                                            ),
                                            child: ProfileReviewsSection(
                                              profile: profile,
                                              isOwnProfile: isOwn,
                                              catalogItems: profile.socialLinks
                                                  .expand(
                                                    (l) =>
                                                        l.catalogItems ??
                                                        const <CatalogItem>[],
                                                  )
                                                  .toList(),
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
                                          displayName: displayName,
                                          photoUrl: displayPhoto,
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

  Widget _buildCoverBackdrop({
    String? coverUrl,
    Widget? topBar,
    double blurSigma = 0,
    double expandProgress = 0,
    required double height,
  }) {
    final hasCoverUrl = coverUrl != null && coverUrl.trim().isNotEmpty;
    final coverImage = SizedBox(
      width: double.infinity,
      height: height,
      child: hasCoverUrl
          ? ColoredBox(
              color: const Color(0xFFE8EEF2),
              child: CachedNetworkImage(
                imageUrl: coverUrl.trim(),
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

  Widget _buildAvatarCircle({
    required String displayName,
    required String? photoUrl,
    required double size,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;
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
                imageUrl: photoUrl.trim(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, _, _) =>
                    _avatarInitials(displayName, true),
                placeholder: (_, _) => _avatarInitials(displayName, true),
              )
            : ColoredBox(
                color: const Color(0xFF1E2022),
                child: _avatarInitials(displayName, true),
              ),
      ),
    );
  }

  Widget _avatarInitials(String name, bool light) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: light ? Colors.white : Colors.black87,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinkSection(UserProfile profile, UserCustomCard? card) {
    var activeLinks = profile.socialLinks
        .where((link) => link.isActive && link.isPublic)
        .toList();

    if (card != null && card.enabledLinkIds.isNotEmpty) {
      final enabled = card.enabledLinkIds.toSet();
      activeLinks = activeLinks
          .where((l) => enabled.contains(l.id))
          .map(card.filterLinkEntries)
          .where((l) {
            if (l.value.trim().isEmpty && l.effectiveEntries.isEmpty) {
              return false;
            }
            return true;
          })
          .toList();
    }

    if (activeLinks.isEmpty) {
      return ProfileEmptyState(
        icon: Icons.apps_outlined,
        title: context.l10n.appsEmpty,
        subtitle: context.l10n.appsEmptySubtitle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const spacing = 21.0;
        const runSpacing = 41.0;
        const radius = 16.0;
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final iconSize = cellWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.start,
          children: activeLinks.map((link) {
            return SizedBox(
              width: cellWidth,
              child: GestureDetector(
                onTap: () => _openScannedLink(link, profile),
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
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius - 1),
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
                    const SizedBox(height: 6),
                    Text(
                      link.platformName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _openScannedLink(SocialLink link, UserProfile profile) async {
    final allowedEntryIds = link.hasMultipleEntries ||
            (link.entries != null && link.entries!.isNotEmpty)
        ? link.effectiveEntries.map((e) => e.id).toSet()
        : null;
    await Launcher.openLink(
      link,
      context,
      businessId: profile.id,
      businessName: profile.businessName ?? profile.name,
      businessCategory: profile.businessCategory,
      currency: profile.currency,
      galleryItems: profile.gallery,
      allowedEntryIds: allowedEntryIds,
    );
  }

  void _showRewardSheet(UserProfile customer) async {
    final repo = RewardRepo();

    final programsFuture = repo.getPrograms();
    final statusFuture = repo.getCustomerBusinessStatus(customer.id!);
    final results = await Future.wait([programsFuture, statusFuture]);

    if (!mounted) return;

    final programsRes = results[0];
    final statusRes = results[1];

    List<RewardProgram> allPrograms = [];
    var isBusinessEnrolled = _isCustomerEnrolledInBusiness;
    List<RewardEnrollment> enrollments = List.from(_customerProgramEnrollments);

    if (programsRes.success && programsRes.data != null) {
      final list = programsRes.data is List
          ? programsRes.data as List
          : (programsRes.data['data'] as List? ?? []);
      allPrograms = list
          .map((e) => RewardProgram.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();
    }

    if (statusRes.success && statusRes.data != null) {
      final data = _unwrapApiPayload(statusRes.data);
      isBusinessEnrolled = data['isBusinessEnrolled'] as bool? ?? false;
      final list = data['programEnrollments'] as List? ?? [];
      enrollments = list
          .map((e) => RewardEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final enrolledProgramIds = enrollments.map((e) => e.programId).toSet();
    final notEnrolledPrograms = allPrograms
        .where((p) => !enrolledProgramIds.contains(p.id))
        .toList();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: isBusinessEnrolled ? 0.65 : 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (_, scrollCtrl) => _RewardSheetContent(
          customer: customer,
          isBusinessEnrolled: isBusinessEnrolled,
          enrollments: enrollments,
          notEnrolledPrograms: notEnrolledPrograms,
          repo: repo,
          scrollController: scrollCtrl,
          onEnrollmentUpdated: _onEnrollmentUpdated,
        ),
      ),
    );

    if (mounted) {
      await _loadCustomerEnrollmentStatus(customer.id!);
    }
  }

  void _onEnrollmentUpdated(
    bool isEnrolled,
    List<RewardEnrollment> enrollments,
  ) {
    if (!mounted) return;
    setState(() {
      _isCustomerEnrolledInBusiness = isEnrolled;
      _customerProgramEnrollments = enrollments;
    });
  }
}

class _ScannedActionPill extends StatelessWidget {
  const _ScannedActionPill({
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

// ─── Reward Bottom Sheet ──────────────────────────────────────────────────────
class _RewardSheetContent extends StatefulWidget {
  final UserProfile customer;
  final bool isBusinessEnrolled;
  final List<RewardEnrollment> enrollments;
  final List<RewardProgram> notEnrolledPrograms;
  final RewardRepo repo;
  final ScrollController scrollController;
  final void Function(bool isEnrolled, List<RewardEnrollment> enrollments)?
  onEnrollmentUpdated;

  const _RewardSheetContent({
    required this.customer,
    required this.isBusinessEnrolled,
    required this.enrollments,
    required this.notEnrolledPrograms,
    required this.repo,
    required this.scrollController,
    this.onEnrollmentUpdated,
  });

  @override
  State<_RewardSheetContent> createState() => _RewardSheetContentState();
}

class _RewardSheetContentState extends State<_RewardSheetContent> {
  late bool _isBusinessEnrolled;
  late List<RewardEnrollment> _enrollments;
  late List<RewardProgram> _notEnrolled;
  String? _enrollingId;
  bool _isEnrollingBusiness = false;

  @override
  void initState() {
    super.initState();
    _isBusinessEnrolled = widget.isBusinessEnrolled;
    _enrollments = widget.enrollments;
    _notEnrolled = widget.notEnrolledPrograms;
  }

  Future<void> _enrollInBusiness() async {
    setState(() => _isEnrollingBusiness = true);
    final res = await widget.repo.enrollCustomerInBusiness(widget.customer.id!);
    if (!mounted) return;
    setState(() => _isEnrollingBusiness = false);

    if (res.success) {
      setState(() => _isBusinessEnrolled = true);
      widget.onEnrollmentUpdated?.call(true, _enrollments);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.customerEnrolledSuccessfully)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? context.l10n.failedToEnrollCustomer),
        ),
      );
    }
  }

  Future<void> _enrollProgram(RewardProgram program) async {
    setState(() => _enrollingId = program.id);
    final res = await widget.repo.enrollCustomer(
      program.id,
      widget.customer.id!,
    );
    if (!mounted) return;
    setState(() => _enrollingId = null);

    if (res.success && res.data != null) {
      final newEnrollment = RewardEnrollment.fromJson(
        res.data['data'] ?? res.data,
      );
      final enriched = RewardEnrollment(
        id: newEnrollment.id,
        program: program,
        programId: program.id,
        stamps: newEnrollment.stamps,
        status: newEnrollment.status,
      );
      setState(() {
        _isBusinessEnrolled = true;
        _enrollments = [..._enrollments, enriched];
        _notEnrolled = _notEnrolled.where((p) => p.id != program.id).toList();
      });
      widget.onEnrollmentUpdated?.call(true, _enrollments);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToAddProgram)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SheetHeader(
            title: context.l10n.rewardsForName(widget.customer.name),
            onBack: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  _isBusinessEnrolled
                      ? Icons.check_circle_outline
                      : Icons.card_giftcard_outlined,
                  color: _isBusinessEnrolled ? Colors.green.shade700 : null,
                ),
                const SizedBox(width: 10),
                Text(
                  _isBusinessEnrolled
                      ? context.l10n.enrolled
                      : context.l10n.notEnrolled,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isBusinessEnrolled
                        ? Colors.green.shade700
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: _isBusinessEnrolled
                  ? _buildEnrolledContent()
                  : _buildNotEnrolledContent(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotEnrolledContent() {
    return [
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.customerIsNotEnrolledYet,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              context.l10n.enrollCustomerInRewardsHint(widget.customer.name),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isEnrollingBusiness ? null : _enrollInBusiness,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isEnrollingBusiness
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.l10n.enrollCustomer),
              ),
            ),
          ],
        ),
      ),
      if (_notEnrolled.isNotEmpty) ...[
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.l10n.businessPrograms,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        ..._notEnrolled.map(
          (p) => _availableTile(p, enrollLabel: context.l10n.enroll),
        ),
      ] else
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              context.l10n.noActiveRewardProgramsAvailable,
              style: TextStyle(color: Colors.black38),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildEnrolledContent() {
    return [
      if (_enrollments.isNotEmpty) ...[
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 6),
          child: Text(
            context.l10n.assignedPrograms,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        ..._enrollments.map((e) => _enrolledTile(e)),
      ] else
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            context.l10n.noProgramsAssignedYetAddProgramsBelow,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      if (_notEnrolled.isNotEmpty) ...[
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            context.l10n.addProgram,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        ..._notEnrolled.map(
          (p) => _availableTile(p, enrollLabel: context.l10n.add),
        ),
      ],
      if (_enrollments.isEmpty && _notEnrolled.isEmpty)
        Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              context.l10n.noActiveRewardProgramsAvailable,
              style: TextStyle(color: Colors.black38),
            ),
          ),
        ),
    ];
  }

  Widget _enrolledTile(RewardEnrollment e) {
    final prog = e.program;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddStampScreen(
              enrollment: e,
              customerName: widget.customer.name,
              customerUsername: widget.customer.username,
              customerPhoto: widget.customer.profilePhotoUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: prog?.theme.cardBackgroundColor ?? Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (prog?.logo.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  prog!.logo,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            if (prog?.logo.isNotEmpty == true) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prog?.title ?? context.l10n.program,
                    style: TextStyle(
                      color: prog?.theme.cardTextColor ?? Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${e.stamps} / ${prog?.stamps ?? '?'} stamps',
                    style: TextStyle(
                      color: (prog?.theme.cardTextColor ?? Colors.white)
                          .withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (e.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else
              Icon(
                Icons.chevron_right,
                color: (prog?.theme.cardTextColor ?? Colors.white).withOpacity(
                  0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _availableTile(RewardProgram program, {required String enrollLabel}) {
    final isLoading = _enrollingId == program.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (program.logo.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                program.logo,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          if (program.logo.isNotEmpty) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${program.stamps} stamps required',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: () => _enrollProgram(program),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(72, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(enrollLabel, style: TextStyle(fontSize: 13)),
                ),
        ],
      ),
    );
  }
}

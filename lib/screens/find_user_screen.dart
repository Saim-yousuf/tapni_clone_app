import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/api_error_messages.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class PublicUserResult {
  final String id;
  final String name;
  final String username;
  final String? profilePhoto;
  final String bio;
  final String businessName;
  final bool isPublic;

  const PublicUserResult({
    required this.id,
    required this.name,
    required this.username,
    this.profilePhoto,
    this.bio = '',
    this.businessName = '',
    this.isPublic = true,
  });

  factory PublicUserResult.fromJson(Map<String, dynamic> json) {
    return PublicUserResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString(),
      bio: json['bio']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  String get subtitle {
    if (businessName.isNotEmpty) return businessName;
    if (bio.isNotEmpty) return bio;
    return '@$username';
  }
}

class FindUserScreen extends StatefulWidget {
  final bool isTab;
  const FindUserScreen({super.key, this.isTab = false});

  @override
  State<FindUserScreen> createState() => _FindUserScreenState();
}

class _FindUserScreenState extends State<FindUserScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _authRepo = AuthRepo();
  Timer? _debounce;
  List<PublicUserResult> _results = [];
  bool _isSearching = false;
  String? _errorMessage;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    final query = value.trim().replaceFirst(RegExp(r'^@'), '');

    if (query.length < 2) {
      setState(() {
        _results = [];
        _errorMessage = null;
        _isSearching = false;
        _lastQuery = query;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _lastQuery = query;
    });

    final res = await _authRepo.searchPublicUsers(query: query);
    if (!mounted || _lastQuery != query) return;

    if (!res.success) {
      setState(() {
        _isSearching = false;
        _results = [];
        _errorMessage = ApiErrorMessages.sanitize(
          res.message,
          fallback: context.l10n.searchFailedTryAgain,
        );
      });
      return;
    }

    final data = res.data;
    final usersJson = data is Map ? data['users'] as List? ?? [] : [];
    final users = usersJson
        .whereType<Map>()
        .map((e) => PublicUserResult.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.username.isNotEmpty)
        .toList();

    setState(() {
      _isSearching = false;
      _results = users;
      _errorMessage = null;
    });
  }

  void _openProfile(PublicUserResult user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannedProfileScreen(username: user.username),
      ),
    );
  }

  bool _isCurrentUser(PublicUserResult user) {
    final me = context.read<ProfileProvider>().profile;
    final myId = me.id?.trim();
    if (myId != null && myId.isNotEmpty && user.id == myId) return true;
    final myUsername = me.username?.trim().toLowerCase();
    if (myUsername != null &&
        myUsername.isNotEmpty &&
        user.username.trim().toLowerCase() == myUsername) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().replaceFirst(RegExp(r'^@'), '');

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isTab)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.findUser2,
                    style: WaUi.toolsTitleOf(
                      size: 22,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            else
              BarqodyTitleBar(
                title: context.l10n.findUser2,
                trailing: CircleAssetButton(
                  asset: 'assets/images/png/icon-morehoriz.png',
                  iconSize: 18,
                  onTap: () {},
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1, color: BarqodyChrome.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: !widget.isTab,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    final q = value.trim().replaceFirst(RegExp(r'^@'), '');
                    if (q.length >= 2) _searchUsers(q);
                  },
                  style: WaUi.body.copyWith(
                    fontSize: 16,
                    height: 1.2,
                    color: Colors.black,
                  ),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    hintText: context.l10n.searchByUsername,
                    hintStyle: WaUi.body.copyWith(
                      fontSize: 15,
                      color: BarqodyChrome.secondaryText,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Image.asset(
                        'assets/images/png/search-icon.png',
                        width: 18,
                        height: 18,
                        color: BarqodyChrome.secondaryText,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.search,
                          size: 20,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 48,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: BarqodyChrome.secondaryText,
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              _searchFocus.requestFocus();
                            },
                          )
                        : null,
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
                      horizontal: 4,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(query)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String query) {
    if (query.length < 2) {
      return _buildHint(
        iconAsset: 'assets/images/png/empty-search.png',
        fallbackIcon: Icons.person_search_outlined,
        title: context.l10n.findPeopleOnBarQody,
        subtitle: context.l10n.typeAtLeast2CharactersOfAUsernameToSearch,
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_errorMessage != null) {
      return _buildHint(
        fallbackIcon: Icons.error_outline,
        title: context.l10n.somethingWentWrong,
        subtitle: _errorMessage!,
      );
    }

    if (_results.isEmpty) {
      return _buildHint(
        fallbackIcon: Icons.search_off_rounded,
        title: context.l10n.noUsersFound,
        subtitle: context.l10n.noPublicProfileMatchesQuery(query),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        indent: 72,
        color: BarqodyChrome.divider,
      ),
      itemBuilder: (context, index) {
        final user = _results[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildHint({
    String? iconAsset,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset,
                width: 72,
                height: 72,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon,
                  size: 56,
                  color: Colors.black26,
                ),
              )
            else
              Icon(fallbackIcon, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: 17,
                weight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: 14,
                color: BarqodyChrome.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(PublicUserResult user) {
    final isMe = _isCurrentUser(user);
    return InkWell(
      onTap: () => _openProfile(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: const Color(0xFFF2F2F7),
                child: user.profilePhoto != null &&
                        user.profilePhoto!.isNotEmpty
                    ? Image.network(
                        user.profilePhoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarFallback(user),
                      )
                    : _avatarFallback(user),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name
                              : '@${user.username}',
                          style: WaUi.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!user.isPublic) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BarqodyChrome.circleBtn,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            context.l10n.you,
                            style: WaUi.label.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMe
                        ? '@${user.username} · ${context.l10n.thisIsYou}'
                        : '@${user.username}',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(PublicUserResult user) {
    final initial = user.name.isNotEmpty
        ? user.name[0].toUpperCase()
        : (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?');
    return Center(
      child: Text(
        initial,
        style: WaUi.body.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

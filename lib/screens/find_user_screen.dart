import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/theme.dart';

class PublicUserResult {
  final String id;
  final String name;
  final String username;
  final String? profilePhoto;
  final String bio;
  final String businessName;

  const PublicUserResult({
    required this.id,
    required this.name,
    required this.username,
    this.profilePhoto,
    this.bio = '',
    this.businessName = '',
  });

  factory PublicUserResult.fromJson(Map<String, dynamic> json) {
    return PublicUserResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString(),
      bio: json['bio']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
    );
  }

  String get subtitle {
    if (businessName.isNotEmpty) return businessName;
    if (bio.isNotEmpty) return bio;
    return '@$username';
  }
}

class FindUserScreen extends StatefulWidget {
  const FindUserScreen({super.key});

  @override
  State<FindUserScreen> createState() => _FindUserScreenState();
}

class _FindUserScreenState extends State<FindUserScreen> {
  final _searchController = TextEditingController();
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
        _errorMessage = res.message ?? 'Search failed. Try again.';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final query = _searchController.text.trim().replaceFirst(RegExp(r'^@'), '');

    return Scaffold(
      backgroundColor: isDark ? AppTheme.cardDarkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.cardDarkBg : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'Find User',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    final q = value.trim().replaceFirst(RegExp(r'^@'), '');
                    if (q.length >= 2) _searchUsers(q);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Only public profiles are shown',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(isDark, query)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, String query) {
    if (query.length < 2) {
      return _buildHint(
        isDark,
        icon: Icons.person_search_outlined,
        title: 'Find people on BarQody',
        subtitle: 'Type at least 2 characters of a username to search.',
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildHint(
        isDark,
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: _errorMessage!,
      );
    }

    if (_results.isEmpty) {
      return _buildHint(
        isDark,
        icon: Icons.search_off_rounded,
        title: 'No users found',
        subtitle: 'No public profile matches "@$query".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _results[index];
        return _buildUserTile(user, isDark);
      },
    );
  }

  Widget _buildHint(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(PublicUserResult user, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProfile(user),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  child: user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                      ? Image.network(
                          user.profilePhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(user, isDark),
                        )
                      : _avatarFallback(user, isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : '@${user.username}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    if (user.subtitle != '@${user.username}') ...[
                      const SizedBox(height: 2),
                      Text(
                        user.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(PublicUserResult user, bool isDark) {
    final initial = user.name.isNotEmpty
        ? user.name[0].toUpperCase()
        : (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?');
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

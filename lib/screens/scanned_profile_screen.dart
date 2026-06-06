import 'package:flutter/material.dart';
import 'package:tapni_app/helper/launcher.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/repository/auth_repo.dart';

class ScannedProfileScreen extends StatefulWidget {
  final String username;

  const ScannedProfileScreen({super.key, required this.username});

  @override
  State<ScannedProfileScreen> createState() => _ScannedProfileScreenState();
}

class _ScannedProfileScreenState extends State<ScannedProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await AuthRepo().profileByUsername(username: widget.username);

    if (!mounted) return;

    if (response.success && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (userJson != null) {
        setState(() {
          _profile = UserProfile.fromApiJson(userJson);
          _isLoading = false;
        });
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? 'Profile not found.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView()
            : _buildProfileView(_profile!),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48, color: Colors.black38),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _fetchProfile,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Image.asset(
            'assets/images/jpg/barqody_name.jpg',
            width: 120,
          ),
          const SizedBox(height: 20),
          _buildProfileAvatar(profile),
          const SizedBox(height: 20),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 30),
          Expanded(child: SingleChildScrollView(child: _buildLinkSection(profile))),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    final hasCover =
        profile.coverPhotoUrl != null && profile.coverPhotoUrl!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          color: hasCover ? const Color(0xFFF5F5F5) : Colors.transparent,
          child: hasCover
              ? Image.network(profile.coverPhotoUrl!, fit: BoxFit.cover)
              : null,
        ),
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: hasCover ? 100 : 130,
                height: hasCover ? 100 : 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2022),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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

  Widget _buildLinkSection(UserProfile profile) {
    final activeLinks = profile.socialLinks
        .where((link) => link.isActive && link.isPublic)
        .toList();

    if (activeLinks.isEmpty) {
      return const Center(
        child: Text(
          'No links available',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: activeLinks.map((link) {
          return GestureDetector(
            onTap: () => Launcher.openLink(link, context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        link.logoUrl ?? '',
                        fit: BoxFit.contain,
                        height: 130,
                        width: 130,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.link, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    link.platformName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

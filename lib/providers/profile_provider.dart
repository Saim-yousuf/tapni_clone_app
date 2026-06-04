import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/services/mock_data_service.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/api_handler.dart';

import '../widgets/loading_widget.dart';

class ProfileProvider extends ChangeNotifier {
  late UserProfile _profile;
  int _selectedTemplateIndex = 1; // Default to Charcoal

  bool _isEditingProfile = false;
  bool get isEditingProfile => _isEditingProfile;

  void setEditingProfile(bool val) {
    _isEditingProfile = val;
    notifyListeners();
  }

  VoidCallback? onSaveTriggered;

  void triggerSave() {
    if (onSaveTriggered != null) {
      onSaveTriggered!();
    }
  }

  final List<CardTemplate> templates = [
    CardTemplate(
      id: 't1',
      name: 'Violet',
      backgroundColor: const Color(0xFF7A78FF),
      textColor: Colors.white,
      labelColor: Colors.white.withOpacity(0.6),
      brandingColor: Colors.white,
      isPro: true,
      isDark: true,
    ),
    CardTemplate(
      id: 't2',
      name: 'Charcoal',
      backgroundColor: const Color(0xFF1E2022),
      textColor: Colors.white,
      labelColor: Colors.white.withOpacity(0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't3',
      name: 'Vibrant Red',
      backgroundColor: const Color(0xFFEA2C3B),
      textColor: Colors.white,
      labelColor: Colors.white.withOpacity(0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't4',
      name: 'Pure White',
      backgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF1E2022),
      labelColor: const Color(0xFF1E2022).withOpacity(0.6),
      brandingColor: const Color(0xFF1E2022),
      isPro: false,
      isDark: false,
    ),
    CardTemplate(
      id: 't5',
      name: 'Cream Beige',
      backgroundColor: const Color(0xFFF5EBE1),
      textColor: const Color(0xFF1E2022),
      labelColor: const Color(0xFF1E2022).withOpacity(0.6),
      brandingColor: const Color(0xFF1E2022),
      isPro: true,
      isDark: false,
    ),
    CardTemplate(
      id: 't6',
      name: 'Olive Green',
      backgroundColor: const Color(0xFF9EBF7B),
      textColor: Colors.white,
      labelColor: Colors.white.withOpacity(0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't7',
      name: 'Light Blue',
      backgroundColor: const Color(0xFF6BB5FF),
      textColor: Colors.white,
      labelColor: Colors.white.withOpacity(0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't8',
      name: 'Pitch Black',
      backgroundColor: const Color(0xFF000000),
      textColor: Colors.white,
      labelColor: Colors.white.withOpacity(0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
  ];

  bool _isProUser = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ProfileProvider() {
    _profile = MockDataService.getInitialProfile();
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    final repo = AuthRepo();
    final response = await repo.profile();

    if (response.success && response.data != null) {
      final data = response.data;
      try {
        if (data is Map<String, dynamic> && data.containsKey('user')) {
          _profile = UserProfile.fromApiJson(
            data['user'] as Map<String, dynamic>,
          );
        } else if (data is Map<String, dynamic>) {
          _profile = UserProfile.fromApiJson(data);
        }
      } catch (e) {
        // Fallback to mock data if there's an issue mapping
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  UserProfile get profile => _profile;
  int get selectedTemplateIndex => _selectedTemplateIndex;
  CardTemplate get currentTemplate => templates[_selectedTemplateIndex];
  bool get isProUser => _isProUser;

  void upgradeToPro() {
    _isProUser = true;
    notifyListeners();
  }

  void setTemplateIndex(int index) {
    if (index >= 0 && index < templates.length) {
      _selectedTemplateIndex = index;
      notifyListeners();
    }
  }

  Future<ApiResponse> updateProfile({
    required String name,
    required String designation,
    required String company,
    required String bio,
    required String phone,
    required String email,
    required String website,
    required List<SocialLink> links,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updatedProfile = _profile.copyWith(
      name: name,
      designation: designation,
      company: company,
      bio: bio,
      phone: phone,
      email: email,
      website: website,
      socialLinks: links,
    );

    try {
      final repo = AuthRepo();
      final response = await repo.updateProfile(
        jsonBody: updatedProfile.toApiJson(),
      );

      if (response.success) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          final profileData = data['user'] is Map<String, dynamic>
              ? data['user'] as Map<String, dynamic>
              : data;
          try {
            _profile = UserProfile.fromApiJson(profileData);
          } catch (_) {
            _profile = updatedProfile;
          }
        } else {
          _profile = updatedProfile;
        }
        notifyListeners();
      }

      return response;
    } catch (error) {
      return ApiResponse<dynamic>(
        success: false,
        statusCode: 0,
        message: error.toString(),
        data: null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> updateLinks({
    required List<SocialLink> links,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    CustomDialog.loadingDialog(context);

    final updatedProfile = _profile.copyWith(socialLinks: links);

    try {
      final repo = AuthRepo();
      final response = await repo.updateProfile(
        jsonBody: links.isEmpty
            ? {"links": []}
            : {"links": links.map((link) => link.toApiJson()).toList()},
      );

      if (response.success) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          final profileData = data['user'] is Map<String, dynamic>
              ? data['user'] as Map<String, dynamic>
              : data;
          try {
            _profile = UserProfile.fromApiJson(profileData);
          } catch (_) {
            _profile = updatedProfile;
          }
        } else {
          _profile = updatedProfile;
        }
        notifyListeners();
        Navigator.pop(context);
      }

      return response;
    } catch (error) {
      Navigator.pop(context);
      return ApiResponse<dynamic>(
        success: false,
        statusCode: 0,
        message: error.toString(),
        data: null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  addSocialLink(
    SocialPlatform platform,
    String value,
    bool showLink,
    context,
  ) async {
    final newLink = SocialLink(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platform: platform,
      value: value,
      isActive: true,
      isPublic: showLink,
    );
    final updatedLinks = List<SocialLink>.from(_profile.socialLinks)
      ..add(newLink);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    await profileProvider.updateLinks(links: updatedLinks, context: context);
    notifyListeners();
  }

  updateSocialLink(
    SocialPlatform platform,
    String value,
    bool showLink,
    context,
  ) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final existingIndex = _profile.socialLinks.indexWhere(
      (link) => link.platform == platform,
    );

    List<SocialLink> updatedLinks = List<SocialLink>.from(_profile.socialLinks);

    if (existingIndex != -1) {
      // 🔁 Update existing link
      updatedLinks[existingIndex] = SocialLink(
        id: updatedLinks[existingIndex].id,
        platform: platform,
        value: value,
        isActive: true,
        isPublic: showLink,
      );
    } else {
      // ➕ Add new link
      updatedLinks.add(
        SocialLink(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          platform: platform,
          value: value,
          isActive: true,
          isPublic: showLink,
        ),
      );
    }

    await profileProvider.updateLinks(links: updatedLinks, context: context);
    notifyListeners();
  }

  // void updateSocialLink(String id, String newValue, bool isActive) {
  //   final updatedLinks = _profile.socialLinks.map((link) {
  //     if (link.id == id) {
  //       return link.copyWith(value: newValue, isActive: isActive);
  //     }
  //     return link;
  //   }).toList();
  //   _profile = _profile.copyWith(socialLinks: updatedLinks);
  //   notifyListeners();
  // }

  void deleteSocialLink(String id) {
    final updatedLinks = _profile.socialLinks
        .where((link) => link.id != id)
        .toList();
    _profile = _profile.copyWith(socialLinks: updatedLinks);
    notifyListeners();
  }

  void toggleLinkActive(String id) {
    final updatedLinks = _profile.socialLinks.map((link) {
      if (link.id == id) {
        return link.copyWith(isActive: !link.isActive);
      }
      return link;
    }).toList();
    _profile = _profile.copyWith(socialLinks: updatedLinks);
    notifyListeners();
  }

  void incrementViews() {
    _profile = _profile.copyWith(viewsCount: _profile.viewsCount + 1);
    notifyListeners();
  }

  void incrementScans() {
    _profile = _profile.copyWith(scansCount: _profile.scansCount + 1);
    notifyListeners();
  }
}

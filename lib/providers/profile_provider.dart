import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/services/mock_data_service.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';

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

  final List<CardTemplate> templates = CardTemplateCatalog.all;

  bool _isProUser = false;
  bool _isLoading = false;
  bool _isLinkCatalogLoading = false;
  List<LinkCategory> _linkCatalog = [];

  bool get isLoading => _isLoading;
  bool get isLinkCatalogLoading => _isLinkCatalogLoading;
  List<LinkCategory> get linkCatalog => _linkCatalog;

  // ProfileProvider() {
  //   _profile = MockDataService.getInitialProfile();
  // }
  void clearData() {
    _profile = MockDataService.getInitialProfile();
    _isProUser = false;
    _linkCatalog.clear();
    _selectedTemplateIndex = 1;
    notifyListeners();
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
          _isProUser = _profile.isPro;
          _selectedTemplateIndex =
              CardTemplateCatalog.indexById(_profile.cardTemplateId);
        } else if (data is Map<String, dynamic>) {
          _profile = UserProfile.fromApiJson(data);
          _isProUser = _profile.isPro;
          _selectedTemplateIndex =
              CardTemplateCatalog.indexById(_profile.cardTemplateId);
        }
        notifyListeners();
      } catch (e) {
        // Fallback to mock data if there's an issue mapping
      }
    }
    profileScore();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchLinkCatalog() async {
    _isLinkCatalogLoading = true;
    notifyListeners();

    try {
      final repo = AuthRepo();
      final response = await repo.linkCatalog();

      if (response.success && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _linkCatalog = (data['categories'] as List<dynamic>? ?? [])
            .map((item) => LinkCategory.fromJson(item as Map<String, dynamic>))
            .where((category) => category.templates.isNotEmpty)
            .toList();
      }
    } finally {
      _isLinkCatalogLoading = false;
      notifyListeners();
    }
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

  Future<bool> saveCardTemplate(int index) async {
    if (index < 0 || index >= templates.length) return false;

    final templateId = templates[index].id;
    _selectedTemplateIndex = index;

    try {
      final repo = AuthRepo();
      final response = await repo.updateProfile(
        jsonBody: {'cardTemplateId': templateId},
      );

      if (response.success) {
        _profile = _profile.copyWith(cardTemplateId: templateId);
        notifyListeners();
        return true;
      }
    } catch (_) {}

    notifyListeners();
    return false;
  }

  Future<ApiResponse> updateProfile({
    required String name,
    required String designation,
    required String company,
    required String bio,
    required String phone,
    required String email,
    required String website,
    String? country,
    String? businessName,
    String? businessCategory,
    required List<SocialLink> links,
    File? profileImage,
    File? coverImage,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    CustomDialog.loadingDialog(context);

    final updatedProfile = _profile.copyWith(
      name: name,
      designation: designation,
      company: company,
      bio: bio,
      phone: phone,
      email: email,
      website: website,
      socialLinks: links,
      country: country,
      businessName: businessName,
      businessCategory: businessCategory,
    );

    final json = updatedProfile.toApiJson();
    if (profileImage != null) {
      final profileImageUrl = await fileToBase64(profileImage);
      json['profilePhoto'] = profileImageUrl;
    }
    if (coverImage != null) {
      log('Converting cover image to base64');
      final coverImageUrl = await fileToBase64(coverImage);
      json['coverPhoto'] = coverImageUrl;
    }

    try {
      final repo = AuthRepo();
      final response = await repo.updateProfile(jsonBody: json);

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
      Navigator.pop(context);
      profileScore();
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
        profileScore();
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

  addTemplateLink(
    LinkTemplate template,
    String value,
    bool showLink,
    context,
  ) async {
    final newLink = SocialLink(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platform: SocialPlatform.wave,
      templateId: template.id,
      customLabel: template.label,
      fieldLabel: template.fieldLabel,
      logoUrl: template.logo,
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

  addCustomTemplateLink({
    required LinkTemplate template,
    required String label,
    required String value,
    required bool showLink,
    required BuildContext context,
    String logo = '',
    Map<String, String>? bankDetails,
    Map<String, String>? contactCard,
  }) async {
    final newLink = SocialLink(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platform: SocialPlatform.wave,
      templateId: template.id,
      customLabel: label,
      fieldLabel: template.fieldLabel,
      logoUrl: logo.isNotEmpty ? logo : template.logo,
      value: value,
      bankDetails: bankDetails,
      contactCard: contactCard,
      isCustom: true,
      isActive: true,
      isPublic: showLink,
    );
    final updatedLinks = List<SocialLink>.from(_profile.socialLinks)
      ..add(newLink);
    await updateLinks(links: updatedLinks, context: context);
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

  updateTemplateLink(
    SocialLink link,
    String value,
    bool showLink,
    context,
  ) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final updatedLinks = List<SocialLink>.from(_profile.socialLinks);
    final existingIndex = updatedLinks.indexWhere((item) => item.id == link.id);

    if (existingIndex != -1) {
      updatedLinks[existingIndex] = link.copyWith(
        value: value,
        isActive: true,
        isPublic: showLink,
      );
    }

    await profileProvider.updateLinks(links: updatedLinks, context: context);
    notifyListeners();
  }

  updateCustomTemplateLink({
    required SocialLink link,
    required String label,
    required String value,
    required bool showLink,
    required BuildContext context,
    String? logo,
    Map<String, String>? bankDetails,
    Map<String, String>? contactCard,
  }) async {
    final updatedLinks = List<SocialLink>.from(_profile.socialLinks);
    final existingIndex = updatedLinks.indexWhere((item) => item.id == link.id);

    if (existingIndex != -1) {
      updatedLinks[existingIndex] = link.copyWith(
        customLabel: label,
        value: value,
        logoUrl: logo?.isNotEmpty == true ? logo : link.logoUrl,
        bankDetails: bankDetails,
        contactCard: contactCard,
        isCustom: true,
        isActive: true,
        isPublic: showLink,
      );
    }

    await updateLinks(links: updatedLinks, context: context);
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

  Future<void> deleteSocialLink(String id, BuildContext context) async {
    final updatedLinks = _profile.socialLinks
        .where((link) => link.id != id)
        .toList();
    await updateLinks(links: updatedLinks, context: context);
    profileScore();
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

  double score = 0;

  void profileScore() {
    if (profile.name.isNotEmpty) score += 12.5;
    if (profile.bio.isNotEmpty) score += 12.5;
    if (profile.profilePhotoUrl?.isNotEmpty ?? false) score += 12.5;
    if (profile.coverPhotoUrl?.isNotEmpty ?? false) score += 12.5;
    if (profile.socialLinks.length >= 3) score += 12.5;
    // if (profile.introVoiceNoteUrl?.isNotEmpty ?? false) score += 12.5;
    // if (profile.gallery.isNotEmpty) score += 12.5;
    if (profile.isPro == true) score += 12.5;
    notifyListeners();
  }
}

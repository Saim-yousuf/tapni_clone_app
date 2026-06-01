import 'package:flutter/material.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/services/mock_data_service.dart';

class ProfileProvider extends ChangeNotifier {
  late UserProfile _profile;

  ProfileProvider() {
    _profile = MockDataService.getInitialProfile();
  }

  UserProfile get profile => _profile;

  void updateProfile({
    required String name,
    required String designation,
    required String company,
    required String bio,
    required String phone,
    required String email,
    required String website,
  }) {
    _profile = _profile.copyWith(
      name: name,
      designation: designation,
      company: company,
      bio: bio,
      phone: phone,
      email: email,
      website: website,
    );
    notifyListeners();
  }

  void addSocialLink(SocialPlatform platform, String value) {
    final newLink = SocialLink(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platform: platform,
      value: value,
      isActive: true,
    );
    final updatedLinks = List<SocialLink>.from(_profile.socialLinks)..add(newLink);
    _profile = _profile.copyWith(socialLinks: updatedLinks);
    notifyListeners();
  }

  void updateSocialLink(String id, String newValue, bool isActive) {
    final updatedLinks = _profile.socialLinks.map((link) {
      if (link.id == id) {
        return link.copyWith(value: newValue, isActive: isActive);
      }
      return link;
    }).toList();
    _profile = _profile.copyWith(socialLinks: updatedLinks);
    notifyListeners();
  }

  void deleteSocialLink(String id) {
    final updatedLinks = _profile.socialLinks.where((link) => link.id != id).toList();
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

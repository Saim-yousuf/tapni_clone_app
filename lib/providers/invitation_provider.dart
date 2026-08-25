import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/l10n_lookup.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/models/published_invitation_template.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/invitation_repo.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/widgets/alert.dart';

class InvitationProvider extends ChangeNotifier {
  final InvitationRepo _repo = InvitationRepo();

  bool _isLoading = false;
  bool _isSending = false;
  bool _isPublishing = false;
  bool _loadingCommunity = false;
  List<EventInvitation> _sent = [];
  List<EventInvitation> _received = [];
  List<PublishedInvitationTemplate> _communityTemplates = [];
  EventInvitation? _selected;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isPublishing => _isPublishing;
  bool get loadingCommunity => _loadingCommunity;
  List<EventInvitation> get sent => _sent;
  List<EventInvitation> get received => _received;
  List<PublishedInvitationTemplate> get communityTemplates =>
      _communityTemplates;
  EventInvitation? get selected => _selected;

  /// Cards the user created (sent + drafts) — for home carousel.
  List<EventInvitation> get myCards => List.unmodifiable(_sent);

  void clearSendingState() {
    if (!_isSending) return;
    _isSending = false;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearData() {
    _sent = [];
    _received = [];
    _communityTemplates = [];
    _selected = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> get notificationItems {
    return _received.map((inv) {
      return {
        'type': 'event_invitation',
        'id': inv.id,
        'title': inv.title,
        'subtitle':
            '${inv.sender.displayName} · ${EventInvitation.typeLabel(inv.type)}',
        'createdAt': inv.createdAt,
        'invitation': inv,
      };
    }).toList();
  }

  Future<void> fetchReceived() async {
    setLoading(true);
    try {
      final response = await _repo.getReceived();
      if (response.success && response.data != null) {
        final data = response.data;
        final list = data is Map<String, dynamic> && data['data'] != null
            ? data['data']
            : data;
        if (list is List) {
          _received = list
              .whereType<Map<String, dynamic>>()
              .map(EventInvitation.fromJson)
              .toList();
        }
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchSent() async {
    setLoading(true);
    try {
      final response = await _repo.getSent();
      if (response.success && response.data != null) {
        final data = response.data;
        final list = data is Map<String, dynamic> && data['data'] != null
            ? data['data']
            : data;
        if (list is List) {
          _sent = list
              .whereType<Map<String, dynamic>>()
              .map(EventInvitation.fromJson)
              .toList();
        }
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchAll() async {
    setLoading(true);
    try {
      await Future.wait([fetchReceivedQuiet(), fetchSentQuiet()]);
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchReceivedQuiet() async {
    final response = await _repo.getReceived();
    if (response.success && response.data != null) {
      final data = response.data;
      final list = data is Map<String, dynamic> && data['data'] != null
          ? data['data']
          : data;
      if (list is List) {
        _received = list
            .whereType<Map<String, dynamic>>()
            .map(EventInvitation.fromJson)
            .toList();
        notifyListeners();
      }
    }
  }

  Future<void> fetchSentQuiet() async {
    final response = await _repo.getSent();
    if (response.success && response.data != null) {
      final data = response.data;
      final list = data is Map<String, dynamic> && data['data'] != null
          ? data['data']
          : data;
      if (list is List) {
        _sent = list
            .whereType<Map<String, dynamic>>()
            .map(EventInvitation.fromJson)
            .toList();
        notifyListeners();
      }
    }
  }

  Future<EventInvitation?> fetchById(String id) async {
    final response = await _repo.getById(id);
    if (response.success && response.data != null) {
      final data = response.data;
      final json = data is Map<String, dynamic> && data['data'] != null
          ? data['data']
          : data;
      if (json is Map<String, dynamic>) {
        _selected = EventInvitation.fromJson(json);
        notifyListeners();
        return _selected;
      }
    }
    return null;
  }

  Future<PhoneMatchResult?> matchPhones(List<String> phones) async {
    final response = await _repo.matchPhones(phones);
    if (response.success && response.data != null) {
      final data = response.data;
      final payload = data is Map<String, dynamic> && data['data'] != null
          ? data['data'] as Map<String, dynamic>
          : data is Map<String, dynamic>
          ? data
          : null;
      return PhoneMatchResult.fromJson(payload);
    }
    return null;
  }

  Future<EventInvitation?> sendInvitation({
    required String type,
    required String title,
    String message = '',
    String venue = '',
    String address = '',
    DateTime? eventAt,
    String themeColor = '#E85D2A',
    String? coverImageBase64,
    bool clearCoverImage = false,
    Map<String, dynamic>? design,
    List<String> recipientIds = const [],
    bool saveAsDraft = false,
    bool showFeedback = true,
    String? invitationId,
    BuildContext? context,
  }) async {
    if (!saveAsDraft && recipientIds.isEmpty) {
      if (showFeedback && context != null && context.mounted) {
        ShowAlert.error(
          message: l10nOr((l) => l.selectContactsToSendOrSaveDraft, 'Select contacts to send, or save as draft'),
          context: context,
        );
      }
      return null;
    }

    _isSending = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'type': type,
        'title': title,
        'message': message,
        'venue': venue,
        'address': address,
        'themeColor': themeColor,
        'recipientIds': recipientIds,
        'saveAsDraft': saveAsDraft,
        if (eventAt != null) 'eventAt': eventAt.toUtc().toIso8601String(),
        if (coverImageBase64 != null && coverImageBase64.isNotEmpty)
          'coverImage': coverImageBase64
        else if (clearCoverImage)
          'coverImage': '',
        if (design != null) 'design': design,
      };

      final response = invitationId != null && invitationId.isNotEmpty
          ? await _repo.updateInvitation(invitationId, body)
          : await _repo.createInvitation(body);
      if (response.success && response.data != null) {
        final data = response.data;
        final json = data is Map<String, dynamic> && data['data'] != null
            ? data['data']
            : data;
        if (json is Map<String, dynamic>) {
          final invitation = EventInvitation.fromJson(json);
          _sent.removeWhere((e) => e.id == invitation.id && e.id.isNotEmpty);
          _sent.insert(0, invitation);
          notifyListeners();
          if (showFeedback && context != null && context.mounted) {
            ShowAlert.success(
              message: saveAsDraft
                  ? 'Draft saved successfully'
                  : 'Invitation sent successfully',
              context: context,
            );
          }
          return invitation;
        }
      } else if (showFeedback && context != null && context.mounted) {
        ShowAlert.error(
          message: response.message ??
              (saveAsDraft
                  ? 'Failed to save draft'
                  : 'Failed to send invitation'),
          context: context,
        );
      }
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Add more recipients to an already-sent invitation.
  Future<EventInvitation?> addRecipients({
    required String invitationId,
    required List<String> recipientIds,
    bool showFeedback = true,
    BuildContext? context,
  }) async {
    if (invitationId.isEmpty || recipientIds.isEmpty) {
      if (showFeedback && context != null && context.mounted) {
        ShowAlert.error(
          message: l10nOr(
            (l) => l.selectContactsToSend,
            'Select contacts to send',
          ),
          context: context,
        );
      }
      return null;
    }

    _isSending = true;
    notifyListeners();
    try {
      final response = await _repo.addRecipients(invitationId, recipientIds);
      if (response.success && response.data != null) {
        final data = response.data;
        final json = data is Map<String, dynamic> && data['data'] != null
            ? data['data']
            : data;
        if (json is Map<String, dynamic>) {
          final invitation = EventInvitation.fromJson(json);
          _sent.removeWhere((e) => e.id == invitation.id && e.id.isNotEmpty);
          _sent.insert(0, invitation);
          if (_selected?.id == invitation.id) {
            _selected = invitation;
          }
          notifyListeners();
          if (showFeedback && context != null && context.mounted) {
            ShowAlert.success(
              message: l10nOr(
                (l) => l.invitationSentSuccessfully,
                'Invitation sent successfully',
              ),
              context: context,
            );
          }
          return invitation;
        }
      } else if (showFeedback && context != null && context.mounted) {
        ShowAlert.error(
          message: response.message ?? 'Failed to send invitation',
          context: context,
        );
      }
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> fetchCommunityTemplates({
    String? country,
    String? category,
  }) async {
    _loadingCommunity = true;
    notifyListeners();
    try {
      final response = await _repo.getPublicTemplates(
        country: country,
        category: category,
      );
      if (response.success && response.data != null) {
        final data = response.data;
        final list = data is Map<String, dynamic> && data['data'] != null
            ? data['data']
            : data;
        if (list is List) {
          _communityTemplates = list
              .whereType<Map<String, dynamic>>()
              .map(PublishedInvitationTemplate.fromJson)
              .toList();
        }
      }
    } finally {
      _loadingCommunity = false;
      notifyListeners();
    }
  }

  Future<PublishedInvitationTemplate?> publishTemplate({
    required String name,
    required InvitationDesign design,
    String description = '',
    BuildContext? context,
  }) async {
    _isPublishing = true;
    notifyListeners();
    try {
      // Community templates publish under the user's country, not the starter template's.
      var countryCode = design.countryCode;
      if (context != null && context.mounted) {
        try {
          final profile =
              Provider.of<ProfileProvider>(context, listen: false).profile;
          countryCode = resolveUserPublishCountryCode(
            profileCountry: profile.country,
            phone: profile.phone,
            fallback: design.countryCode,
          );
        } catch (_) {}
      }

      final publishDesign = design.copy()..countryCode = countryCode;
      final body = <String, dynamic>{
        'name': name,
        'description': description,
        'countryCode': countryCode,
        'category': publishDesign.category,
        'locale': publishDesign.locale,
        'rtl': publishDesign.rtl,
        'previewColor': publishDesign.backgroundColor,
        'accentColor': '#D4AF37',
        'design': publishDesign.toJson(),
      };
      final response = await _repo.publishTemplate(body);
      if (response.success && response.data != null) {
        final data = response.data;
        final json = data is Map<String, dynamic> && data['data'] != null
            ? data['data']
            : data;
        if (json is Map<String, dynamic>) {
          final published = PublishedInvitationTemplate.fromJson(json);
          _communityTemplates.insert(0, published);
          notifyListeners();
          if (context != null && context.mounted) {
            ShowAlert.success(
              message: l10nOr((l) => l.templatePublishedOthersCanUse, 'Template published! Others can use it now.'),
              context: context,
            );
          }
          return published;
        }
      } else if (context != null && context.mounted) {
        ShowAlert.error(
          message: response.message ?? 'Failed to publish template',
          context: context,
        );
      }
      return null;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  Future<InvitationDesign?> useCommunityTemplate(
    String id, {
    BuildContext? context,
  }) async {
    final response = await _repo.useTemplate(id);
    if (response.success && response.data != null) {
      final data = response.data;
      final json = data is Map<String, dynamic> && data['data'] != null
          ? data['data']
          : data;
      if (json is Map<String, dynamic>) {
        final published = PublishedInvitationTemplate.fromJson(json);
        return published.designCopy();
      }
    } else if (context != null && context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Could not load template',
        context: context,
      );
    }
    return null;
  }
}

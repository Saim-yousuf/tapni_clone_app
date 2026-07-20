import 'package:flutter/material.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/repository/invitation_repo.dart';
import 'package:tapni_app/widgets/alert.dart';

class InvitationProvider extends ChangeNotifier {
  final InvitationRepo _repo = InvitationRepo();

  bool _isLoading = false;
  bool _isSending = false;
  List<EventInvitation> _sent = [];
  List<EventInvitation> _received = [];
  EventInvitation? _selected;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  List<EventInvitation> get sent => _sent;
  List<EventInvitation> get received => _received;
  EventInvitation? get selected => _selected;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearData() {
    _sent = [];
    _received = [];
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
    List<String> recipientIds = const [],
    bool saveAsDraft = false,
    bool showFeedback = true,
    String? invitationId,
    BuildContext? context,
  }) async {
    if (!saveAsDraft && recipientIds.isEmpty) {
      if (showFeedback && context != null && context.mounted) {
        ShowAlert.error(
          message: 'Select contacts to send, or save as draft',
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
}
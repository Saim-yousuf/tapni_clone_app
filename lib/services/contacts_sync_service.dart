import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapni_app/repository/directory_repo.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/preference_helper.dart';

class ContactsSyncResult {
  final bool success;
  final int uploaded;
  final String? message;

  const ContactsSyncResult({
    required this.success,
    this.uploaded = 0,
    this.message,
  });
}

class ContactsSyncService {
  ContactsSyncService._();

  /// Temporary kill switch. Set true to bring contacts sync back.
  static const bool isFeatureEnabled = false;

  static const int chunkSize = 500;
  static final DirectoryRepo _repo = DirectoryRepo();

  static String _promptKey(String userId) =>
      '${SharedPrefHelper.utils.contactsSyncPromptedPrefix}$userId';

  static bool wasPrompted(String userId) {
    if (userId.isEmpty) return false;
    return SharedPrefHelper.getBool(_promptKey(userId));
  }

  static Future<void> markPrompted(String userId) async {
    if (userId.isEmpty) return;
    await SharedPrefHelper.putBool(_promptKey(userId), true);
  }

  static Future<PermissionStatus> requestPermission() {
    return Permission.contacts.request();
  }

  static Future<List<Map<String, dynamic>>> readDeviceContacts() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final byPhone = <String, Map<String, dynamic>>{};

    for (final contact in contacts) {
      final name = contact.displayName.trim();
      if (name.isEmpty) continue;

      final email = contact.emails.isNotEmpty
          ? contact.emails.first.address.trim()
          : '';
      final company = contact.organizations.isNotEmpty
          ? contact.organizations.first.company.trim()
          : '';

      for (final phone in contact.phones) {
        final normalized = PhoneUtils.normalize(phone.number);
        if (!PhoneUtils.isValid(normalized)) continue;
        byPhone.putIfAbsent(normalized, () {
          final payload = <String, dynamic>{
            'name': name,
            'phone': normalized,
          };
          if (email.isNotEmpty) payload['email'] = email;
          if (company.isNotEmpty) payload['company'] = company;
          return payload;
        });
      }
    }

    return byPhone.values.toList();
  }

  static Future<ContactsSyncResult> syncAll({
    void Function(int done, int total)? onProgress,
  }) async {
    if (!isFeatureEnabled) {
      return const ContactsSyncResult(success: true, uploaded: 0);
    }
    final contacts = await readDeviceContacts();
    if (contacts.isEmpty) {
      return const ContactsSyncResult(success: true, uploaded: 0);
    }

    var uploaded = 0;
    for (var i = 0; i < contacts.length; i += chunkSize) {
      final end = (i + chunkSize > contacts.length)
          ? contacts.length
          : i + chunkSize;
      final chunk = contacts.sublist(i, end);
      final res = await _repo.syncContacts(chunk);
      if (!res.success) {
        return ContactsSyncResult(
          success: false,
          uploaded: uploaded,
          message: res.message ?? 'Failed to sync contacts',
        );
      }
      final data = res.data is Map ? res.data['data'] : null;
      if (data is Map && data['accepted'] is num) {
        uploaded += (data['accepted'] as num).toInt();
      } else {
        uploaded += chunk.length;
      }
      onProgress?.call(end, contacts.length);
    }

    return ContactsSyncResult(success: true, uploaded: uploaded);
  }
}

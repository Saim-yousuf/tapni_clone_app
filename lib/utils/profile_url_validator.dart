import 'package:tapni_app/utils/constant.dart';

class ProfileScanResult {
  final String username;
  final String? cardId;

  const ProfileScanResult({required this.username, this.cardId});
}

class ProfileUrlValidator {
  static ProfileScanResult? parse(String scannedValue) {
    final username = extractUsername(scannedValue);
    if (username == null) return null;

    final trimmed = scannedValue.trim();
    Uri uri;
    try {
      uri = trimmed.contains('://')
          ? Uri.parse(trimmed)
          : Uri.parse('https://$trimmed');
    } catch (_) {
      return null;
    }

    final cardId = uri.queryParameters['card']?.trim();
    return ProfileScanResult(
      username: username,
      cardId: cardId != null && cardId.isNotEmpty ? cardId : null,
    );
  }

  static String? extractUsername(String scannedValue) {
    final trimmed = scannedValue.trim();
    if (trimmed.isEmpty) return null;

    Uri uri;
    try {
      uri = trimmed.contains('://')
          ? Uri.parse(trimmed)
          : Uri.parse('https://$trimmed');
    } catch (_) {
      return null;
    }

    final expectedHost = Uri.parse(Constants.appDomain).host;
    final scannedHost = uri.host.replaceFirst(RegExp(r'^www\.'), '');

    if (scannedHost != expectedHost) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) return null;

    final username = segments.first;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(username)) return null;

    return username;
  }

  static bool isValidProfileUrl(String scannedValue) {
    return extractUsername(scannedValue) != null;
  }
}

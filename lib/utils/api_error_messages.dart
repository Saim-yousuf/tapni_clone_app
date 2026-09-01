import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tapni_app/l10n/l10n_lookup.dart';

/// User-facing API / network error text — never raw SocketException dumps.
class ApiErrorMessages {
  ApiErrorMessages._();

  static bool isNetworkIssue({Object? error, String? message}) {
    if (error != null && _errorLooksLikeNetwork(error)) return true;
    if (message != null && _textLooksLikeNetwork(message)) return true;
    return false;
  }

  static bool _errorLooksLikeNetwork(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is TlsException;
  }

  static bool _textLooksLikeNetwork(String text) {
    final lower = text.toLowerCase();
    const needles = [
      'socketexception',
      'clientexception',
      'failed host lookup',
      'no route to host',
      'network is unreachable',
      'connection refused',
      'connection timed out',
      'connection reset',
      'errno =',
      'request failed:',
      'no address associated with hostname',
      'software caused connection abort',
    ];
    return needles.any(lower.contains);
  }

  static String forException(Object error) {
    if (_errorLooksLikeNetwork(error)) {
      return l10nOr((l) => l.noInternetConnection, 'No internet connection');
    }
    return l10nOr((l) => l.somethingWentWrong, 'Something went wrong');
  }

  /// Cleans [message] from [ApiResponse] before showing in UI.
  static String sanitize(String? message, {String? fallback}) {
    final generic = fallback ??
        l10nOr((l) => l.somethingWentWrong, 'Something went wrong');
    if (message == null || message.trim().isEmpty) return generic;
    if (_textLooksLikeNetwork(message)) {
      return l10nOr((l) => l.noInternetConnection, 'No internet connection');
    }
    return message;
  }

  static String? networkSubtitle() {
    return l10nOr(
      (l) => l.pleaseCheckYourConnection,
      'Please check your connection',
    );
  }
}

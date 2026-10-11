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
      'no address associated with hostname',
      'software caused connection abort',
      'no internet',
      'network_error',
    ];
    return needles.any(lower.contains);
  }

  /// True offline / DNS / unreachable — not every ClientException.
  static bool _looksLikeNoInternet(Object error) {
    if (error is SocketException) {
      final msg = (error.message).toLowerCase();
      // Backend down on LAN is not "no internet".
      if (msg.contains('connection refused')) return false;
      return true;
    }
    if (error is TimeoutException) return true;
    if (error is HandshakeException || error is TlsException) return false;
    if (error is http.ClientException) {
      final msg = error.message.toLowerCase();
      return msg.contains('failed host lookup') ||
          msg.contains('network is unreachable') ||
          msg.contains('no address associated') ||
          msg.contains('failed to connect');
    }
    return false;
  }

  static const _serverUnreachable =
      'Unable to reach server. Please try again.';

  static String forException(Object error) {
    if (_looksLikeNoInternet(error)) {
      return l10nOr((l) => l.noInternetConnection, 'No internet connection');
    }
    if (_errorLooksLikeNetwork(error)) {
      // Prefer a clear reachability message over generic "Something went wrong".
      return _serverUnreachable;
    }
    return l10nOr((l) => l.somethingWentWrong, 'Something went wrong');
  }

  /// Cleans [message] from [ApiResponse] before showing in UI.
  static String sanitize(String? message, {String? fallback}) {
    final generic = fallback ??
        l10nOr((l) => l.somethingWentWrong, 'Something went wrong');
    if (message == null || message.trim().isEmpty) return generic;
    final lower = message.toLowerCase();
    // Don't rewrite real API errors that merely mention "connection".
    if (lower.contains('connection refused') ||
        lower.contains('failed to connect') ||
        lower.contains('unable to reach server')) {
      return _serverUnreachable;
    }
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

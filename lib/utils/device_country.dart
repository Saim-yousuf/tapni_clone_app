import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tapni_app/utils/country_dial_codes.dart';

/// Resolves the best default dial-country:
/// SIM → network → IP geo → device locale → product fallback (`+92`).
///
/// Emulators fake a US SIM / en_US locale — those are skipped; IP geo still
/// runs so a real network location (e.g. PK) can win.
class DeviceCountry {
  DeviceCountry._();

  static const _channel = MethodChannel('barqody/device_country');
  static const _geoTimeout = Duration(seconds: 3);

  /// First-frame default. [detect] refines with SIM / IP / locale.
  static CountryDialCode syncDefault() => defaultCountryDialCodeFallback;

  /// Full cascade. Never throws — always returns a usable country.
  static Future<CountryDialCode> detect() async {
    final emulator = await _isEmulator();

    if (!emulator) {
      final fromNative = findCountryByIso(await _nativeIso());
      if (fromNative != null) return fromNative;
    }

    final fromGeo = findCountryByIso(await _geoIpIso());
    if (fromGeo != null) return fromGeo;

    if (!emulator) {
      final fromLocale = findCountryByIso(_localeIso());
      if (fromLocale != null) return fromLocale;
    }

    return defaultCountryDialCodeFallback;
  }

  static String? _localeIso() {
    final iso = PlatformDispatcher.instance.locale.countryCode;
    if (iso == null || iso.trim().length != 2) return null;
    return iso.trim().toUpperCase();
  }

  /// Android: SIM ISO, then network ISO. iOS / others: null → geo / locale.
  static Future<String?> _nativeIso() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    try {
      final raw = await _channel.invokeMethod<String>('getCountryIso');
      final iso = raw?.trim().toUpperCase();
      if (iso == null || iso.length != 2) return null;
      return iso;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Soft IP geolocation — short timeout, silent failure.
  static Future<String?> _geoIpIso() async {
    // Prefer lightweight country-only endpoints (HTTPS, no API key).
    final endpoints = <Uri>[
      Uri.parse('https://api.country.is/'),
      Uri.parse('https://ipapi.co/json/'),
    ];

    for (final uri in endpoints) {
      try {
        final response = await http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(_geoTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) continue;

        final body = response.body.trim();
        if (body.isEmpty) continue;

        final decoded = jsonDecode(body);
        if (decoded is! Map) continue;

        final map = Map<String, dynamic>.from(decoded);
        final iso = (map['country'] ??
                map['country_code'] ??
                map['countryCode'])
            ?.toString()
            .trim()
            .toUpperCase();
        if (iso != null && iso.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(iso)) {
          return iso;
        }
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Future<bool> _isEmulator() async {
    if (kIsWeb) return false;
    try {
      final plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return !info.isPhysicalDevice;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        return !info.isPhysicalDevice;
      }
    } catch (_) {}
    return false;
  }
}

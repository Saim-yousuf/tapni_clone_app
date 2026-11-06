import 'dart:convert';

import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/utils/preference_helper.dart';

/// Persists admin link-catalog locally so profile icons resolve on cold start
/// without waiting for the network catalog fetch.
class LinkCatalogCache {
  static const _prefsKey = 'link_catalog_cache_v1';

  static List<LinkCategory> loadSync() {
    final raw = SharedPrefHelper.getString(_prefsKey);
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => LinkCategory.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.templates.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<LinkCategory> catalog) async {
    if (catalog.isEmpty) return;
    await SharedPrefHelper.getInstance();
    final encoded = jsonEncode(catalog.map((c) => c.toJson()).toList());
    await SharedPrefHelper.putString(_prefsKey, encoded);
  }

  static Future<void> clear() async {
    await SharedPrefHelper.getInstance();
    await SharedPrefHelper.remove(_prefsKey);
  }
}

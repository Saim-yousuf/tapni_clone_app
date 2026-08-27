import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/utils/preference_helper.dart';

/// Persists multi-entry link data locally so names/photos survive when the API
/// omits `entries` on profile read/write responses.
class LinkEntriesCache {
  static String _prefsKey(String userId) => 'link_entries_cache_$userId';

  static String _itemKey(String cacheKey) => 'link_entries_item_$cacheKey';

  static String cacheKeyFor(SocialLink link) {
    if (link.templateId != null && link.templateId!.trim().isNotEmpty) {
      return 'tpl:${link.templateId}';
    }
    if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(link.id)) {
      return 'id:${link.id}';
    }
    return 'label:${link.platformName.trim().toLowerCase()}';
  }

  static Future<void> save(String userId, List<SocialLink> links) async {
    await SharedPrefHelper.getInstance();
    final map = <String, dynamic>{};
    for (final link in links) {
      final entries = link.entries;
      if (entries == null || entries.isEmpty) continue;
      final encoded = entries.map((e) => e.toJson()).toList();
      final key = cacheKeyFor(link);
      map[key] = encoded;
      // Per-link key — works even when userId is missing.
      await SharedPrefHelper.putObject(_itemKey(key), {'entries': encoded});
      await SharedPrefHelper.putObject(
        _itemKey('label:${link.platformName.trim().toLowerCase()}'),
        {'entries': encoded},
      );
    }
    if (userId.trim().isNotEmpty) {
      await SharedPrefHelper.putObject(_prefsKey(userId), map);
    }
  }

  static List<LinkEntry>? _readItem(String key) {
    final raw = SharedPrefHelper.getObject(_itemKey(key));
    final list = raw?['entries'];
    if (list is! List || list.isEmpty) return null;
    final restored = list
        .whereType<Map>()
        .map((e) => LinkEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.value.trim().isNotEmpty)
        .toList();
    return restored.isEmpty ? null : restored;
  }

  static Future<List<SocialLink>> apply(
    String userId,
    List<SocialLink> links,
  ) async {
    if (links.isEmpty) return links;
    await SharedPrefHelper.getInstance();
    final raw = userId.trim().isEmpty
        ? null
        : SharedPrefHelper.getObject(_prefsKey(userId));

    return links.map((link) {
      final remoteEntries = link.entries;
      final hasRemoteMulti = remoteEntries != null &&
          remoteEntries.where((e) => e.value.trim().isNotEmpty).length > 1;
      final hasRemoteNamed = remoteEntries != null &&
          remoteEntries.any((e) => e.name.trim().isNotEmpty);
      if (hasRemoteMulti || hasRemoteNamed) return link;

      List<LinkEntry>? restored = _readItem(cacheKeyFor(link)) ??
          _readItem('label:${link.platformName.trim().toLowerCase()}');

      if (restored == null && raw != null) {
        final cached = raw[cacheKeyFor(link)] ??
            raw['label:${link.platformName.trim().toLowerCase()}'];
        if (cached is List && cached.isNotEmpty) {
          restored = cached
              .whereType<Map>()
              .map((e) => LinkEntry.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.value.trim().isNotEmpty)
              .toList();
          if (restored!.isEmpty) restored = null;
        }
      }

      if (restored == null || restored.isEmpty) return link;
      return link.copyWith(entries: restored, value: restored.first.value);
    }).toList();
  }

  /// Resolve one link's entries for open/edit.
  static Future<SocialLink> resolve(SocialLink link, {String userId = ''}) async {
    final list = await apply(userId, [link]);
    return list.first;
  }
}

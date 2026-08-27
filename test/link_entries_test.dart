import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/helper/link_entries_cache.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LinkEntry + multi-entry SocialLink', () {
    test('toApiJson includes entries with names', () {
      final link = SocialLink(
        id: '1',
        platform: SocialPlatform.whatsApp,
        customLabel: 'Whatsapp',
        fieldType: 'phone',
        value: '03362402187',
        entries: const [
          LinkEntry(id: 'a', name: 'Saim', value: '03362402187'),
          LinkEntry(id: 'b', name: 'Dev', value: '03092335909'),
        ],
      );

      final json = link.toApiJson();
      expect(json['entries'], isA<List>());
      expect((json['entries'] as List).length, 2);
      expect((json['entries'] as List).first['name'], 'Saim');
      expect(link.hasMultipleEntries, isTrue);
      expect(link.effectiveEntries.length, 2);
    });

    test('fromApiJson restores entries', () {
      final link = SocialLink.fromApiJson({
        '_id': '507f1f77bcf86cd799439011',
        'title': 'Whatsapp',
        'type': 'phone',
        'value': '03362402187',
        'entries': [
          {'id': 'a', 'name': 'Saim', 'value': '03362402187'},
          {'id': 'b', 'name': 'Dev', 'value': '03092335909'},
        ],
      });

      expect(link.hasMultipleEntries, isTrue);
      expect(link.entries!.first.name, 'Saim');
      expect(link.entries!.last.name, 'Dev');
    });

    test('fromApiJson without entries is single', () {
      final link = SocialLink.fromApiJson({
        'title': 'Whatsapp',
        'type': 'phone',
        'value': '03362402187',
      });
      expect(link.hasMultipleEntries, isFalse);
      expect(link.effectiveEntries.length, 1);
    });

    test('urlForValue builds wa.me for WhatsApp', () {
      final link = SocialLink(
        id: '1',
        platform: SocialPlatform.whatsApp,
        customLabel: 'Whatsapp',
        value: '03362402187',
      );
      expect(link.urlForValue('03092335909'), 'https://wa.me/03092335909');
    });
  });

  group('LinkEntriesCache', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('save + apply restores entries when API link has none', () async {
      final saved = SocialLink(
        id: 'local-1',
        platform: SocialPlatform.whatsApp,
        templateId: '507f1f77bcf86cd799439099',
        customLabel: 'Whatsapp',
        value: '03362402187',
        entries: const [
          LinkEntry(id: 'a', name: 'Saim', value: '03362402187'),
          LinkEntry(id: 'b', name: 'Dev', value: '03092335909'),
        ],
      );

      await LinkEntriesCache.save('user1', [saved]);

      final fromApi = SocialLink(
        id: '507f1f77bcf86cd799439011',
        platform: SocialPlatform.whatsApp,
        templateId: '507f1f77bcf86cd799439099',
        customLabel: 'Whatsapp',
        value: '03362402187',
      );

      final restored = await LinkEntriesCache.apply('user1', [fromApi]);
      expect(restored.first.hasMultipleEntries, isTrue);
      expect(restored.first.entries!.map((e) => e.name).toList(), [
        'Saim',
        'Dev',
      ]);
    });

    test('resolve works without userId via per-item key', () async {
      final saved = SocialLink(
        id: 'local-1',
        platform: SocialPlatform.whatsApp,
        customLabel: 'Whatsapp',
        value: '03362402187',
        entries: const [
          LinkEntry(id: 'a', name: 'Saim', value: '03362402187'),
          LinkEntry(id: 'b', name: 'Dev', value: '03092335909'),
        ],
      );
      await LinkEntriesCache.save('', [saved]);
      final resolved = await LinkEntriesCache.resolve(
        SocialLink(
          id: 'x',
          platform: SocialPlatform.whatsApp,
          customLabel: 'Whatsapp',
          value: '03362402187',
        ),
      );
      expect(resolved.hasMultipleEntries, isTrue);
    });
  });
}

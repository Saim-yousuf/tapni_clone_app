import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/screens/business_website/business_website_customize_screen.dart';

void main() {
  group('hex color helpers', () {
    test('normalizes 6-digit and 3-digit hex', () {
      expect(normalizeHexColorInput('#E4572E'), '#e4572e');
      expect(normalizeHexColorInput('abc'), '#aabbcc');
      expect(normalizeHexColorInput('E4572E'), '#e4572e');
    });

    test('rejects invalid colors', () {
      expect(normalizeHexColorInput(''), isNull);
      expect(normalizeHexColorInput('nope'), isNull);
      expect(normalizeHexColorInput('#12'), isNull);
    });
  });

  group('BusinessWebsiteDesign', () {
    test('legacy json defaults showLogo/showBio true', () {
      final d = BusinessWebsiteDesign.fromJson({'themeColor': '#111111'});
      expect(d.showLogo, isTrue);
      expect(d.showBio, isTrue);
      expect(d.hasCustomThemeColor, isFalse);
      expect(d.homepageHeadline, '');
      expect(d.themeColor, '#111111');
    });

    test('toDesignPatchJson includes customization fields only', () {
      const d = BusinessWebsiteDesign(
        themeColor: '#2563eb',
        hasCustomThemeColor: true,
        homepageHeadline: 'Hello',
        showLogo: false,
        showBio: true,
        fontStyle: 'elegant',
      );
      final patch = d.toDesignPatchJson();
      expect(patch['themeColor'], '#2563eb');
      expect(patch['hasCustomThemeColor'], isTrue);
      expect(patch['homepageHeadline'], 'Hello');
      expect(patch['showLogo'], isFalse);
      expect(patch['showBio'], isTrue);
      expect(patch.containsKey('fontStyle'), isFalse);
    });

    test('explicit false visibility is preserved', () {
      final d = BusinessWebsiteDesign.fromJson({
        'showLogo': false,
        'showBio': false,
      });
      expect(d.showLogo, isFalse);
      expect(d.showBio, isFalse);
    });
  });
}

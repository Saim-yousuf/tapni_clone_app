import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/utils/business_feature_hub.dart';
import 'package:tapni_app/utils/business_features.dart';

void main() {
  group('Retail / products open feature access', () {
    test('defaults remain; optionals include all other catalog features', () {
      expect(
        kDefaultFeatures['products'],
        containsAll(['products', 'website', 'orders', 'earnings']),
      );
      expect(
        kOptionalFeatures['products'],
        containsAll([
          'loyalty',
          'offers',
          'ads',
          'pickup',
          'delivery',
          'team',
          'rooms',
          'stay_bookings',
          'calendar',
          'staff',
          'pos',
        ]),
      );
    });

    test('no type-based unsupported reason for rooms', () {
      expect(unsupportedFeatureReasonClient('products', 'rooms'), isEmpty);
      expect(unsupportedFeatureReasonClient('products', 'pickup'), isEmpty);
    });

    test('businessTypeLabel distinguishes Retail from Stay', () {
      expect(businessTypeLabel('products'), 'Products / Retail');
      expect(businessTypeLabel('stay'), 'Stay / Hotel');
    });

    test('hub exposes rooms for every type; access open', () {
      final access = BusinessFeatureAccess.fromProfile(
        businessType: 'products',
        businessCategory: 'Retail',
        enabledFeatures: ['products', 'website', 'orders', 'earnings'],
        featuresInitialized: true,
        featuresMap: {
          'rooms': {'state': 'available'},
          'pickup': {'state': 'available'},
        },
      );
      expect(access.businessType, 'products');
      expect(access.isStay, isFalse);
      expect(access.showRooms, isTrue);
      expect(access.isAvailable('pickup'), isTrue);
      expect(access.isAvailable('rooms'), isTrue);
    });

    test('Feature Hub frequent vs more by type', () {
      final retailFreq = frequentHubItems('products').map((e) => e.id).toList();
      final stayFreq = frequentHubItems('stay').map((e) => e.id).toList();
      expect(retailFreq, contains('orders'));
      expect(retailFreq, contains('website'));
      expect(stayFreq, contains('rooms'));
      expect(moreHubItems('products').map((e) => e.id), contains('rooms'));
      expect(moreHubItems('products').map((e) => e.id), contains('loyalty'));
    });
  });
}

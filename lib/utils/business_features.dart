/// Client-side mirror of backend `config/businessFeatures.js`.
/// Prefer API snapshot on [UserProfile] when present; these helpers cover
/// offline / pre-backfill navigation.

const kBusinessTypes = [
  'restaurant',
  'products',
  'services',
  'stay',
  'portfolio',
];

const Map<String, String> kCategoryToBusinessType = {
  'Food & Beverage': 'restaurant',
  'Retail': 'products',
  'Health': 'services',
  'Education': 'services',
  'Technology': 'services',
  'Finance': 'services',
  'Real Estate': 'stay',
  'Entertainment': 'services',
  'Other': 'products',
};

const Map<String, List<String>> kDefaultFeatures = {
  'restaurant': ['menu', 'website', 'pickup', 'delivery', 'orders', 'earnings'],
  'products': ['products', 'website', 'orders', 'earnings'],
  'services': [
    'services',
    'website',
    'availability',
    'appointments',
    'orders',
    'calendar',
    'earnings',
  ],
  'stay': [
    'products',
    'website',
    'rooms',
    'stay_bookings',
    'orders',
    'calendar',
    'earnings',
  ],
  'portfolio': ['portfolio', 'website'],
};

const Map<String, Map<String, String>> kFeatureMeta = {
  'menu': {
    'title': 'Menu Management',
    'description': 'Sections and food items for your restaurant website.',
  },
  'products': {
    'title': 'Product Catalog',
    'description': 'Product sections and items customers can browse and order.',
  },
  'services': {
    'title': 'Services Catalog',
    'description': 'Service list with duration and booking type.',
  },
  'portfolio': {
    'title': 'Portfolio Website',
    'description': 'Showcase sections and projects — browse only.',
  },
  'website': {
    'title': 'Website Publishing',
    'description': 'Create, preview, and publish your business website.',
  },
  'pickup': {
    'title': 'Pickup Orders',
    'description': 'Customers place orders for collection.',
  },
  'delivery': {
    'title': 'Delivery Orders',
    'description': 'Customers place orders with a delivery address.',
  },
  'orders': {
    'title': 'Orders & Bookings',
    'description': 'Inbox for customer orders, appointments, and stays.',
  },
  'earnings': {
    'title': 'Earnings',
    'description': 'Wallet balance and payment history.',
  },
  'availability': {
    'title': 'Service Availability',
    'description': 'Working days, hours, and slot duration.',
  },
  'appointments': {
    'title': 'Appointments',
    'description': 'Customers book service time slots.',
  },
  'calendar': {
    'title': 'Calendar',
    'description': 'Busy times for appointments and stays.',
  },
  'rooms': {
    'title': 'Room Management',
    'description': 'Rooms used for stay availability and bookings.',
  },
  'stay_bookings': {
    'title': 'Stay Bookings',
    'description': 'Night inventory and stay reservations.',
  },
  'loyalty': {
    'title': 'Loyalty',
    'description': 'Stamp or points rewards for customers.',
  },
  'offers': {
    'title': 'Offers & Coupons',
    'description': 'Discounts customers can apply at checkout.',
  },
  'ads': {
    'title': 'Banner Ads',
    'description': 'Promote your business on Explore.',
  },
  'staff': {
    'title': 'Staff / Specialists',
    'description': 'Bookable team members for appointments.',
  },
  'team': {
    'title': 'Team Attendance',
    'description': 'Invite employees, shifts, and presence.',
  },
  'pos': {
    'title': 'POS Connect',
    'description': 'Push orders to kitchen POS.',
  },
};

/// Every catalog feature is available to every business type.
/// Non-defaults are optional (activatable); type only sets defaults.
List<String> _openOptionalFor(List<String> defaults) {
  final set = defaults.toSet();
  return kFeatureMeta.keys.where((k) => !set.contains(k)).toList();
}

final Map<String, List<String>> kOptionalFeatures = {
  for (final e in kDefaultFeatures.entries) e.key: _openOptionalFor(e.value),
};

String normalizeBusinessType(String? value) {
  final t = (value ?? '').trim().toLowerCase();
  return kBusinessTypes.contains(t) ? t : '';
}

String inferBusinessTypeFromCategory(String? category) {
  return kCategoryToBusinessType[category?.trim() ?? ''] ?? '';
}

String businessTypeLabel(String? type) {
  switch (normalizeBusinessType(type)) {
    case 'restaurant':
      return 'Restaurant';
    case 'products':
      return 'Products / Retail';
    case 'services':
      return 'Services';
    case 'stay':
      return 'Stay / Hotel';
    case 'portfolio':
      return 'Portfolio';
    default:
      return 'Business';
  }
}

/// Client mirror — features are open across business types.
String unsupportedFeatureReasonClient(String? businessType, String featureKey) {
  if (featureKey.trim().isEmpty) return '';
  if (kFeatureMeta.containsKey(featureKey)) return '';
  return 'Unknown feature.';
}

/// Primary websiteType for setup / My Website shortcuts.
String websiteTypeForBusinessType(String? businessType) {
  switch (normalizeBusinessType(businessType)) {
    case 'restaurant':
      return 'menu';
    case 'services':
      return 'service';
    case 'portfolio':
      return 'portfolio';
    case 'stay':
    case 'products':
      return 'products';
    default:
      return 'menu';
  }
}

String catalogTypeForBusinessType(String? businessType) {
  switch (normalizeBusinessType(businessType)) {
    case 'restaurant':
      return 'menu';
    case 'services':
      return 'services';
    case 'portfolio':
      return 'portfolio';
    case 'stay':
    case 'products':
      return 'products';
    default:
      return 'menu';
  }
}

/// Resolve routing type without writing to the server.
/// Prefer explicit [businessType]; fall back to Explore industry category.
String resolveBusinessTypeForRouting({
  String? businessType,
  String? businessCategory,
}) {
  final explicit = normalizeBusinessType(businessType);
  if (explicit.isNotEmpty) return explicit;
  return inferBusinessTypeFromCategory(businessCategory);
}

/// Website template category names for products vertical (Retail vs Hospitality).
bool websiteCategoryMatchesBusinessType(
  String categoryName,
  String? businessType,
) {
  final type = normalizeBusinessType(businessType);
  final name = categoryName.trim().toLowerCase();
  if (type == 'products') {
    return name.contains('retail') ||
        name.contains('ecommerce') ||
        name.contains('e-commerce') ||
        name.contains('shop') ||
        name.contains('store');
  }
  if (type == 'stay') {
    return name.contains('hospitality') ||
        name.contains('hotel') ||
        name.contains('stay') ||
        name.contains('lodging') ||
        name.contains('resort');
  }
  // Other business types: do not filter website categories by this helper.
  return true;
}

class BusinessFeatureAccess {
  final String businessType;
  final List<String> enabledFeatures;
  final bool featuresInitialized;
  final Map<String, String> featureStates;

  const BusinessFeatureAccess({
    required this.businessType,
    required this.enabledFeatures,
    this.featuresInitialized = false,
    this.featureStates = const {},
  });

  factory BusinessFeatureAccess.fromProfile({
    required String? businessType,
    required String? businessCategory,
    required List<String>? enabledFeatures,
    bool featuresInitialized = false,
    Map<String, dynamic>? featuresMap,
  }) {
    var type = normalizeBusinessType(businessType);
    if (type.isEmpty) {
      type = inferBusinessTypeFromCategory(businessCategory);
    }
    if (type.isEmpty) type = 'products';

    final states = <String, String>{};
    if (featuresMap != null) {
      for (final entry in featuresMap.entries) {
        final v = entry.value;
        if (v is Map && v['state'] != null) {
          states[entry.key] = v['state'].toString();
        }
      }
    }

    var enabled = (enabledFeatures ?? [])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (!featuresInitialized || enabled.isEmpty) {
      // Generous local fallback until API backfill lands.
      enabled = [
        ...(kDefaultFeatures[type] ?? const []),
        ...(kOptionalFeatures[type] ?? const []),
      ];
    } else {
      final defaults = kDefaultFeatures[type] ?? const [];
      for (final d in defaults) {
        if (!enabled.contains(d)) enabled.add(d);
      }
    }

    return BusinessFeatureAccess(
      businessType: type,
      enabledFeatures: enabled,
      featuresInitialized: featuresInitialized,
      featureStates: states,
    );
  }

  bool isEnabled(String feature) {
    final state = featureStates[feature];
    // Hub access is open across types; locked still means Pro plan gate.
    if (state == 'locked') return false;
    if (state == 'enabled') return true;
    if (state == 'available') return false;
    // Legacy "unsupported" from older APIs: treat as available to activate.
    if (state == 'unsupported') return false;
    final defaults = kDefaultFeatures[businessType] ?? const [];
    if (defaults.contains(feature)) return true;
    return enabledFeatures.contains(feature);
  }

  bool isAvailable(String feature) {
    final state = featureStates[feature];
    if (state == 'locked') return false;
    if (state == 'available' || state == 'unsupported') return true;
    if (state == 'enabled') return false;
    final optional = kOptionalFeatures[businessType] ?? const [];
    return optional.contains(feature) && !enabledFeatures.contains(feature);
  }

  bool isLocked(String feature) {
    final state = featureStates[feature];
    if (state == 'locked') return true;
    return false;
  }

  /// Suite / hub: modules are navigable for every business type.
  bool get showCalendar => true;
  bool get showRooms => true;
  bool get showOrders => true;
  bool get showEarnings => true;
  bool get showLoyalty => true;
  bool get showOffers => true;
  bool get showAds => true;
  bool get showTeam => true;
  bool get showStaff => true;
  bool get showPos => true;
  bool get showWebsite => true;
  bool get isPortfolio => businessType == 'portfolio';
  bool get isRestaurant => businessType == 'restaurant';
  bool get isServices => businessType == 'services';
  bool get isStay => businessType == 'stay';
}

/// Setup checklist steps per business type.
List<SetupChecklistStep> setupStepsFor(String? businessType) {
  final type = normalizeBusinessType(businessType);
  switch (type) {
    case 'restaurant':
      return const [
        SetupChecklistStep(id: 'profile', title: 'Complete Business Profile'),
        SetupChecklistStep(id: 'website', title: 'Create Menu Website'),
        SetupChecklistStep(id: 'sections', title: 'Add Menu Sections'),
        SetupChecklistStep(id: 'items', title: 'Add Food Items'),
        SetupChecklistStep(id: 'fulfillment', title: 'Pickup & Delivery Settings'),
        SetupChecklistStep(id: 'publish', title: 'Publish Website'),
      ];
    case 'services':
      return const [
        SetupChecklistStep(id: 'profile', title: 'Complete Business Profile'),
        SetupChecklistStep(id: 'website', title: 'Create Services Website'),
        SetupChecklistStep(id: 'items', title: 'Add Services'),
        SetupChecklistStep(id: 'availability', title: 'Working Hours'),
        SetupChecklistStep(id: 'staff', title: 'Optional Staff Setup', optional: true),
        SetupChecklistStep(id: 'publish', title: 'Publish Website'),
      ];
    case 'stay':
      return const [
        SetupChecklistStep(id: 'profile', title: 'Complete Business Profile'),
        SetupChecklistStep(id: 'website', title: 'Create Stay Website'),
        SetupChecklistStep(id: 'items', title: 'Add Room Offers'),
        SetupChecklistStep(id: 'rooms', title: 'Configure Rooms'),
        SetupChecklistStep(id: 'publish', title: 'Publish Website'),
      ];
    case 'portfolio':
      return const [
        SetupChecklistStep(id: 'profile', title: 'Complete Business Profile'),
        SetupChecklistStep(id: 'website', title: 'Create Portfolio Website'),
        SetupChecklistStep(id: 'sections', title: 'Add Sections'),
        SetupChecklistStep(id: 'items', title: 'Add Projects'),
        SetupChecklistStep(id: 'publish', title: 'Publish Website'),
      ];
    case 'products':
    default:
      return const [
        SetupChecklistStep(id: 'profile', title: 'Complete Business Profile'),
        SetupChecklistStep(id: 'website', title: 'Create Products Website'),
        SetupChecklistStep(id: 'sections', title: 'Add Product Sections'),
        SetupChecklistStep(id: 'items', title: 'Add Products'),
        SetupChecklistStep(id: 'publish', title: 'Publish Website'),
      ];
  }
}

class SetupChecklistStep {
  final String id;
  final String title;
  final bool optional;

  const SetupChecklistStep({
    required this.id,
    required this.title,
    this.optional = false,
  });
}

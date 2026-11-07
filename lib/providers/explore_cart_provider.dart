import 'package:flutter/foundation.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/models/explore_cart.dart';

class ExploreCartProvider extends ChangeNotifier {
  final List<ExploreCartVendor> _vendors = [];

  /// takeaway (pickup) | delivery — shared across cart → checkout.
  String _fulfillMode = 'takeaway';
  String _deliveryLine = '';
  String _deliveryApt = '';
  String _deliveryEntry = '';
  String _deliveryBuilding = '';
  String _deliveryNotes = '';
  double? _deliveryLat;
  double? _deliveryLng;
  /// cash_on_delivery | online
  String _paymentMethod = 'cash_on_delivery';
  /// Selected delivery area chip (when vendor.deliveryAreas is non-empty).
  String _deliveryArea = '';
  /// Tip in major currency units (0 when tips disabled / none).
  double _tipAmount = 0;
  /// `datetime-local` style value: `yyyy-MM-ddTHH:mm` (empty = ASAP).
  String _scheduledFor = '';

  List<ExploreCartVendor> get vendors => List.unmodifiable(_vendors);

  bool get isEmpty => _vendors.every((v) => v.lines.isEmpty) || _vendors.isEmpty;
  bool get hasItems => !isEmpty;

  int get itemCount =>
      _vendors.fold<int>(0, (sum, v) => sum + v.itemCount);

  double get total =>
      _vendors.fold<double>(0, (sum, v) => sum + v.total);

  int get vendorCount => _vendors.where((v) => v.lines.isNotEmpty).length;

  String get fulfillMode => _fulfillMode;
  bool get isDelivery => _fulfillMode == 'delivery';
  String get deliveryLine => _deliveryLine;
  String get deliveryApt => _deliveryApt;
  String get deliveryEntry => _deliveryEntry;
  String get deliveryBuilding => _deliveryBuilding;
  String get deliveryNotes =>
      stripLegacyDeliveryDropOffNotes(_deliveryNotes);
  double? get deliveryLat => _deliveryLat;
  double? get deliveryLng => _deliveryLng;
  String get paymentMethod => _paymentMethod;
  String get deliveryArea => _deliveryArea;
  double get tipAmount => _tipAmount;
  String get scheduledFor => _scheduledFor;

  List<ExploreCartVendor> get activeVendors =>
      _vendors.where((v) => v.lines.isNotEmpty).toList();

  bool get acceptsPickup =>
      activeVendors.isEmpty || activeVendors.every((v) => v.acceptPickup);

  bool get acceptsDelivery =>
      activeVendors.isEmpty || activeVendors.every((v) => v.acceptDelivery);

  bool get tipsEnabled => activeVendors.any((v) => v.tipsEnabled);

  bool get scheduleOrdersEnabled =>
      activeVendors.any((v) => v.scheduleOrdersEnabled);

  bool get canScheduleWhileClosed =>
      activeVendors.any((v) => v.canScheduleWhileClosed);

  List<String> get deliveryAreas {
    for (final v in activeVendors) {
      if (v.deliveryAreas.isNotEmpty) return List<String>.from(v.deliveryAreas);
    }
    return const [];
  }

  /// Longest prep estimate among active vendors (minutes).
  int get prepTimeMinutes => activeVendors.fold<int>(
        0,
        (max, v) => v.prepTimeMinutes > max ? v.prepTimeMinutes : max,
      );

  String get prepTimeLabel {
    final m = prepTimeMinutes;
    if (m <= 0) return '';
    return 'Ready in ~$m min';
  }

  double get minOrderAmount => activeVendors.fold<double>(
        0,
        (max, v) => v.minOrderAmount > max ? v.minOrderAmount : max,
      );

  bool get belowMinOrder =>
      activeVendors.any((v) => v.belowMinOrder);

  double get minOrderShortfall => activeVendors.fold<double>(
        0,
        (sum, v) => sum + v.minOrderShortfall,
      );

  String get deliveryDisplayAddress {
    final parts = <String>[
      _deliveryLine.trim(),
      if (_deliveryApt.trim().isNotEmpty) _deliveryApt.trim(),
      if (_deliveryBuilding.trim().isNotEmpty) _deliveryBuilding.trim(),
    ].where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  double get deliveryFeesTotal {
    if (!isDelivery) return 0;
    return _vendors.fold<double>(
      0,
      (sum, v) =>
          v.lines.isEmpty ? sum : sum + v.deliveryFeeForSubtotal(v.total),
    );
  }

  double get effectiveTip => tipsEnabled ? _tipAmount.clamp(0, 1e9) : 0;

  double get payableTotal => total + deliveryFeesTotal + effectiveTip;

  void setFulfillMode(String mode) {
    var next = mode == 'delivery' ? 'delivery' : 'takeaway';
    if (next == 'delivery' && !acceptsDelivery && acceptsPickup) {
      next = 'takeaway';
    } else if (next == 'takeaway' && !acceptsPickup && acceptsDelivery) {
      next = 'delivery';
    }
    if (_fulfillMode == next) return;
    _fulfillMode = next;
    notifyListeners();
  }

  /// Keep fulfill mode valid after storefront flags refresh.
  void _syncFulfillModeToFlags() {
    if (_fulfillMode == 'delivery' && !acceptsDelivery && acceptsPickup) {
      _fulfillMode = 'takeaway';
    } else if (_fulfillMode == 'takeaway' && !acceptsPickup && acceptsDelivery) {
      _fulfillMode = 'delivery';
    }
  }

  void setPaymentMethod(String method) {
    final next = method == 'online' ? 'online' : 'cash_on_delivery';
    if (_paymentMethod == next) return;
    _paymentMethod = next;
    notifyListeners();
  }

  void setDeliveryArea(String area) {
    final next = area.trim();
    if (_deliveryArea == next) return;
    _deliveryArea = next;
    notifyListeners();
  }

  void setTipAmount(double amount) {
    final next = amount.isFinite && amount > 0 ? amount : 0.0;
    if (_tipAmount == next) return;
    _tipAmount = next;
    notifyListeners();
  }

  void setScheduledFor(String value) {
    final next = value.trim();
    if (_scheduledFor == next) return;
    _scheduledFor = next;
    notifyListeners();
  }

  void setDeliveryAddress({
    String? line,
    String? apt,
    String? entry,
    String? building,
    String? notes,
    double? lat,
    double? lng,
    bool clearCoords = false,
  }) {
    if (line != null) _deliveryLine = line.trim();
    if (apt != null) _deliveryApt = apt.trim();
    if (entry != null) _deliveryEntry = entry.trim();
    if (building != null) _deliveryBuilding = building.trim();
    if (notes != null) {
      _deliveryNotes = stripLegacyDeliveryDropOffNotes(notes);
    }
    if (clearCoords) {
      _deliveryLat = null;
      _deliveryLng = null;
    } else {
      if (lat != null) _deliveryLat = lat;
      if (lng != null) _deliveryLng = lng;
    }
    notifyListeners();
  }

  /// Adds (or merges qty). Different businesses keep separate baskets.
  void addItem({
    required String businessId,
    required String businessLinkId,
    required String businessName,
    String businessUsername = '',
    required String catalogType,
    String currency = 'PKR',
    String websiteSlug = '',
    bool ordersPaused = false,
    bool isClosedNow = false,
    required List<CatalogItem> catalogItems,
    required ExploreCartLine line,
  }) {
    final idx = _vendors.indexWhere(
      (v) =>
          v.businessId == businessId && v.businessLinkId == businessLinkId,
    );

    if (idx < 0) {
      _vendors.add(
        ExploreCartVendor(
          businessId: businessId,
          businessLinkId: businessLinkId,
          businessName: businessName,
          businessUsername: businessUsername,
          catalogType: catalogType,
          currency: currency,
          websiteSlug: websiteSlug,
          ordersPaused: ordersPaused,
          isClosedNow: isClosedNow,
          catalogItems: List<CatalogItem>.from(catalogItems),
          lines: [line],
        ),
      );
      _syncFulfillModeToFlags();
      notifyListeners();
      return;
    }

    final vendor = _vendors[idx];
    final lines = List<ExploreCartLine>.from(vendor.lines);
    final lineIdx = lines.indexWhere((l) => l.sameIdentityAs(line));
    if (lineIdx >= 0) {
      final existing = lines[lineIdx];
      lines[lineIdx] = existing.copyWith(
        quantity: existing.quantity + line.quantity,
        notes: line.notes.isNotEmpty ? line.notes : existing.notes,
      );
    } else {
      lines.add(line);
    }

    // Merge catalog item snapshots (prefer id match).
    final mergedCatalog = List<CatalogItem>.from(vendor.catalogItems);
    for (final ci in catalogItems) {
      final existingIdx = mergedCatalog.indexWhere(
        (e) =>
            (ci.id.isNotEmpty && e.id == ci.id) ||
            (ci.id.isEmpty && e.name == ci.name),
      );
      if (existingIdx < 0) {
        mergedCatalog.add(ci);
      } else {
        mergedCatalog[existingIdx] = ci;
      }
    }

    _vendors[idx] = vendor.copyWith(
      businessName: businessName,
      businessUsername: businessUsername.isNotEmpty
          ? businessUsername
          : vendor.businessUsername,
      catalogType: catalogType,
      currency: currency,
      websiteSlug:
          websiteSlug.isNotEmpty ? websiteSlug : vendor.websiteSlug,
      ordersPaused: ordersPaused,
      isClosedNow: isClosedNow,
      catalogItems: mergedCatalog,
      lines: lines,
    );
    _syncFulfillModeToFlags();
    notifyListeners();
  }

  /// Refresh menu open/paused / ordering rules from website status.
  void updateVendorOrderingStatus({
    required String businessId,
    String websiteSlug = '',
    required bool ordersPaused,
    required bool isClosedNow,
    double? deliveryFee,
    double? freeDeliveryAbove,
    double? minOrderAmount,
    bool? acceptPickup,
    bool? acceptDelivery,
    bool? tipsEnabled,
    bool? scheduleOrdersEnabled,
    List<String>? deliveryAreas,
    int? prepTimeMinutes,
  }) {
    final id = businessId.trim();
    final slug = websiteSlug.trim();
    var changed = false;
    for (var i = 0; i < _vendors.length; i++) {
      final v = _vendors[i];
      final match = (id.isNotEmpty && v.businessId == id) ||
          (slug.isNotEmpty && v.websiteSlug == slug);
      if (!match) continue;
      final nextFee = deliveryFee ?? v.deliveryFee;
      final nextFree = freeDeliveryAbove ?? v.freeDeliveryAbove;
      final nextMin = minOrderAmount ?? v.minOrderAmount;
      final nextPickup = acceptPickup ?? v.acceptPickup;
      final nextDelivery = acceptDelivery ?? v.acceptDelivery;
      final nextTips = tipsEnabled ?? v.tipsEnabled;
      final nextSched = scheduleOrdersEnabled ?? v.scheduleOrdersEnabled;
      final nextAreas = deliveryAreas ?? v.deliveryAreas;
      final nextPrep = prepTimeMinutes ?? v.prepTimeMinutes;
      final areasSame = listEquals(nextAreas, v.deliveryAreas);
      if (v.ordersPaused == ordersPaused &&
          v.isClosedNow == isClosedNow &&
          v.deliveryFee == nextFee &&
          v.freeDeliveryAbove == nextFree &&
          v.minOrderAmount == nextMin &&
          v.acceptPickup == nextPickup &&
          v.acceptDelivery == nextDelivery &&
          v.tipsEnabled == nextTips &&
          v.scheduleOrdersEnabled == nextSched &&
          areasSame &&
          v.prepTimeMinutes == nextPrep) {
        continue;
      }
      _vendors[i] = v.copyWith(
        ordersPaused: ordersPaused,
        isClosedNow: isClosedNow,
        deliveryFee: nextFee,
        freeDeliveryAbove: nextFree,
        minOrderAmount: nextMin,
        acceptPickup: nextPickup,
        acceptDelivery: nextDelivery,
        tipsEnabled: nextTips,
        scheduleOrdersEnabled: nextSched,
        deliveryAreas: nextAreas,
        prepTimeMinutes: nextPrep,
      );
      changed = true;
    }
    if (changed) {
      _syncFulfillModeToFlags();
      if (_tipAmount > 0 && !this.tipsEnabled) _tipAmount = 0;
      if (_scheduledFor.isNotEmpty && !this.scheduleOrdersEnabled) {
        _scheduledFor = '';
      }
      final areas = this.deliveryAreas;
      if (_deliveryArea.isNotEmpty &&
          (areas.isEmpty || !areas.contains(_deliveryArea))) {
        // Keep area only while the vendor still lists it.
        if (areas.isNotEmpty) _deliveryArea = '';
      }
      notifyListeners();
    }
  }

  void updateQuantity({
    required String businessLinkId,
    required int lineIndex,
    required int quantity,
  }) {
    final vIdx = _vendors.indexWhere((v) => v.businessLinkId == businessLinkId);
    if (vIdx < 0) return;
    final vendor = _vendors[vIdx];
    if (lineIndex < 0 || lineIndex >= vendor.lines.length) return;

    final lines = List<ExploreCartLine>.from(vendor.lines);
    if (quantity <= 0) {
      lines.removeAt(lineIndex);
    } else {
      lines[lineIndex] = lines[lineIndex].copyWith(quantity: quantity);
    }

    if (lines.isEmpty) {
      _vendors.removeAt(vIdx);
    } else {
      _vendors[vIdx] = vendor.copyWith(lines: lines);
    }
    notifyListeners();
  }

  void removeLine({
    required String businessLinkId,
    required int lineIndex,
  }) {
    updateQuantity(
      businessLinkId: businessLinkId,
      lineIndex: lineIndex,
      quantity: 0,
    );
  }

  void updateLine({
    required String businessLinkId,
    required int lineIndex,
    int? quantity,
    String? notes,
  }) {
    final vIdx = _vendors.indexWhere((v) => v.businessLinkId == businessLinkId);
    if (vIdx < 0) return;
    final vendor = _vendors[vIdx];
    if (lineIndex < 0 || lineIndex >= vendor.lines.length) return;

    final lines = List<ExploreCartLine>.from(vendor.lines);
    final current = lines[lineIndex];
    final nextQty = quantity ?? current.quantity;
    if (nextQty <= 0) {
      lines.removeAt(lineIndex);
    } else {
      lines[lineIndex] = current.copyWith(
        quantity: nextQty,
        notes: notes ?? current.notes,
      );
    }

    if (lines.isEmpty) {
      _vendors.removeAt(vIdx);
    } else {
      _vendors[vIdx] = vendor.copyWith(lines: lines);
    }
    notifyListeners();
  }

  void removeVendor(String businessLinkId) {
    _vendors.removeWhere((v) => v.businessLinkId == businessLinkId);
    notifyListeners();
  }

  /// Replace / merge the catalog snapshot used by "Add more".
  void setVendorCatalogItems({
    required String businessLinkId,
    required List<CatalogItem> catalogItems,
  }) {
    final vIdx = _vendors.indexWhere((v) => v.businessLinkId == businessLinkId);
    if (vIdx < 0) return;
    final vendor = _vendors[vIdx];
    final merged = List<CatalogItem>.from(vendor.catalogItems);
    for (final ci in catalogItems) {
      final existingIdx = merged.indexWhere(
        (e) =>
            (ci.id.isNotEmpty && e.id == ci.id) ||
            (ci.id.isEmpty && e.name == ci.name),
      );
      if (existingIdx < 0) {
        merged.add(ci);
      } else {
        merged[existingIdx] = ci;
      }
    }
    _vendors[vIdx] = vendor.copyWith(catalogItems: merged);
    notifyListeners();
  }

  void clear() {
    _vendors.clear();
    _fulfillMode = 'takeaway';
    _deliveryLine = '';
    _deliveryApt = '';
    _deliveryEntry = '';
    _deliveryBuilding = '';
    _deliveryNotes = '';
    _deliveryLat = null;
    _deliveryLng = null;
    _paymentMethod = 'cash_on_delivery';
    _deliveryArea = '';
    _tipAmount = 0;
    _scheduledFor = '';
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_cart.dart';

class ExploreCartProvider extends ChangeNotifier {
  final List<ExploreCartVendor> _vendors = [];

  List<ExploreCartVendor> get vendors => List.unmodifiable(_vendors);

  bool get isEmpty => _vendors.every((v) => v.lines.isEmpty) || _vendors.isEmpty;
  bool get hasItems => !isEmpty;

  int get itemCount =>
      _vendors.fold<int>(0, (sum, v) => sum + v.itemCount);

  double get total =>
      _vendors.fold<double>(0, (sum, v) => sum + v.total);

  int get vendorCount => _vendors.where((v) => v.lines.isNotEmpty).length;

  /// Adds (or merges qty). Different businesses keep separate baskets.
  void addItem({
    required String businessId,
    required String businessLinkId,
    required String businessName,
    required String catalogType,
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
          catalogType: catalogType,
          catalogItems: List<CatalogItem>.from(catalogItems),
          lines: [line],
        ),
      );
      notifyListeners();
      return;
    }

    final vendor = _vendors[idx];
    final lines = List<ExploreCartLine>.from(vendor.lines);
    final lineIdx = lines.indexWhere((l) => l.item.name == line.item.name);
    if (lineIdx >= 0) {
      final existing = lines[lineIdx];
      lines[lineIdx] = existing.copyWith(
        quantity: existing.quantity + line.quantity,
        notes: line.notes.isNotEmpty ? line.notes : existing.notes,
      );
    } else {
      lines.add(line);
    }

    _vendors[idx] = vendor.copyWith(
      businessName: businessName,
      catalogType: catalogType,
      catalogItems: List<CatalogItem>.from(catalogItems),
      lines: lines,
    );
    notifyListeners();
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

  void removeVendor(String businessLinkId) {
    _vendors.removeWhere((v) => v.businessLinkId == businessLinkId);
    notifyListeners();
  }

  void clear() {
    _vendors.clear();
    notifyListeners();
  }
}

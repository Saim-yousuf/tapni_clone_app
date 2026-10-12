import 'package:flutter/foundation.dart';
import 'package:tapni_app/repository/loyalty_points_repo.dart';
import 'package:tapni_app/utils/money_format.dart';

/// Cached business points balance (synced from API).
class BusinessPointsBalance extends ChangeNotifier {
  BusinessPointsBalance._();
  static final BusinessPointsBalance instance = BusinessPointsBalance._();

  int _balance = 0;
  String _currency = 'USD';
  List<PointsPackage> _packages = List.from(kDefaultPointsPackages);
  bool _loaded = false;

  int get balance => _balance;
  String get currency => _currency;
  List<PointsPackage> get packages => _packages;
  bool get loaded => _loaded;

  set balance(int value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }

  void addPoints(int points) {
    balance = _balance + points;
  }

  Future<void> refresh() async {
    final res = await LoyaltyPointsRepo().getBusinessPoints();
    if (!res.success || res.data == null) {
      _loaded = true;
      notifyListeners();
      return;
    }
    final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (raw is! Map) {
      _loaded = true;
      notifyListeners();
      return;
    }
    final map = Map<String, dynamic>.from(raw);
    _balance = (map['balance'] as num?)?.toInt() ?? _balance;
    final cur = map['currency']?.toString();
    if (cur != null && cur.isNotEmpty) _currency = cur.toUpperCase();
    final pkgs = map['packages'];
    if (pkgs is List && pkgs.isNotEmpty) {
      _packages = pkgs
          .whereType<Map>()
          .map(
            (e) => PointsPackage.fromJson(
              Map<String, dynamic>.from(e),
              fallbackCurrency: _currency,
            ),
          )
          .toList();
    }
    _loaded = true;
    notifyListeners();
  }
}

class PointsPackage {
  final String id;
  final int points;
  /// Local display amount (converted from USD on the server).
  final num priceLocal;
  final String currency;
  /// USD cents charged for the base package (1 pt = 1 US cent).
  final int priceUsdCents;
  final int bonusPoints;
  final bool recommended;

  const PointsPackage({
    required this.id,
    required this.points,
    required this.priceLocal,
    this.currency = 'USD',
    this.priceUsdCents = 0,
    this.bonusPoints = 0,
    this.recommended = false,
  });

  int get totalPoints => points + bonusPoints;

  /// Formatted local price for UI (e.g. "ر.س 37.50" / "Rs 2,780").
  String get priceLabel {
    final whole = priceLocal == priceLocal.roundToDouble();
    return formatMoney(priceLocal, currency: currency, compact: whole);
  }

  factory PointsPackage.fromJson(
    Map<String, dynamic> json, {
    String fallbackCurrency = 'USD',
  }) {
    final points = (json['points'] as num?)?.toInt() ?? 0;
    final currency =
        (json['currency']?.toString().isNotEmpty == true
                ? json['currency'].toString()
                : fallbackCurrency)
            .toUpperCase();
    final priceLocal = json['priceLocal'] as num? ??
        json['priceSar'] as num? ??
        (points / 100);
    final priceUsdCents = (json['priceUsdCents'] as num?)?.toInt() ?? points;
    return PointsPackage(
      id: json['id']?.toString() ?? '',
      points: points,
      priceLocal: priceLocal,
      currency: currency,
      priceUsdCents: priceUsdCents,
      bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
      recommended: json['recommended'] == true,
    );
  }
}

/// Offline defaults: USD amounts (1 pt = 1 US cent → $10 / $50 / …).
const kDefaultPointsPackages = [
  PointsPackage(
    id: 'p1k',
    points: 1000,
    priceLocal: 10,
    currency: 'USD',
    priceUsdCents: 1000,
  ),
  PointsPackage(
    id: 'p5k',
    points: 5000,
    priceLocal: 50,
    currency: 'USD',
    priceUsdCents: 5000,
    recommended: true,
  ),
  PointsPackage(
    id: 'p10k',
    points: 10000,
    priceLocal: 100,
    currency: 'USD',
    priceUsdCents: 10000,
    bonusPoints: 2500,
  ),
  PointsPackage(
    id: 'p17k',
    points: 17500,
    priceLocal: 175,
    currency: 'USD',
    priceUsdCents: 17500,
  ),
];

enum PointsActivityKind { purchased, redeemed, withdraw, stampAward, other }

class PointsActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final int delta;
  final DateTime at;
  final PointsActivityKind kind;

  const PointsActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.delta,
    required this.at,
    required this.kind,
  });

  factory PointsActivityItem.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind']?.toString() ?? 'other';
    final kind = switch (kindStr) {
      'purchased' => PointsActivityKind.purchased,
      'redeemed' => PointsActivityKind.redeemed,
      'stamp_award' => PointsActivityKind.stampAward,
      'withdraw' => PointsActivityKind.withdraw,
      _ => PointsActivityKind.other,
    };
    return PointsActivityItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Activity',
      subtitle: json['subtitle']?.toString() ?? '',
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      at: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      kind: kind,
    );
  }
}

String formatPoints(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

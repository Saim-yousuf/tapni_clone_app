import 'package:flutter/foundation.dart';

/// Local stub balance for business points purchase flow (no API yet).
class BusinessPointsBalance extends ChangeNotifier {
  BusinessPointsBalance._();
  static final BusinessPointsBalance instance = BusinessPointsBalance._();

  int _balance = 12500;

  int get balance => _balance;

  set balance(int value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }

  void addPoints(int points) {
    balance = _balance + points;
  }
}

class PointsPackage {
  final String id;
  final int points;
  final int priceSar;
  final int bonusPoints;
  final bool recommended;

  const PointsPackage({
    required this.id,
    required this.points,
    required this.priceSar,
    this.bonusPoints = 0,
    this.recommended = false,
  });

  int get totalPoints => points + bonusPoints;
}

const kDefaultPointsPackages = [
  PointsPackage(id: 'p1k', points: 1000, priceSar: 10),
  PointsPackage(id: 'p5k', points: 5000, priceSar: 50, recommended: true),
  PointsPackage(
    id: 'p10k',
    points: 10000,
    priceSar: 100,
    bonusPoints: 500,
  ),
];

enum PointsActivityKind { purchased, redeemed, withdraw, other }

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
}

List<PointsActivityItem> mockPointsActivity() {
  final now = DateTime.now();
  return [
    PointsActivityItem(
      id: 'a1',
      title: 'Points purchased',
      subtitle: 'Package 5,000 pts',
      delta: 5000,
      at: now.subtract(const Duration(hours: 2)),
      kind: PointsActivityKind.purchased,
    ),
    PointsActivityItem(
      id: 'a2',
      title: 'Customer redemption',
      subtitle: 'Free coffee reward',
      delta: -250,
      at: now.subtract(const Duration(days: 1)),
      kind: PointsActivityKind.redeemed,
    ),
    PointsActivityItem(
      id: 'a3',
      title: 'Points purchased',
      subtitle: 'Package 1,000 pts',
      delta: 1000,
      at: now.subtract(const Duration(days: 3)),
      kind: PointsActivityKind.purchased,
    ),
    PointsActivityItem(
      id: 'a4',
      title: 'Withdrawal',
      subtitle: 'Bank transfer',
      delta: -1200,
      at: now.subtract(const Duration(days: 5)),
      kind: PointsActivityKind.withdraw,
    ),
    PointsActivityItem(
      id: 'a5',
      title: 'Customer redemption',
      subtitle: '10% discount',
      delta: -500,
      at: now.subtract(const Duration(days: 7)),
      kind: PointsActivityKind.redeemed,
    ),
  ];
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

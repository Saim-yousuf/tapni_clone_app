import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_offer.dart';
import 'package:tapni_app/repository/offer_repo.dart';
import 'package:tapni_app/screens/offers/business_offer_form_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Business Suite — list and manage special offers / coupons.
class BusinessOffersScreen extends StatefulWidget {
  const BusinessOffersScreen({super.key});

  @override
  State<BusinessOffersScreen> createState() => _BusinessOffersScreenState();
}

class _BusinessOffersScreenState extends State<BusinessOffersScreen> {
  final _repo = OfferRepo();
  bool _loading = true;
  String? _error;
  List<BusinessOffer> _offers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.listBusinessOffers();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load offers';
      });
      return;
    }
    final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => BusinessOffer.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BusinessOffer>[];
    setState(() {
      _loading = false;
      _offers = list;
    });
  }

  Future<void> _openForm([BusinessOffer? existing]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusinessOfferFormScreen(existing: existing),
      ),
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _toggleActive(BusinessOffer offer) async {
    final res = await _repo.updateOffer(offer.id, {
      'title': offer.title,
      'description': offer.description,
      'code': offer.code,
      'discountType': offer.discountType,
      'discountValue': offer.discountValue,
      'startsAt': offer.startsAt?.toIso8601String(),
      'expiresAt': offer.expiresAt?.toIso8601String(),
      'minOrderAmount': offer.minOrderAmount,
      'maxDiscountAmount': offer.maxDiscountAmount,
      'totalUsageLimit': offer.totalUsageLimit,
      'perCustomerLimit': offer.perCustomerLimit,
      'catalogTypes': offer.catalogTypes,
      'applicableItemIds': offer.applicableItemIds,
      'applicableCategories': offer.applicableCategories,
      'isActive': !offer.isActive,
      'allowWithPoints': offer.allowWithPoints,
      'allowGuests': offer.allowGuests,
    });
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Update failed')),
      );
    }
  }

  Future<void> _delete(BusinessOffer offer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete offer?'),
        content: Text('Remove “${offer.title}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.deleteOffer(offer.id);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Delete failed')),
      );
    }
  }

  String _badge(BusinessOffer o) {
    if (o.discountType == 'percentage') {
      return '${o.discountValue.toStringAsFixed(0)}%';
    }
    return o.discountValue.toStringAsFixed(
      o.discountValue == o.discountValue.roundToDouble() ? 0 : 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: 'Offers',
              trailing: IconButton(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, color: Colors.black),
                tooltip: 'New offer',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Coupons and automatic discounts for checkout. Totals are always calculated on the server.',
                style: WaUi.body.copyWith(
                  color: BarqodyChrome.secondaryText,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: WaUi.body.copyWith(
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _offers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'No offers yet',
                                      style: WaUi.toolsTitleOf(
                                        size: 18,
                                        weight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create a coupon or automatic discount for your customers.',
                                      textAlign: TextAlign.center,
                                      style: WaUi.body.copyWith(
                                        color: BarqodyChrome.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => _openForm(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: const StadiumBorder(),
                                      ),
                                      child: const Text('Create offer'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: Colors.black,
                              onRefresh: _load,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 28),
                                itemCount: _offers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final o = _offers[i];
                                  final usage = o.totalUsageLimit > 0
                                      ? '${o.usedCount}/${o.totalUsageLimit} used'
                                      : '${o.usedCount} used';
                                  return Material(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _openForm(o),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: o.isActive
                                                        ? Colors.black
                                                        : const Color(
                                                            0xFF9CA3AF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    _badge(o),
                                                    style: WaUi.body.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  o.isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: WaUi.body.copyWith(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: o.isActive
                                                        ? const Color(
                                                            0xFF15803D)
                                                        : BarqodyChrome
                                                            .secondaryText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              o.title,
                                              style: WaUi.toolsTitleOf(
                                                size: 16,
                                                weight: FontWeight.w800,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              o.hasCode
                                                  ? 'Code ${o.code} · $usage'
                                                  : 'No code · $usage',
                                              style: WaUi.body.copyWith(
                                                fontSize: 12,
                                                color: BarqodyChrome
                                                    .secondaryText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      _toggleActive(o),
                                                  child: Text(
                                                    o.isActive
                                                        ? 'Deactivate'
                                                        : 'Activate',
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _delete(o),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Color(0xFFD32F2F),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _offers.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_offer.dart';
import 'package:tapni_app/repository/offer_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Customer-facing active offers for a business (browse / pick for checkout).
class CustomerOffersScreen extends StatefulWidget {
  final String businessId;
  final String? catalogType;
  final bool pickMode;

  const CustomerOffersScreen({
    super.key,
    required this.businessId,
    this.catalogType,
    this.pickMode = false,
  });

  @override
  State<CustomerOffersScreen> createState() => _CustomerOffersScreenState();
}

class _CustomerOffersScreenState extends State<CustomerOffersScreen> {
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
    final res = await _repo.listPublicOffers(
      businessId: widget.businessId,
      catalogType: widget.catalogType,
    );
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

  String _label(BusinessOffer o) {
    if (o.discountType == 'percentage') {
      return '${o.discountValue.toStringAsFixed(0)}% OFF';
    }
    return '${o.discountValue.toStringAsFixed(o.discountValue == o.discountValue.roundToDouble() ? 0 : 2)} OFF';
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
              title: widget.pickMode ? 'Choose offer' : 'Offers',
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
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: WaUi.body.copyWith(
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        )
                      : _offers.isEmpty
                          ? Center(
                              child: Text(
                                'No active offers right now.',
                                style: WaUi.body.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: Colors.black,
                              onRefresh: _load,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                itemCount: _offers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final o = _offers[i];
                                  return Material(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: widget.pickMode
                                          ? () => Navigator.of(context).pop(o)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                _label(o),
                                                style: WaUi.body.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
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
                                            if (o.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                o.description,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: WaUi.body.copyWith(
                                                  color: BarqodyChrome
                                                      .secondaryText,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Text(
                                              o.hasCode
                                                  ? 'Code: ${o.code}'
                                                  : 'Apply at checkout',
                                              style: WaUi.body.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/business_offer.dart';
import 'package:tapni_app/repository/offer_repo.dart';
import 'package:tapni_app/screens/offers/customer_offers_screen.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class CheckoutCouponSelection {
  final String code;
  final String offerId;
  final double discountAmount;
  final String title;
  final bool applied;
  final bool valid;
  final String? error;

  const CheckoutCouponSelection({
    required this.code,
    required this.offerId,
    required this.discountAmount,
    required this.title,
    required this.applied,
    required this.valid,
    this.error,
  });

  static const none = CheckoutCouponSelection(
    code: '',
    offerId: '',
    discountAmount: 0,
    title: '',
    applied: false,
    valid: true,
  );
}

/// Optional coupon entry for Flutter checkout. Discount is always server-quoted.
class CheckoutCouponCard extends StatefulWidget {
  final String businessId;
  final double subtotalAmount;
  final String currency;
  final String? catalogType;
  final List<Map<String, dynamic>> items;
  final int pointsToRedeem;
  final ValueChanged<CheckoutCouponSelection> onChanged;

  const CheckoutCouponCard({
    super.key,
    required this.businessId,
    required this.subtotalAmount,
    required this.currency,
    required this.items,
    required this.onChanged,
    this.catalogType,
    this.pointsToRedeem = 0,
  });

  @override
  State<CheckoutCouponCard> createState() => _CheckoutCouponCardState();
}

class _CheckoutCouponCardState extends State<CheckoutCouponCard> {
  final _repo = OfferRepo();
  final _codeCtrl = TextEditingController();
  bool _quoting = false;
  double _discount = 0;
  String _offerId = '';
  String _title = '';
  String? _error;
  bool _applied = false;

  @override
  void didUpdateWidget(covariant CheckoutCouponCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_applied &&
        (oldWidget.subtotalAmount != widget.subtotalAmount ||
            oldWidget.pointsToRedeem != widget.pointsToRedeem ||
            oldWidget.businessId != widget.businessId)) {
      _quote();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      CheckoutCouponSelection(
        code: _applied ? _codeCtrl.text.trim().toUpperCase() : '',
        offerId: _applied ? _offerId : '',
        discountAmount: _applied ? _discount : 0,
        title: _applied ? _title : '',
        applied: _applied && _discount > 0,
        valid: !_applied || (_error == null && _discount > 0),
        error: _applied ? _error : null,
      ),
    );
  }

  Future<void> _quote({String? offerId}) async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final oid = (offerId ?? _offerId).trim();
    if (code.isEmpty && oid.isEmpty) {
      setState(() {
        _error = 'Enter a coupon code';
        _discount = 0;
        _applied = false;
      });
      _emit();
      return;
    }
    setState(() {
      _quoting = true;
      _error = null;
      _applied = true;
    });
    final res = await _repo.quoteCoupon(
      businessId: widget.businessId,
      subtotalAmount: widget.subtotalAmount,
      items: widget.items,
      couponCode: code.isNotEmpty ? code : null,
      offerId: oid.isNotEmpty ? oid : null,
      catalogType: widget.catalogType,
      pointsToRedeem: widget.pointsToRedeem,
    );
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _quoting = false;
        _discount = 0;
        _error = res.message ?? 'Invalid coupon';
      });
      _emit();
      return;
    }
    final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final offer = map['offer'];
    final offerMap =
        offer is Map ? Map<String, dynamic>.from(offer) : <String, dynamic>{};
    setState(() {
      _quoting = false;
      _discount = (map['discountAmount'] as num?)?.toDouble() ?? 0;
      _offerId = map['offerId']?.toString() ?? oid;
      _title = offerMap['title']?.toString() ?? '';
      final returnedCode = map['code']?.toString() ?? '';
      if (returnedCode.isNotEmpty) _codeCtrl.text = returnedCode;
      _error = _discount > 0 ? null : 'Offer produces no discount';
    });
    _emit();
  }

  void _clear() {
    setState(() {
      _codeCtrl.clear();
      _discount = 0;
      _offerId = '';
      _title = '';
      _error = null;
      _applied = false;
      _quoting = false;
    });
    _emit();
  }

  Future<void> _browseOffers() async {
    final picked = await Navigator.of(context).push<BusinessOffer>(
      MaterialPageRoute(
        builder: (_) => CustomerOffersScreen(
          businessId: widget.businessId,
          catalogType: widget.catalogType,
          pickMode: true,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _codeCtrl.text = picked.code;
      _offerId = picked.id;
    });
    await _quote(offerId: picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final money = formatMoney(_discount, currency: widget.currency);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: m.v(12)),
      padding: EdgeInsets.all(m.s(14).clamp(12.0, 16.0)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Coupon',
                  style: WaUi.toolsTitleOf(
                    size: m.s(15).clamp(13.0, 16.0),
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: _browseOffers,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Browse offers',
                  style: WaUi.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: m.v(10)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _quote(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _quoting ? null : () => _quote(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _quoting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
          if (_applied && _discount > 0) ...[
            SizedBox(height: m.v(8)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_title.isNotEmpty ? _title : 'Coupon'} · −$money',
                    style: WaUi.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                    foregroundColor: BarqodyChrome.secondaryText,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ] else if (_error != null) ...[
            SizedBox(height: m.v(8)),
            Text(
              _error!,
              style: WaUi.body.copyWith(
                fontSize: 12,
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

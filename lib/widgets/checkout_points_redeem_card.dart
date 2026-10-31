import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/repository/loyalty_points_repo.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Optional loyalty points redemption for Flutter checkout.
/// Does not force redemption — toggle off by default.
class CheckoutPointsRedeemCard extends StatefulWidget {
  final String businessId;
  final double subtotalAmount;
  final String currency;
  final ValueChanged<CheckoutPointsSelection> onChanged;

  const CheckoutPointsRedeemCard({
    super.key,
    required this.businessId,
    required this.subtotalAmount,
    required this.currency,
    required this.onChanged,
  });

  @override
  State<CheckoutPointsRedeemCard> createState() =>
      _CheckoutPointsRedeemCardState();
}

class CheckoutPointsSelection {
  final bool usePoints;
  final int pointsToRedeem;
  final double discountAmount;
  final double payableAmount;
  final bool valid;
  final String? error;

  const CheckoutPointsSelection({
    required this.usePoints,
    required this.pointsToRedeem,
    required this.discountAmount,
    required this.payableAmount,
    required this.valid,
    this.error,
  });

  static CheckoutPointsSelection none(double subtotal) =>
      CheckoutPointsSelection(
        usePoints: false,
        pointsToRedeem: 0,
        discountAmount: 0,
        payableAmount: subtotal,
        valid: true,
      );
}

class _CheckoutPointsRedeemCardState extends State<CheckoutPointsRedeemCard> {
  final _repo = LoyaltyPointsRepo();
  final _inputCtrl = TextEditingController();

  bool _loading = true;
  bool _enabled = false;
  bool _use = false;
  int _available = 0;
  int _min = 50;
  int _max = 0;
  double _rate = 0;
  int _points = 0;
  double _discount = 0;
  String? _error;
  bool _quoting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CheckoutPointsRedeemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtotalAmount != widget.subtotalAmount ||
        oldWidget.businessId != widget.businessId) {
      if (_use && _points > 0) {
        _quote();
      } else {
        _emit();
      }
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getCustomerCheckoutPoints(widget.businessId);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _enabled = false;
      });
      _emit();
      return;
    }
    final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    if (raw is! Map) {
      setState(() {
        _loading = false;
        _enabled = false;
      });
      _emit();
      return;
    }
    final map = Map<String, dynamic>.from(raw);
    setState(() {
      _loading = false;
      _enabled = map['redemptionEnabled'] == true;
      _available = (map['availablePoints'] as num?)?.toInt() ?? 0;
      _min = (map['minPointsToRedeem'] as num?)?.toInt() ?? 50;
      _max = (map['maxPointsPerOrder'] as num?)?.toInt() ?? 0;
      _rate = (map['effectiveCurrencyPerPoint'] as num?)?.toDouble() ?? 0;
    });
    _emit();
  }

  int get _cap {
    var cap = _available;
    if (_max > 0 && _max < cap) cap = _max;
    if (_rate > 0) {
      final byOrder = (widget.subtotalAmount / _rate).floor();
      if (byOrder < cap) cap = byOrder;
    }
    return cap < 0 ? 0 : cap;
  }

  void _emit() {
    final use = _use && _points > 0;
    final payable =
        (widget.subtotalAmount - (use ? _discount : 0)).clamp(0.0, double.infinity);
    final valid = !_use || (_error == null && _points > 0 && _discount > 0);
    widget.onChanged(
      CheckoutPointsSelection(
        usePoints: use,
        pointsToRedeem: use ? _points : 0,
        discountAmount: use ? _discount : 0,
        payableAmount: payable.toDouble(),
        valid: valid || !_use,
        error: _use ? _error : null,
      ),
    );
  }

  Future<void> _quote() async {
    if (!_use) {
      setState(() {
        _discount = 0;
        _error = null;
      });
      _emit();
      return;
    }
    final pts = int.tryParse(_inputCtrl.text.trim()) ?? _points;
    setState(() {
      _points = pts;
      _quoting = true;
      _error = null;
    });
    if (pts <= 0) {
      setState(() {
        _quoting = false;
        _discount = 0;
        _error = 'Enter points to redeem';
      });
      _emit();
      return;
    }
    final res = await _repo.quoteRedemption(
      businessId: widget.businessId,
      subtotalAmount: widget.subtotalAmount,
      pointsToRedeem: pts,
    );
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _quoting = false;
        _discount = 0;
        _error = res.message ?? 'Cannot redeem these points';
      });
      _emit();
      return;
    }
    final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    setState(() {
      _quoting = false;
      _points = (map['pointsApplied'] as num?)?.toInt() ?? pts;
      _discount = (map['discountAmount'] as num?)?.toDouble() ?? 0;
      _error = null;
      _inputCtrl.text = '$_points';
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          ),
        ),
      );
    }
    if (!_enabled || _available <= 0) {
      return const SizedBox.shrink();
    }

    final m = AuthScale.of(context);
    final money = formatMoney(_discount, currency: widget.currency);
    final payable = formatMoney(
      (widget.subtotalAmount - (_use ? _discount : 0)).clamp(0.0, double.infinity),
      currency: widget.currency,
    );

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
                  'Loyalty points',
                  style: WaUi.toolsTitleOf(
                    size: m.s(15).clamp(13.0, 16.0),
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _use,
                activeColor: Colors.black,
                onChanged: (v) async {
                  setState(() {
                    _use = v;
                    if (v && _points <= 0) {
                      _points = _cap >= _min ? _cap : 0;
                      _inputCtrl.text = '$_points';
                    }
                    if (!v) {
                      _points = 0;
                      _discount = 0;
                      _error = null;
                      _inputCtrl.text = '0';
                    }
                  });
                  if (v) {
                    await _quote();
                  } else {
                    _emit();
                  }
                },
              ),
            ],
          ),
          Text(
            'Available: ${_available.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} pts',
            style: WaUi.body.copyWith(
              fontSize: m.s(12).clamp(11.0, 13.0),
              color: BarqodyChrome.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_use) ...[
            SizedBox(height: m.v(10)),
            TextField(
              controller: _inputCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                _points = int.tryParse(_inputCtrl.text.trim()) ?? 0;
              },
              onEditingComplete: _quote,
              onSubmitted: (_) => _quote(),
              decoration: InputDecoration(
                labelText: 'Points to redeem',
                hintText: 'Min $_min${_max > 0 ? ' · max $_max' : ''}',
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
            SizedBox(height: m.v(8)),
            if (_quoting)
              Text(
                'Calculating…',
                style: WaUi.body.copyWith(
                  fontSize: 12,
                  color: BarqodyChrome.secondaryText,
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: WaUi.body.copyWith(
                  fontSize: 12,
                  color: const Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (_discount > 0)
              Text(
                '$_points pts → $money off · Payable $payable',
                style: WaUi.body.copyWith(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

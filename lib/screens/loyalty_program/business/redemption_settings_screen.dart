import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/repository/loyalty_points_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// P2 — business owner configures points redemption rules.
class RedemptionSettingsScreen extends StatefulWidget {
  const RedemptionSettingsScreen({super.key});

  @override
  State<RedemptionSettingsScreen> createState() =>
      _RedemptionSettingsScreenState();
}

class _RedemptionSettingsScreenState extends State<RedemptionSettingsScreen> {
  final _repo = LoyaltyPointsRepo();
  final _minCtrl = TextEditingController(text: '50');
  final _maxCtrl = TextEditingController(text: '0');
  final _rateCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  String _currency = 'PKR';
  double? _effectiveRate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getBusinessRedemptionSettings();
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load settings';
      });
      return;
    }
    final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final custom = map['currencyPerPoint'];
    setState(() {
      _loading = false;
      _enabled = map['redemptionEnabled'] == true;
      _minCtrl.text = '${(map['minPointsToRedeem'] as num?)?.toInt() ?? 50}';
      _maxCtrl.text = '${(map['maxPointsPerOrder'] as num?)?.toInt() ?? 0}';
      _currency = (map['currency']?.toString().isNotEmpty ?? false)
          ? map['currency'].toString().toUpperCase()
          : 'PKR';
      _effectiveRate =
          (map['effectiveCurrencyPerPoint'] as num?)?.toDouble();
      if (custom != null && custom is num && custom > 0) {
        _rateCtrl.text = custom.toString();
      } else {
        _rateCtrl.clear();
      }
    });
  }

  Future<void> _save() async {
    final min = int.tryParse(_minCtrl.text.trim()) ?? 0;
    final max = int.tryParse(_maxCtrl.text.trim()) ?? 0;
    if (min < 1) {
      setState(() => _error = 'Minimum points must be at least 1');
      return;
    }
    if (max < 0) {
      setState(() => _error = 'Maximum must be 0 (unlimited) or higher');
      return;
    }
    if (max > 0 && max < min) {
      setState(() => _error = 'Maximum cannot be below minimum');
      return;
    }
    final rateText = _rateCtrl.text.trim();
    double? rate;
    var clearRate = false;
    if (rateText.isEmpty) {
      clearRate = true;
    } else {
      rate = double.tryParse(rateText);
      if (rate == null || rate < 0) {
        setState(() => _error = 'Enter a valid conversion rate or leave blank');
        return;
      }
      if (rate == 0) clearRate = true;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final res = await _repo.updateBusinessRedemptionSettings(
      redemptionEnabled: _enabled,
      minPointsToRedeem: min,
      maxPointsPerOrder: max,
      currencyPerPoint: clearRate ? null : rate,
      clearCurrencyPerPoint: clearRate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      setState(() => _error = res.message ?? 'Save failed');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redemption settings saved')),
    );
    await _load();
  }

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.2);

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Redemption Settings'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(side, m.v(8), side, m.v(24)),
                      children: [
                        Text(
                          'Control how customers redeem points at checkout.',
                          style: WaUi.body.copyWith(
                            fontSize: _font(m, 14),
                            color: BarqodyChrome.secondaryText,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: m.v(20)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: m.s(14),
                            vertical: m.v(6),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Enable points redemption',
                              style: WaUi.toolsTitleOf(
                                size: _font(m, 15),
                                weight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              _enabled
                                  ? 'Customers can redeem during checkout'
                                  : 'Redemption is off for all checkouts',
                              style: WaUi.body.copyWith(
                                fontSize: 12,
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                            value: _enabled,
                            activeColor: Colors.black,
                            onChanged: (v) => setState(() => _enabled = v),
                          ),
                        ),
                        SizedBox(height: m.v(18)),
                        _field(
                          label: 'Minimum points to redeem',
                          controller: _minCtrl,
                          hint: 'e.g. 50',
                        ),
                        SizedBox(height: m.v(14)),
                        _field(
                          label: 'Maximum points per order',
                          controller: _maxCtrl,
                          hint: '0 = no max',
                        ),
                        SizedBox(height: m.v(14)),
                        _field(
                          label: '$_currency per point (optional)',
                          controller: _rateCtrl,
                          hint: _effectiveRate != null
                              ? 'Default ≈ ${_effectiveRate!.toStringAsFixed(4)} $_currency'
                              : 'Leave blank for USD-cent parity',
                          decimal: true,
                        ),
                        SizedBox(height: m.v(8)),
                        Text(
                          'Blank uses 1 point = 1 US cent, converted to $_currency. '
                          'Override to set an exact $_currency discount per point.',
                          style: WaUi.body.copyWith(
                            fontSize: 12,
                            color: BarqodyChrome.secondaryText,
                            height: 1.35,
                          ),
                        ),
                        if (_error != null) ...[
                          SizedBox(height: m.v(12)),
                          Text(
                            _error!,
                            style: WaUi.body.copyWith(
                              fontSize: 13,
                              color: const Color(0xFFD32F2F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 16),
              child: PillButton(
                label: _saving ? 'Saving…' : 'Save settings',
                onPressed: _save,
                enabled: !_saving && !_loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: WaUi.body.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.85,
            color: const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ],
    );
  }
}

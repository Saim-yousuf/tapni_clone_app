import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/widgets/app_toast.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

/// Pickup/delivery rules, fees, tips, schedule for menu sites.
class BusinessWebsiteOrderingScreen extends StatefulWidget {
  final BusinessWebsite website;

  const BusinessWebsiteOrderingScreen({super.key, required this.website});

  @override
  State<BusinessWebsiteOrderingScreen> createState() =>
      _BusinessWebsiteOrderingScreenState();
}

class _BusinessWebsiteOrderingScreenState
    extends State<BusinessWebsiteOrderingScreen> {
  final _repo = BusinessWebsiteRepo();
  late bool _acceptPickup;
  late bool _acceptDelivery;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _freeAboveCtrl;
  late final TextEditingController _prepCtrl;
  late bool _tipsEnabled;
  late bool _scheduleEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.website.ordering;
    _acceptPickup = o.acceptPickup;
    _acceptDelivery = o.acceptDelivery;
    _minOrderCtrl = TextEditingController(
      text: o.minOrderAmount > 0 ? o.minOrderAmount.toStringAsFixed(0) : '',
    );
    _deliveryFeeCtrl = TextEditingController(
      text: o.deliveryFee > 0 ? o.deliveryFee.toStringAsFixed(0) : '',
    );
    _freeAboveCtrl = TextEditingController(
      text: o.freeDeliveryAbove > 0
          ? o.freeDeliveryAbove.toStringAsFixed(0)
          : '',
    );
    _prepCtrl = TextEditingController(
      text: o.prepTimeMinutes > 0 ? '${o.prepTimeMinutes}' : '',
    );
    _tipsEnabled = o.tipsEnabled;
    _scheduleEnabled = o.scheduleOrdersEnabled;
  }

  @override
  void dispose() {
    _minOrderCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _freeAboveCtrl.dispose();
    _prepCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    if (_saving) return;
    if (!_acceptPickup && !_acceptDelivery) {
      showAppToast(
        context,
        'Turn on pickup or delivery',
        kind: AppToastKind.warning,
      );
      return;
    }
    setState(() => _saving = true);
    final next = widget.website.ordering.copyWith(
      acceptPickup: _acceptPickup,
      acceptDelivery: _acceptDelivery,
      minOrderAmount: _num(_minOrderCtrl),
      deliveryFee: _num(_deliveryFeeCtrl),
      freeDeliveryAbove: _num(_freeAboveCtrl),
      prepTimeMinutes: int.tryParse(_prepCtrl.text.trim()) ?? 0,
      // Areas setting removed — clear so checkout never requires a zone chip.
      deliveryAreas: const [],
      tipsEnabled: _tipsEnabled,
      scheduleOrdersEnabled: _scheduleEnabled,
    );
    final res = await _repo.updateWebsite(
      {'ordering': next.toJson()},
      websiteId: widget.website.id,
      websiteType: widget.website.websiteType,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      showAppToast(
        context,
        res.message ?? 'Could not save ordering',
        kind: AppToastKind.error,
      );
      return;
    }
    final website = _repo.parseWebsite(res.data);
    showAppToast(context, 'Ordering saved', kind: AppToastKind.success);
    Navigator.pop(context, website ?? widget.website.copyWith(ordering: next));
  }

  @override
  Widget build(BuildContext context) {
    return BwPresenceScaffold(
      title: 'Ordering',
      bottom: BwBottomCta(
        label: 'Save ordering',
        loading: _saving,
        onPressed: _saving ? null : _save,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppAppear(
            index: 0,
            child: _card(
              children: [
                _switchRow(
                  title: 'Accept pickup',
                  subtitle: 'Customer collects the order',
                  value: _acceptPickup,
                  onChanged: (v) => setState(() => _acceptPickup = v),
                ),
                const Divider(height: 1, color: BwUi.cardBorder),
                _switchRow(
                  title: 'Accept delivery',
                  subtitle: 'You deliver to the customer',
                  value: _acceptDelivery,
                  onChanged: (v) => setState(() => _acceptDelivery = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppAppear(
            index: 1,
            child: _card(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Text(
                    'Order rules',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _numField(
                  controller: _minOrderCtrl,
                  label: 'Minimum order amount',
                  hint: '0 = no minimum',
                ),
                _numField(
                  controller: _deliveryFeeCtrl,
                  label: 'Delivery fee',
                  hint: '0 = free delivery',
                ),
                _numField(
                  controller: _freeAboveCtrl,
                  label: 'Free delivery above',
                  hint: '0 = never free from threshold',
                ),
                _numField(
                  controller: _prepCtrl,
                  label: 'Prep time (minutes)',
                  hint: 'Shown on the menu site',
                  integer: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppAppear(
            index: 2,
            child: _card(
              children: [
                _switchRow(
                  title: 'Tips',
                  subtitle: 'Let customers add a tip at checkout',
                  value: _tipsEnabled,
                  onChanged: (v) => setState(() => _tipsEnabled = v),
                ),
                const Divider(height: 1, color: BwUi.cardBorder),
                _switchRow(
                  title: 'Schedule orders',
                  subtitle:
                      'Customer can pick a later pickup/delivery time',
                  value: _scheduleEnabled,
                  onChanged: (v) => setState(() => _scheduleEnabled = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BwUi.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AuthUi.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: Colors.black,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool integer = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          if (integer)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AuthUi.fieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

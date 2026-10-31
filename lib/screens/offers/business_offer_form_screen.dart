import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_offer.dart';
import 'package:tapni_app/repository/offer_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class BusinessOfferFormScreen extends StatefulWidget {
  final BusinessOffer? existing;

  const BusinessOfferFormScreen({super.key, this.existing});

  @override
  State<BusinessOfferFormScreen> createState() =>
      _BusinessOfferFormScreenState();
}

class _BusinessOfferFormScreenState extends State<BusinessOfferFormScreen> {
  final _repo = OfferRepo();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minCtrl = TextEditingController(text: '0');
  final _maxDiscCtrl = TextEditingController(text: '0');
  final _totalLimitCtrl = TextEditingController(text: '0');
  final _perCustCtrl = TextEditingController(text: '1');
  final _categoriesCtrl = TextEditingController();
  final _itemIdsCtrl = TextEditingController();

  String _discountType = 'percentage';
  bool _isActive = true;
  bool _allowWithPoints = true;
  bool _allowGuests = true;
  final Set<String> _catalogTypes = {};
  DateTime? _startsAt;
  DateTime? _expiresAt;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existing;
    if (o == null) return;
    _titleCtrl.text = o.title;
    _descCtrl.text = o.description;
    _codeCtrl.text = o.code;
    _discountType = o.discountType;
    _valueCtrl.text = o.discountValue.toString();
    _minCtrl.text = o.minOrderAmount.toString();
    _maxDiscCtrl.text = o.maxDiscountAmount.toString();
    _totalLimitCtrl.text = o.totalUsageLimit.toString();
    _perCustCtrl.text = o.perCustomerLimit.toString();
    _categoriesCtrl.text = o.applicableCategories.join(', ');
    _itemIdsCtrl.text = o.applicableItemIds.join(', ');
    _catalogTypes.addAll(o.catalogTypes);
    _isActive = o.isActive;
    _allowWithPoints = o.allowWithPoints;
    _allowGuests = o.allowGuests;
    _startsAt = o.startsAt;
    _expiresAt = o.expiresAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minCtrl.dispose();
    _maxDiscCtrl.dispose();
    _totalLimitCtrl.dispose();
    _perCustCtrl.dispose();
    _categoriesCtrl.dispose();
    _itemIdsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _startsAt : _expiresAt) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startsAt = DateTime(picked.year, picked.month, picked.day);
      } else {
        _expiresAt =
            DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  List<String> _splitCsv(String raw) => raw
      .split(RegExp(r'[,;\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final value = double.tryParse(_valueCtrl.text.trim()) ?? 0;
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    if (value <= 0) {
      setState(() => _error = 'Discount value must be greater than 0');
      return;
    }
    if (_discountType == 'percentage' && value > 100) {
      setState(() => _error = 'Percentage cannot exceed 100');
      return;
    }
    if (_startsAt != null &&
        _expiresAt != null &&
        _expiresAt!.isBefore(_startsAt!)) {
      setState(() => _error = 'Expiry must be after start date');
      return;
    }

    final body = <String, dynamic>{
      'title': title,
      'description': _descCtrl.text.trim(),
      'code': _codeCtrl.text.trim().toUpperCase(),
      'discountType': _discountType,
      'discountValue': value,
      // UTC ISO so Node Date parsing is timezone-stable across hosts.
      'startsAt': _startsAt?.toUtc().toIso8601String(),
      'expiresAt': _expiresAt?.toUtc().toIso8601String(),
      'minOrderAmount': double.tryParse(_minCtrl.text.trim()) ?? 0,
      'maxDiscountAmount': double.tryParse(_maxDiscCtrl.text.trim()) ?? 0,
      'totalUsageLimit': int.tryParse(_totalLimitCtrl.text.trim()) ?? 0,
      'perCustomerLimit': int.tryParse(_perCustCtrl.text.trim()) ?? 1,
      'catalogTypes': _catalogTypes.toList(),
      'applicableCategories': _splitCsv(_categoriesCtrl.text),
      'applicableItemIds': _splitCsv(_itemIdsCtrl.text),
      'isActive': _isActive,
      'allowWithPoints': _allowWithPoints,
      'allowGuests': _allowGuests,
    };

    setState(() {
      _saving = true;
      _error = null;
    });
    final res = _isEdit
        ? await _repo.updateOffer(widget.existing!.id, body)
        : await _repo.createOffer(body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      setState(() => _error = res.message ?? 'Save failed');
      return;
    }
    Navigator.of(context).pop(true);
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: _isEdit ? 'Edit offer' : 'New offer'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: WaUi.body.copyWith(
                          color: const Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _field('Title', _titleCtrl),
                  _field('Description', _descCtrl, maxLines: 3),
                  _field(
                    'Coupon code (optional)',
                    _codeCtrl,
                    hint: 'Leave empty for auto / browse-to-apply',
                  ),
                  Text(
                    'Discount type',
                    style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'percentage',
                        label: Text('%'),
                      ),
                      ButtonSegment(
                        value: 'fixed',
                        label: Text('Fixed'),
                      ),
                    ],
                    selected: {_discountType},
                    onSelectionChanged: (s) {
                      setState(() => _discountType = s.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _discountType == 'percentage'
                        ? 'Percentage'
                        : 'Fixed amount',
                    _valueCtrl,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _field(
                    'Minimum order',
                    _minCtrl,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _field(
                    'Max discount (0 = none)',
                    _maxDiscCtrl,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _field(
                    'Total usage limit (0 = unlimited)',
                    _totalLimitCtrl,
                    keyboard: TextInputType.number,
                  ),
                  _field(
                    'Per-customer limit (0 = unlimited)',
                    _perCustCtrl,
                    keyboard: TextInputType.number,
                  ),
                  Text(
                    'Catalog types (empty = all)',
                    style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['menu', 'products', 'services'].map((t) {
                      final selected = _catalogTypes.contains(t);
                      return FilterChip(
                        label: Text(t),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _catalogTypes.add(t);
                            } else {
                              _catalogTypes.remove(t);
                            }
                          });
                        },
                        selectedColor: Colors.black,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'Categories (comma-separated)',
                    _categoriesCtrl,
                    hint: 'Empty = all categories',
                  ),
                  _field(
                    'Catalog item IDs (comma-separated)',
                    _itemIdsCtrl,
                    hint: 'Stable item _id only — empty = all items',
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(_fmt(_startsAt)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_startsAt != null)
                          IconButton(
                            onPressed: () => setState(() => _startsAt = null),
                            icon: const Icon(Icons.clear),
                          ),
                        IconButton(
                          onPressed: () => _pickDate(start: true),
                          icon: const Icon(Icons.calendar_today_outlined),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry date'),
                    subtitle: Text(_fmt(_expiresAt)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_expiresAt != null)
                          IconButton(
                            onPressed: () => setState(() => _expiresAt = null),
                            icon: const Icon(Icons.clear),
                          ),
                        IconButton(
                          onPressed: () => _pickDate(start: false),
                          icon: const Icon(Icons.calendar_today_outlined),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: _isActive,
                    activeColor: Colors.black,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow with loyalty points'),
                    subtitle: const Text(
                      'Points apply after coupon on remaining total',
                    ),
                    value: _allowWithPoints,
                    activeColor: Colors.black,
                    onChanged: (v) => setState(() => _allowWithPoints = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow guests'),
                    subtitle: const Text('Public website guests can use'),
                    value: _allowGuests,
                    activeColor: Colors.black,
                    onChanged: (v) => setState(() => _allowGuests = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: WaUi.primaryButtonHeight,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Save changes' : 'Create offer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

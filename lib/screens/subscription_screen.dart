import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/utils/business_categories.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/radio_option_picker_sheet.dart';

class SubscriptionScreen extends StatefulWidget {
  SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _cardBg = Color(0xFFF2F2F7);
  static const _muted = Color(0xFF8E8E93);
  static const _bodyGrey = Color(0xFF707070);
  static const _border = Color(0xFFE8E8E8);

  /// Design prices (SAR). Overridden when API plans provide prices.
  static const _yearlyPrice = 99.99;
  static const _yearlySubtotal = 119.99;
  static const _monthlyPrice = 9.99;

  bool _isYearlySelected = true;
  final _transactionController = TextEditingController();
  String _receiptBase64 = '';

  /// 0 = Business Details, 1 = Plan, 2 = Payment
  int _step = 0;
  final _businessNameController = TextEditingController();
  String? _selectedCategory;
  bool _isSavingBusinessData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      _businessNameController.text =
          profileProvider.profile.businessName ?? '';
      if (kBusinessCategories
          .contains(profileProvider.profile.businessCategory)) {
        _selectedCategory = profileProvider.profile.businessCategory;
      }
      provider.fetchPlans();
      provider.checkSubscriptionStatus();
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final fromApi = _planPriceFromApi();
    if (fromApi != null) return fromApi;
    return _isYearlySelected ? _yearlyPrice : _monthlyPrice;
  }

  double get _subtotal {
    if (!_isYearlySelected) return _totalAmount;
    final fromApi = _planPriceFromApi();
    if (fromApi != null) {
      // Infer list price from 20% savings when API only returns final price.
      return double.parse((fromApi / 0.8).toStringAsFixed(2));
    }
    return _yearlySubtotal;
  }

  double get _discount {
    if (!_isYearlySelected) return 0;
    return double.parse((_subtotal - _totalAmount).toStringAsFixed(2));
  }

  double? _planPriceFromApi() {
    final plans =
        Provider.of<SubscriptionProvider>(context, listen: false).plans;
    if (plans.isEmpty) return null;
    final id = _isYearlySelected ? 'yearly' : 'monthly';
    for (final p in plans) {
      final matchId = p.id.toLowerCase() == id;
      final matchName = p.name.toLowerCase().contains(id);
      if ((matchId || matchName) && p.price > 0) return p.price;
    }
    return null;
  }

  String get _planLabel => _isYearlySelected ? 'Yearly' : 'Monthly';

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Future<void> _submitRequest() async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    final planId = _isYearlySelected ? 'yearly' : 'monthly';
    final success = await provider.subscribe(
      planId,
      context,
      transactionRef: _transactionController.text.trim(),
      paymentReceipt: _receiptBase64,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.subscriptionRequestSubmitted2)),
      );
    }
  }

  Future<void> _handleNext() async {
    final name = _businessNameController.text.trim();
    if (name.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterBusinessDetailsToContinue),
        ),
      );
      return;
    }

    setState(() => _isSavingBusinessData = true);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;

    final response = await profileProvider.updateProfile(
      name: profile.name,
      designation: profile.designation,
      company: profile.company,
      bio: profile.bio,
      phone: profile.phone,
      email: profile.email,
      website: profile.website,
      country: profile.country,
      businessName: name,
      businessCategory: _selectedCategory,
      links: profile.socialLinks,
      context: context,
    );

    if (!mounted) return;
    setState(() => _isSavingBusinessData = false);

    if (response.success) {
      setState(() => _step = 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? context.l10n.failedToSaveBusinessDetails,
          ),
        ),
      );
    }
  }

  Future<void> _pickReceipt() async {
    final file = await pickFile();
    if (file?.file == null) return;
    _receiptBase64 = await fileToBase64(File(file!.file!.path));
    setState(() {});
  }

  Future<void> _openAddPaymentMethod() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: 'Add Payment Method',
                onBack: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
              _bankPanel(),
              const SizedBox(height: 14),
              TextField(
                controller: _transactionController,
                decoration: WaUi.fieldDecoration(
                  labelText:
                      context.l10n.transactionReferenceNumberOptional,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await _pickReceipt();
                  if (ctx.mounted) setState(() {});
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  _receiptBase64.isEmpty
                      ? context.l10n.uploadReceiptOptional
                      : context.l10n.receiptAttached,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Done',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  String get _titleBarLabel {
    switch (_step) {
      case 1:
        return 'Plan';
      case 2:
        return 'Payment';
      default:
        return context.l10n.subscription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final subscription = provider.currentSubscription;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: _titleBarLabel,
              onBack: () {
                if (_step > 0 &&
                    subscription?.isRequested != true &&
                    subscription?.isActive != true) {
                  setState(() => _step -= 1);
                  return;
                }
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: subscription?.isRequested == true
                  ? _StatusView(
                      title: context.l10n.requestPending,
                      text: context.l10n.subscriptionRequestSubmittedOn(
                        subscription!.planName,
                      ),
                    )
                  : subscription?.isRejected == true
                      ? _StatusView(
                          title: context.l10n.requestRejected,
                          text:
                              '${subscription!.rejectionReason.isEmpty ? context.l10n.noReasonProvided : subscription.rejectionReason}\nYou can submit a new request below.',
                          actionLabel: 'Choose Plan',
                          onAction: () => setState(() => _step = 1),
                        )
                      : subscription?.isActive == true
                          ? _StatusView(
                              title: context.l10n.premiumActive,
                              text:
                                  '${subscription!.planName} is active until ${_date(subscription.endDate)}. Cancel your current subscription before buying another plan.',
                            )
                          : _step == 0
                              ? _buildBusinessDetailsStep()
                              : _step == 1
                                  ? _buildPlanSelectionStep()
                                  : _buildPaymentStep(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BarqodyChrome.sidePad,
        16,
        BarqodyChrome.sidePad,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.businessDetails,
            style: WaUi.toolsTitleOf(
              size: 24,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.pleaseProvideYourBusinessDetailsBeforeUpgrading,
            style: WaUi.body.copyWith(fontSize: 14, color: _muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _businessNameController,
            decoration: WaUi.fieldDecoration(
              labelText: context.l10n.businessName,
            ),
          ),
          const SizedBox(height: 16),
          RadioPickerField(
            labelText: context.l10n.businessCategory,
            valueText: _selectedCategory == null
                ? null
                : businessCategoryLabel(context, _selectedCategory!),
            onTap: _pickBusinessCategory,
          ),
          const SizedBox(height: 28),
          PillButton(
            label: _isSavingBusinessData ? '…' : context.l10n.next,
            enabled: !_isSavingBusinessData,
            onPressed: _handleNext,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionStep() {
    final price = _totalAmount;
    final period = _isYearlySelected ? '/Yearly' : '/Monthly';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BarqodyChrome.sidePad,
              20,
              BarqodyChrome.sidePad,
              16,
            ),
            child: Column(
              children: [
                Text(
                  'Choose Your Plan',
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 26,
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock your Business Profile and all business features.',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: _muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                _PlanToggle(
                  isYearly: _isYearlySelected,
                  onChanged: (yearly) {
                    HapticFeedback.selectionClick();
                    setState(() => _isYearlySelected = yearly);
                  },
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Business Profile',
                                  style: WaUi.bodyMedium.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'SAR ${_money(price)}',
                                        style: WaUi.toolsTitleOf(
                                          size: 28,
                                          weight: FontWeight.w700,
                                          color: Colors.black,
                                          height: 1.1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' $period',
                                        style: WaUi.body.copyWith(
                                          fontSize: 14,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/images/png/star-icon.png',
                            width: 52,
                            height: 52,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.workspace_premium_rounded,
                              size: 48,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _FeatureRow(label: 'Professional business profile'),
                      const SizedBox(height: 12),
                      const _FeatureRow(label: 'Customer Rewards'),
                      const SizedBox(height: 12),
                      const _FeatureRow(label: 'Team Management'),
                      const SizedBox(height: 12),
                      const _FeatureRow(label: 'Top Performing Links'),
                      const SizedBox(height: 12),
                      const _FeatureRow(label: 'Advanced Analytics'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BarqodyChrome.sidePad,
            8,
            BarqodyChrome.sidePad,
            16,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: PillButton(
              label: 'Continue to Payment',
              onPressed: () => setState(() => _step = 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(SubscriptionProvider provider) {
    final total = _totalAmount;
    final subtotal = _subtotal;
    final discount = _discount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BarqodyChrome.sidePad,
              16,
              BarqodyChrome.sidePad,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Complete your payment',
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 24,
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activate your business profile to get started',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(fontSize: 14, color: _muted),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Profile',
                              style: WaUi.bodyMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selected: $_planLabel',
                              style: WaUi.caption.copyWith(
                                fontSize: 13,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Sar ${_money(total)}',
                        style: WaUi.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Payment Method',
                      style: WaUi.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openAddPaymentMethod,
                      child: Text(
                        '+ Add Payment Method',
                        style: WaUi.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visa',
                        style: WaUi.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• 4242',
                        style: WaUi.caption.copyWith(
                          fontSize: 13,
                          color: _muted,
                        ),
                      ),
                      if (_transactionController.text.trim().isNotEmpty ||
                          _receiptBase64.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          [
                            if (_transactionController.text.trim().isNotEmpty)
                              'Ref: ${_transactionController.text.trim()}',
                            if (_receiptBase64.isNotEmpty) 'Receipt attached',
                          ].join(' · '),
                          style: WaUi.caption.copyWith(
                            fontSize: 12,
                            color: _bodyGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _PriceRow(
                  label: 'Subtotal',
                  value: 'SAR ${_money(subtotal)}',
                ),
                const SizedBox(height: 12),
                _PriceRow(
                  label: 'Discount',
                  value: 'SAR ${_money(discount)}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, thickness: 1, color: _border),
                ),
                _PriceRow(
                  label: 'Total amount',
                  value: 'Sar ${_money(total)}',
                  boldValue: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BarqodyChrome.sidePad,
            8,
            BarqodyChrome.sidePad,
            16,
          ),
          child: PillButton(
            label: provider.isLoading
                ? '…'
                : 'Pay SAR ${_money(total)}',
            enabled: !provider.isLoading,
            onPressed: _submitRequest,
          ),
        ),
      ],
    );
  }

  Widget _bankPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.bankAccount,
            style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.accountTitleTapni, style: WaUi.body),
          Text(context.l10n.bankAddBankNameHere, style: WaUi.body),
          Text(context.l10n.accountIBANAddAccountNumberHere, style: WaUi.body),
        ],
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '--';
    return '${value.day}/${value.month}/${value.year}';
  }

  Future<void> _pickBusinessCategory() async {
    final selected = await showRadioOptionPickerSheet(
      context: context,
      options: [
        for (final category in kBusinessCategories)
          RadioPickerOption(
            id: category,
            label: businessCategoryLabel(context, category),
          ),
      ],
      selectedId: _selectedCategory,
      searchHint: context.l10n.searchCategory,
      helperText: context.l10n.selectCategoryHelper,
      emptyText: context.l10n.noCategoriesFound,
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedCategory = selected);
  }
}

class _PlanToggle extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onChanged;

  const _PlanToggle({
    required this.isYearly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(false),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isYearly ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Monthly',
                          style: WaUi.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: !isYearly
                                ? Colors.white
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(true),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isYearly ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Yearly',
                          style: WaUi.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isYearly
                                ? Colors.white
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isYearly)
            Positioned(
              top: -10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Save 20%',
                  style: WaUi.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;

  const _FeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/images/png/check-icon-1.png',
              width: 11,
              height: 11,
              color: Colors.white,
              errorBuilder: (_, _, _) => const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: const Color(0xFF707070),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;

  const _PriceRow({
    required this.label,
    required this.value,
    this.boldValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ),
        Text(
          value,
          style: boldValue
              ? WaUi.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                )
              : WaUi.body.copyWith(
                  fontSize: 14,
                  color: Colors.black,
                ),
        ),
      ],
    );
  }
}

class _StatusView extends StatelessWidget {
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusView({
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BarqodyChrome.sidePad,
        24,
        BarqodyChrome.sidePad,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WaUi.toolsTitleOf(
                    size: 20,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: BarqodyChrome.bodyText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const Spacer(),
            PillButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

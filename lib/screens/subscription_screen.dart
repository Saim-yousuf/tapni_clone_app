import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/screens/quick_add_links_screen.dart';
import 'package:tapni_app/screens/subscription_purchased_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_option_grid.dart';

class SubscriptionScreen extends StatefulWidget {
  SubscriptionScreen({
    Key? key,
    this.fromRegistration = false,
  }) : super(key: key);

  /// Business account signup — payment required before onboarding continues.
  final bool fromRegistration;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _cardBg = Color(0xFFF2F2F7);
  static const _muted = Color(0xFF8E8E93);
  static const _border = Color(0xFFE8E8E8);

  /// Design prices (SAR). Overridden when API plans provide prices.
  static const _yearlyPrice = 99.99;
  static const _yearlySubtotal = 119.99;
  static const _monthlyPrice = 9.99;

  bool _isYearlySelected = true;

  /// Local mock card (never sent to backend).
  String? _cardBrand;
  String? _cardLast4;

  /// 0 = Concern, 1 = Category, 2 = Plan, 3 = Payment
  int _step = 0;
  String? _selectedConcernId;
  String? _selectedCategory;
  bool _isSavingBusinessData = false;
  bool _loadingCategories = false;
  List<ExploreCategoryItem> _categories = [];

  static const _concernOptions = <BusinessOptionItem>[
    BusinessOptionItem(
      id: 'more_customers',
      label: 'More customers',
      emoji: '📈',
    ),
    BusinessOptionItem(
      id: 'digital_card',
      label: 'Digital card',
      emoji: '💳',
    ),
    BusinessOptionItem(
      id: 'loyalty_rewards',
      label: 'Loyalty rewards',
      emoji: '🎁',
    ),
    BusinessOptionItem(
      id: 'showcase_catalog',
      label: 'Menu & catalog',
      emoji: '📋',
    ),
    BusinessOptionItem(
      id: 'team_management',
      label: 'Team tools',
      emoji: '👥',
    ),
    BusinessOptionItem(
      id: 'analytics',
      label: 'Analytics',
      emoji: '📊',
    ),
    BusinessOptionItem(
      id: 'online_presence',
      label: 'Online presence',
      emoji: '🌐',
    ),
    BusinessOptionItem(
      id: 'other',
      label: 'Other',
      emoji: '✨',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final concern = profileProvider.profile.businessConcern;
      if (concern != null && concern.isNotEmpty) {
        _selectedConcernId = concern;
      }
      final cat = profileProvider.profile.businessCategory;
      if (cat != null && cat.isNotEmpty) {
        _selectedCategory = cat;
      }
      provider.fetchPlans();
      provider.checkSubscriptionStatus();
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final repo = ExploreRepo();
    final response = await repo.getCategories();
    if (!mounted) return;
    if (response.success) {
      _categories = repo.parseCategories(response.data);
    }
    setState(() => _loadingCategories = false);
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

  Future<void> _pay() async {
    if (_cardLast4 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a payment method')),
      );
      return;
    }

    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final planId = _isYearlySelected ? 'yearly' : 'monthly';
    final amount = _totalAmount;
    final success = await provider.pay(planId: planId, context: context);

    if (!success || !mounted) return;

    // Unlock Pro gates immediately (profile.isPro + isProUser), then refresh.
    profileProvider.upgradeToPro();
    await profileProvider.fetchProfile();
    if (!mounted) return;

    final sub = provider.currentSubscription;

    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (_) => SubscriptionPurchasedScreen(
          planName: sub?.planName ??
              (_isYearlySelected ? 'Yearly Plan' : 'Monthly Plan'),
          planLabel: _planLabel,
          amount: sub?.amount != null && sub!.amount > 0 ? sub.amount : amount,
          currency: sub?.currency.isNotEmpty == true ? sub!.currency : 'SAR',
          transactionId: sub?.providerPaymentId.isNotEmpty == true
              ? sub!.providerPaymentId
              : (sub?.checkoutId ?? ''),
          startDate: sub?.startDate,
          endDate: sub?.endDate,
          fromRegistration: widget.fromRegistration,
        ),
      ),
    );
  }

  Future<void> _saveOnboardingAndGoToPlan() async {
    if (_selectedConcernId == null || _selectedCategory == null) return;

    setState(() => _isSavingBusinessData = true);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    final displayName = (profile.businessName?.trim().isNotEmpty == true)
        ? profile.businessName!.trim()
        : profile.name;

    final response = await profileProvider.updateProfile(
      name: profile.name,
      designation: profile.designation,
      company: profile.company,
      bio: profile.bio,
      phone: profile.phone,
      email: profile.email,
      website: profile.website,
      country: profile.country,
      businessName: displayName,
      businessCategory: _selectedCategory,
      businessConcern: _selectedConcernId,
      links: profile.socialLinks,
      context: context,
    );

    if (!mounted) return;
    setState(() => _isSavingBusinessData = false);

    if (response.success) {
      setState(() => _step = 2);
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

  Future<void> _openAddPaymentMethod() async {
    final result = await showModalBottomSheet<_SavedCardPreview>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _AddPaymentMethodSheet(),
    );

    if (!mounted || result == null) return;
    setState(() {
      _cardLast4 = result.last4;
      _cardBrand = result.brand;
    });
  }

  String get _titleBarLabel {
    switch (_step) {
      case 2:
        return 'Plan';
      case 3:
        return 'Payment';
      default:
        return context.l10n.subscription;
    }
  }

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'devices_rounded':
        return Icons.devices_rounded;
      case 'shopping_bag_rounded':
        return Icons.shopping_bag_rounded;
      case 'spa_rounded':
        return Icons.spa_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'account_balance_rounded':
        return Icons.account_balance_rounded;
      case 'home_work_rounded':
        return Icons.home_work_rounded;
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'movie_rounded':
        return Icons.movie_rounded;
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'checkroom_rounded':
        return Icons.checkroom_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _onBack(bool isActive) {
    if (_step > 0 && !isActive) {
      setState(() => _step -= 1);
      return;
    }
    if (widget.fromRegistration && !isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete payment to activate your Business profile.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final subscription = provider.currentSubscription;
    final isActive = subscription?.isActive == true;

    return PopScope(
      canPop: !widget.fromRegistration || isActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack(isActive);
      },
      child: Scaffold(
        backgroundColor: BarqodyChrome.scaffold,
        body: SafeArea(
          child: isActive
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BarqodyTitleBar(
                      title: _titleBarLabel,
                      onBack: () => _onBack(isActive),
                    ),
                    Expanded(
                      child: _StatusView(
                        title: context.l10n.premiumActive,
                        text: widget.fromRegistration
                            ? '${subscription!.planName} is active. Continue to finish setting up your profile.'
                            : '${subscription!.planName} is active until ${_date(subscription.endDate)}. Cancel your current subscription before buying another plan.',
                        actionLabel: widget.fromRegistration
                            ? context.l10n.continueLabel
                            : null,
                        onAction: widget.fromRegistration
                            ? () async {
                                final profileProvider =
                                    Provider.of<ProfileProvider>(
                                  context,
                                  listen: false,
                                );
                                await profileProvider.fetchProfile();
                                if (!mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  AppPageRoute(
                                    builder: (_) =>
                                        const QuickAddLinksScreen(),
                                  ),
                                  (_) => false,
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                )
              : subscription?.isPendingPayment == true
                  ? Column(
                      children: [
                        BarqodyTitleBar(
                          title: 'Payment',
                          onBack: () => _onBack(false),
                        ),
                        Expanded(
                          child: _StatusView(
                            title: 'Payment pending',
                            text:
                                'Complete payment for ${subscription!.planName} to activate Premium.',
                            actionLabel: 'Continue to Payment',
                            onAction: () => setState(() => _step = 3),
                          ),
                        ),
                      ],
                    )
                  : subscription?.isFailed == true
                      ? Column(
                          children: [
                            BarqodyTitleBar(
                              title: 'Payment',
                              onBack: () => _onBack(false),
                            ),
                            Expanded(
                              child: _StatusView(
                                title: 'Payment failed',
                                text:
                                    'Your last payment did not go through. Try again with a different card.',
                                actionLabel: 'Choose Plan',
                                onAction: () => setState(() => _step = 2),
                              ),
                            ),
                          ],
                        )
                      : _step == 0
                          ? _buildConcernStep()
                          : _step == 1
                              ? _buildCategoryStep()
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    BarqodyTitleBar(
                                      title: _titleBarLabel,
                                      onBack: () => _onBack(false),
                                    ),
                                    Expanded(
                                      child: _step == 2
                                          ? _buildPlanSelectionStep()
                                          : _buildPaymentStep(provider),
                                    ),
                                  ],
                                ),
        ),
      ),
    );
  }

  Widget _buildConcernStep() {
    return BusinessOptionPickerPage(
      title: 'Your goal',
      question: 'What brings you to Business?',
      subtitle: 'Pick the option that fits you best',
      options: _concernOptions,
      selectedId: _selectedConcernId,
      stepIndex: 0,
      totalSteps: 2,
      childAspectRatio: 1.28,
      iconBoxSize: 64,
      emojiSize: 34,
      iconSize: 32,
      cardPadding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      labelFontSize: 13,
      onBack: () => _onBack(false),
      onSelect: (id) => setState(() => _selectedConcernId = id),
      onContinue: _selectedConcernId == null
          ? null
          : () => setState(() => _step = 1),
    );
  }

  Widget _buildCategoryStep() {
    final options = _categories
        .map(
          (c) => BusinessOptionItem(
            id: c.name,
            label: c.label.isNotEmpty ? c.label : c.name,
            icon: _categoryIcon(c.icon),
            iconUrl: c.iconUrl.isNotEmpty ? c.iconUrl : null,
          ),
        )
        .toList();

    return BusinessOptionPickerPage(
      title: 'Business type',
      question: 'What type of business is this?',
      subtitle: () {
        if (_selectedCategory == null) return 'Choose a category';
        for (final o in options) {
          if (o.id == _selectedCategory) return o.label;
        }
        return 'Choose a category';
      }(),
      options: options,
      selectedId: _selectedCategory,
      stepIndex: 1,
      totalSteps: 2,
      loading: _loadingCategories || _isSavingBusinessData,
      onBack: () => _onBack(false),
      onSelect: (id) => setState(() => _selectedCategory = id),
      onContinue: (_selectedCategory == null || _isSavingBusinessData)
          ? null
          : _saveOnboardingAndGoToPlan,
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
              onPressed: () => setState(() => _step = 3),
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
                  child: _cardLast4 == null
                      ? Text(
                          'No card added yet',
                          style: WaUi.caption.copyWith(
                            fontSize: 13,
                            color: _muted,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cardBrand ?? 'Card',
                              style: WaUi.bodyMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '•••• $_cardLast4',
                              style: WaUi.caption.copyWith(
                                fontSize: 13,
                                color: _muted,
                              ),
                            ),
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
            onPressed: _pay,
          ),
        ),
      ],
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '--';
    return '${value.day}/${value.month}/${value.year}';
  }
}

class _SavedCardPreview {
  final String last4;
  final String brand;

  const _SavedCardPreview({required this.last4, required this.brand});
}

class _AddPaymentMethodSheet extends StatefulWidget {
  const _AddPaymentMethodSheet();

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  static const _muted = Color(0xFF8E8E93);

  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  String? _formError;

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _detectBrand(String digits) {
    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits) ||
        RegExp(r'^2[2-7]').hasMatch(digits)) {
      return 'Mastercard';
    }
    if (digits.startsWith('3')) return 'Amex';
    return 'Card';
  }

  void _save() {
    final digits = _numberController.text.replaceAll(RegExp(r'\D'), '');
    final expiry = _expiryController.text.trim();
    final cvc = _cvcController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _formError = 'Enter the name on the card');
      return;
    }
    if (digits.length < 13 || digits.length > 19) {
      setState(() => _formError = 'Enter a valid card number');
      return;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      setState(() => _formError = 'Enter expiry as MM/YY');
      return;
    }
    if (cvc.length < 3) {
      setState(() => _formError = 'Enter a valid CVC');
      return;
    }

    Navigator.pop(
      context,
      _SavedCardPreview(
        last4: digits.substring(digits.length - 4),
        brand: _detectBrand(digits),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Add Payment Method',
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Card details stay on this device. Real card charging will use Stripe later.',
              style: WaUi.caption.copyWith(
                fontSize: 12,
                color: _muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: WaUi.fieldDecoration(
                labelText: 'Name on card',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                _CardNumberFormatter(),
              ],
              decoration: WaUi.fieldDecoration(
                labelText: 'Card number',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    decoration: WaUi.fieldDecoration(
                      labelText: 'MM/YY',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvcController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: WaUi.fieldDecoration(
                      labelText: 'CVC',
                    ),
                  ),
                ),
              ],
            ),
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: WaUi.caption.copyWith(
                  color: const Color(0xFFD32F2F),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            PillButton(
              label: 'Save card',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SubcriptionSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (_) => ProUpgradeSheet(),
    );
  }
}

class ProUpgradeSheet extends StatefulWidget {
  const ProUpgradeSheet({Key? key}) : super(key: key);

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  bool _isYearlySelected = true;
  final _transactionController = TextEditingController();
  String _receiptBase64 = '';

  int _step = 0; // 0 = intro, 1 = Business Details, 2 = Plan Selection
  final _businessNameController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = const [
    'Technology',
    'Retail',
    'Health',
    'Education',
    'Finance',
    'Real Estate',
    'Food & Beverage',
    'Entertainment',
    'Other',
  ];
  bool _isSavingBusinessData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).profile;
      _businessNameController.text = profile.businessName ?? '';
      if (_categories.contains(profile.businessCategory)) {
        _selectedCategory = profile.businessCategory;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await pickFile();
    if (file?.file == null) return;

    _receiptBase64 = await fileToBase64(File(file!.file!.path));
    setState(() {});
  }

  Future<void> _submitRequest() async {
    final messenger = sheetMessenger(context);
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    final planId = _isYearlySelected ? 'yearly' : 'monthly';

    final success = await provider.subscribe(
      planId,
      context,
      transactionRef: _transactionController.text.trim(),
      paymentReceipt: _receiptBase64,
    );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.subscriptionRequestSubmitted)),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleNext() async {
    final messenger = sheetMessenger(context);
    final name = _businessNameController.text.trim();
    if (name.isEmpty || _selectedCategory == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterBusinessDetailsToContinue),
        ),
      );
      return;
    }

    setState(() => _isSavingBusinessData = true);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
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
      setState(() => _step = 2);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(response.message ?? context.l10n.failedToSaveBusinessDetails),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final subscription = subscriptionProvider.currentSubscription;
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;

    return SheetScaffold(
      body: AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          // Keep the sheet above the keyboard and scrollable if needed.
          maxHeight: media.size.height - keyboardInset - media.padding.top,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161618) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
          bottom: media.padding.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subscription?.isRequested == true)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Big center icon
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        size: 56,
                        color: Colors.orange,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Title
                    Text(context.l10n.requestPending2,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    SizedBox(height: 10),

                    // Subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        context.l10n.subscriptionRequestSubmittedOn(
                          subscription!.planName,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                )
              else if (subscription?.isRejected == true)
                _statusPanel(
                  isDark: isDark,
                  title: context.l10n.requestRejected,
                  text:
                      "${subscription!.rejectionReason.isEmpty ? context.l10n.noReasonProvided : subscription.rejectionReason}\nYou can try again below.",
                )
              else if (subscription?.isActive == true)
                _statusPanel(
                  isDark: isDark,
                  title: context.l10n.premiumActive,
                  text:
                      "${subscription!.planName} is active until ${_date(subscription.endDate)}.\nPlease cancel current plan before buying another.",
                ),
              if (subscription?.isRequested == false &&
                  subscription?.isActive == false)
                _step == 0
                    ? _buildIntroStep(isDark)
                    : _step == 1
                        ? _buildBusinessDetailsStep(isDark)
                        : _buildPlanSelectionStep(
                            isDark,
                            theme,
                            subscriptionProvider,
                          ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _openLegalPage(String path) async {
    final uri = Uri.parse('${Constants.appDomain}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildIntroStep(bool isDark) {
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF4B4F56);
    final linkColor = const Color(0xFF1877F2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Center(child: _BusinessProIntroArt()),
        const SizedBox(height: 20),
        Text(
          context.l10n.businessProBrand,
          textAlign: TextAlign.center,
          style: WaUi.headline.copyWith(
            color: linkColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.upgradeYourBusiness,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.businessProIntroBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 28),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 13, height: 1.4, color: bodyColor),
            children: [
              TextSpan(text: '${context.l10n.byContinuingYouAgreeTo} '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => _openLegalPage('/privacy'),
                  child: Text(
                    context.l10n.privacyPolicy,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: linkColor,
                    ),
                  ),
                ),
              ),
              TextSpan(text: ' ${context.l10n.andConjunction} '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => _openLegalPage('/terms'),
                  child: Text(
                    context.l10n.termsOfService,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: linkColor,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        WaPrimaryButton(
          label: context.l10n.continueLabel,
          onPressed: () => setState(() => _step = 1),
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsStep(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(context.l10n.businessDetails,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          context.l10n.pleaseProvideYourBusinessDetailsBeforeUpgrading,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        TextField(
          controller: _businessNameController,
          decoration: WaUi.fieldDecoration(
            labelText: context.l10n.businessName,
          ),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: WaUi.fieldDecoration(
            labelText: context.l10n.businessCategory,
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_industryLabel(context, category)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
        SizedBox(height: 24),
        WaPrimaryButton(
          label: context.l10n.next,
          loading: _isSavingBusinessData,
          onPressed: _isSavingBusinessData ? null : _handleNext,
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
      ],
    );
  }

  Widget _buildPlanSelectionStep(
    bool isDark,
    ThemeData theme,
    SubscriptionProvider subscriptionProvider,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// HANDLE
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        SizedBox(height: 12),

        /// TITLE (same UI)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.upgradeTo2,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(context.l10n.pro,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        /// YEARLY (same UI style)
        GestureDetector(
          onTap: () => setState(() => _isYearlySelected = true),
          child: _planCard(
            isDark: isDark,
            selected: _isYearlySelected,
            title: context.l10n.yearly,
            subtitle: context.l10n.rs8300BilledYearly,
            price: context.l10n.pkrPerMonth('691.66'),
            badge: context.l10n.monthsFree(7),
          ),
        ),

        SizedBox(height: 12),

        /// MONTHLY
        GestureDetector(
          onTap: () => setState(() => _isYearlySelected = false),
          child: _planCard(
            isDark: isDark,
            selected: !_isYearlySelected,
            title: context.l10n.monthly,
            subtitle: context.l10n.rs1600BilledMonthly,
            price: context.l10n.pkrPerMonth('1,600'),
            badge: null,
          ),
        ),

        SizedBox(height: 14),

        Text(
          context.l10n.cancelAnytime,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),

        SizedBox(height: 16),

        /// BENEFITS (same UI)
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _benefit(Icons.palette_outlined, context.l10n.customizeYourself),
              _benefit(Icons.qr_code_scanner, context.l10n.unlimitedAiScans),
              _benefit(
                Icons.analytics_outlined,
                context.l10n.analyticsAndInsights,
              ),
            ],
          ),
        ),

        SizedBox(height: 18),

        /// TRANSACTION FIELD (added from subscription screen)
        TextField(
          controller: _transactionController,
          decoration: WaUi.fieldDecoration(
            labelText: context.l10n.transactionReferenceOptional,
          ),
        ),

        SizedBox(height: 10),

        /// RECEIPT UPLOAD
        OutlinedButton.icon(
          onPressed: _pickReceipt,
          icon: Icon(Icons.upload_file),
          label: Text(
            _receiptBase64.isEmpty
                ? context.l10n.uploadReceiptOptional
                : context.l10n.receiptAttached,
          ),
        ),

        SizedBox(height: 18),

        /// BUTTON (now real subscription)
        WaPrimaryButton(
          label: context.l10n.upgradeNow,
          loading: subscriptionProvider.isLoading,
          onPressed: subscriptionProvider.isLoading ? null : _submitRequest,
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
      ],
    );
  }

  Widget _planCard({
    required bool isDark,
    required bool selected,
    required String title,
    required String subtitle,
    required String price,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.black12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Text(price, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Icon(selected ? Icons.check_circle : Icons.radio_button_off),
            ],
          ),
        ),

        if (badge != null)
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _statusPanel({
    required bool isDark,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        color: isDark ? Colors.white10 : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '--';
    return '${value.day}/${value.month}/${value.year}';
  }

  String _industryLabel(BuildContext context, String category) {
    switch (category) {
      case 'Technology':
        return context.l10n.industryTechnology;
      case 'Retail':
        return context.l10n.industryRetail;
      case 'Health':
        return context.l10n.industryHealthcare;
      case 'Education':
        return context.l10n.industryEducation;
      case 'Finance':
        return context.l10n.industryFinance;
      case 'Real Estate':
        return context.l10n.realEstate;
      case 'Food & Beverage':
        return context.l10n.foodBeverage;
      case 'Entertainment':
        return context.l10n.industryEntertainment;
      case 'Other':
        return context.l10n.industryOther;
      default:
        return category;
    }
  }
}

class _BusinessProIntroArt extends StatelessWidget {
  const _BusinessProIntroArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 18,
            child: CustomPaint(
              size: const Size(10, 10),
              painter: _SparkPainter(),
            ),
          ),
          Positioned(
            right: 22,
            top: 8,
            child: CustomPaint(
              size: const Size(8, 8),
              painter: _SparkPainter(),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 22,
            child: CustomPaint(
              size: const Size(7, 7),
              painter: _SparkPainter(),
            ),
          ),
          Positioned(
            left: 10,
            top: 28,
            child: Container(
              width: 88,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFD7F0C8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                size: 36,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 36,
            child: Container(
              width: 96,
              height: 64,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9DFD0),
                borderRadius: BorderRadius.circular(22),
              ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArtLine(width: 52),
                  SizedBox(height: 8),
                  _ArtLine(width: 36),
                ],
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 14,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtLine extends StatelessWidget {
  const _ArtLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFC4B8A6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), paint);
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

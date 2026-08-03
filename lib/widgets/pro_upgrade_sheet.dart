import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
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

  int _step = 0; // 0 = Business Details, 1 = Plan Selection
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
      setState(() => _step = 1);
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
                        "Your ${subscription!.planName} request is submitted and waiting for approval on ${_date(subscription.requestedAt)}.",
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
          decoration: InputDecoration(
            labelText: context.l10n.businessName,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: context.l10n.businessCategory,
            border: OutlineInputBorder(),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
        SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: _isSavingBusinessData ? null : _handleNext,
            child: _isSavingBusinessData
                ? CircularProgressIndicator()
                : Text(context.l10n.next),
          ),
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
            price: "PKR 691.66/month",
            badge: "7 months free",
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
            price: "PKR 1,600/month",
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
              _benefit(Icons.palette_outlined, "Customize your profile"),
              _benefit(Icons.qr_code_scanner, "Unlimited AI scans"),
              _benefit(Icons.analytics_outlined, "Analytics & insights"),
            ],
          ),
        ),

        SizedBox(height: 18),

        /// TRANSACTION FIELD (added from subscription screen)
        TextField(
          controller: _transactionController,
          decoration: InputDecoration(
            labelText: context.l10n.transactionReferenceOptional,
            border: OutlineInputBorder(),
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
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: subscriptionProvider.isLoading ? null : _submitRequest,
            child: subscriptionProvider.isLoading
                ? CircularProgressIndicator()
                : Text(context.l10n.upgradeNow),
          ),
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
}

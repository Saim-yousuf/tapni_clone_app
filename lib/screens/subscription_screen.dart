import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class SubscriptionScreen extends StatefulWidget {
  SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
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
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _businessNameController.text = profileProvider.profile.businessName ?? '';
      if (_categories.contains(profileProvider.profile.businessCategory)) {
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
        SnackBar(content: Text(context.l10n.pleaseEnterBusinessDetailsToContinue)),
      );
      return;
    }

    setState(() => _isSavingBusinessData = true);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
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
        SnackBar(content: Text(response.message ?? context.l10n.failedToSaveBusinessDetails)),
      );
    }
  }

  Future<void> _pickReceipt() async {
    final file = await pickFile();
    if (file?.file == null) return;
    _receiptBase64 = await fileToBase64(File(file!.file!.path));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final subscription = provider.currentSubscription;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.subscription)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subscription?.isRequested == true)
                _statusPanel(
                  title: context.l10n.requestPending,
                  text:
                      'Your ${subscription!.planName} request was submitted on ${_date(subscription.requestedAt)}.',
                )
              else if (subscription?.isRejected == true)
                _statusPanel(
                  title: context.l10n.requestRejected,
                  text:
                      '${subscription!.rejectionReason.isEmpty ? context.l10n.noReasonProvided : subscription.rejectionReason}\nYou can submit a new request below.',
                )
              else if (subscription?.isActive == true)
                _statusPanel(
                  title: context.l10n.premiumActive,
                  text:
                      '${subscription!.planName} is active until ${_date(subscription.endDate)}. Cancel your current subscription before buying another plan.',
                ),
              if (subscription?.isRequested != true &&
                  subscription?.isActive != true) ...[
                if (_step == 0) _buildBusinessDetailsStep(isDark)
                else _buildPlanSelectionStep(isDark, provider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.businessDetails,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8),
        Text(
          context.l10n.pleaseProvideYourBusinessDetailsBeforeUpgrading,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
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
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSavingBusinessData ? null : _handleNext,
            child: _isSavingBusinessData
                ? CircularProgressIndicator()
                : Text(context.l10n.next),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelectionStep(bool isDark, SubscriptionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.choosePlan,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 16),
        _planTile(
          title: context.l10n.yearly,
          subtitle: context.l10n.bestValue,
          selected: _isYearlySelected,
          onTap: () => setState(() => _isYearlySelected = true),
        ),
        SizedBox(height: 12),
        _planTile(
          title: context.l10n.monthly,
          subtitle: context.l10n.payMonthByMonth,
          selected: !_isYearlySelected,
          onTap: () => setState(() => _isYearlySelected = false),
        ),
        SizedBox(height: 20),
        _bankPanel(isDark),
        SizedBox(height: 16),
        TextField(
          controller: _transactionController,
          decoration: InputDecoration(
            labelText: context.l10n.transactionReferenceNumberOptional,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickReceipt,
          icon: Icon(Icons.receipt_long_outlined),
          label: Text(
            _receiptBase64.isEmpty
                ? context.l10n.uploadReceiptOptional
                : context.l10n.receiptAttached,
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _submitRequest,
            child: provider.isLoading
                ? CircularProgressIndicator()
                : Text(context.l10n.requestSubscription),
          ),
        ),
      ],
    );
  }

  Widget _planTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.black : Colors.black12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.radio_button_off),
          ],
        ),
      ),
    );
  }

  Widget _bankPanel(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.bankAccount, style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(context.l10n.accountTitleTapni),
          Text(context.l10n.bankAddBankNameHere),
          Text(context.l10n.accountIBANAddAccountNumberHere),
        ],
      ),
    );
  }

  Widget _statusPanel({required String title, required String text}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
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

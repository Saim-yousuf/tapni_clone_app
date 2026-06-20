import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

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
  final List<String> _categories = [
    'Technology', 'Retail', 'Health', 'Education', 'Finance', 
    'Real Estate', 'Food & Beverage', 'Entertainment', 'Other'
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
        const SnackBar(content: Text('Subscription request submitted.')),
      );
    }
  }

  Future<void> _handleNext() async {
    final name = _businessNameController.text.trim();
    if (name.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter business details to continue')),
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
        SnackBar(content: Text(response.message ?? 'Failed to save business details')),
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
      appBar: AppBar(title: const Text('Subscription')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subscription?.isRequested == true)
                _statusPanel(
                  title: 'Request pending',
                  text:
                      'Your ${subscription!.planName} request was submitted on ${_date(subscription.requestedAt)}.',
                )
              else if (subscription?.isRejected == true)
                _statusPanel(
                  title: 'Request rejected',
                  text:
                      '${subscription!.rejectionReason.isEmpty ? 'No reason provided.' : subscription.rejectionReason}\nYou can submit a new request below.',
                )
              else if (subscription?.isActive == true)
                _statusPanel(
                  title: 'Premium active',
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
        const Text(
          'Business Details',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Please provide your business details before upgrading.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Business Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Business Category',
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSavingBusinessData ? null : _handleNext,
            child: _isSavingBusinessData
                ? const CircularProgressIndicator()
                : const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelectionStep(bool isDark, SubscriptionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Plan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        _planTile(
          title: 'Yearly',
          subtitle: 'Best value',
          selected: _isYearlySelected,
          onTap: () => setState(() => _isYearlySelected = true),
        ),
        const SizedBox(height: 12),
        _planTile(
          title: 'Monthly',
          subtitle: 'Pay month by month',
          selected: !_isYearlySelected,
          onTap: () => setState(() => _isYearlySelected = false),
        ),
        const SizedBox(height: 20),
        _bankPanel(isDark),
        const SizedBox(height: 16),
        TextField(
          controller: _transactionController,
          decoration: const InputDecoration(
            labelText: 'Transaction reference number (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickReceipt,
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(
            _receiptBase64.isEmpty
                ? 'Upload receipt (optional)'
                : 'Receipt attached',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _submitRequest,
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Request subscription'),
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
        padding: const EdgeInsets.all(16),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bank Account', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Account Title: Tapni'),
          Text('Bank: Add bank name here'),
          Text('Account / IBAN: Add account number here'),
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
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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

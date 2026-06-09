import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';

class SubcriptionSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProUpgradeSheet(),
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

  Future<void> _pickReceipt() async {
    final file = await pickFile();
    if (file?.file == null) return;

    _receiptBase64 = await fileToBase64(File(file!.file!.path));
    setState(() {});
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

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription request submitted')),
      );
      Navigator.pop(context);
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
          bottom: MediaQuery.of(context).padding.bottom + 16,
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
                    const SizedBox(height: 32),

                    // Big center icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 56,
                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Request Pending',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Your ${subscription!.planName} request is submitted and waiting for approval on ${_date(subscription.requestedAt)}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                )
              else if (subscription?.isRejected == true)
                _statusPanel(
                  isDark: isDark,
                  title: "Request rejected",
                  text:
                      "${subscription!.rejectionReason.isEmpty ? "No reason provided." : subscription.rejectionReason}\nYou can try again below.",
                )
              else if (subscription?.isActive == true)
                _statusPanel(
                  isDark: isDark,
                  title: "Premium active",
                  text:
                      "${subscription!.planName} is active until ${_date(subscription.endDate)}.\nPlease cancel current plan before buying another.",
                ),
              if (subscription?.isRequested == false &&
                  subscription?.isActive == false)
                Column(
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
                    const SizedBox(height: 12),

                    /// TITLE (same UI)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Upgrade to ',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// YEARLY (same UI style)
                    GestureDetector(
                      onTap: () => setState(() => _isYearlySelected = true),
                      child: _planCard(
                        isDark: isDark,
                        selected: _isYearlySelected,
                        title: "Yearly",
                        subtitle: "Rs 8,300 billed yearly",
                        price: "PKR 691.66/month",
                        badge: "7 months free",
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// MONTHLY
                    GestureDetector(
                      onTap: () => setState(() => _isYearlySelected = false),
                      child: _planCard(
                        isDark: isDark,
                        selected: !_isYearlySelected,
                        title: "Monthly",
                        subtitle: "Rs 1,600 billed monthly",
                        price: "PKR 1,600/month",
                        badge: null,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Cancel anytime.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// BENEFITS (same UI)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _benefit(
                            Icons.palette_outlined,
                            "Customize your profile",
                          ),
                          _benefit(Icons.qr_code_scanner, "Unlimited AI scans"),
                          _benefit(
                            Icons.analytics_outlined,
                            "Analytics & insights",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// TRANSACTION FIELD (added from subscription screen)
                    TextField(
                      controller: _transactionController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction reference (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// RECEIPT UPLOAD
                    OutlinedButton.icon(
                      onPressed: _pickReceipt,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _receiptBase64.isEmpty
                            ? "Upload receipt (optional)"
                            : "Receipt attached",
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// BUTTON (now real subscription)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                        onPressed: subscriptionProvider.isLoading
                            ? null
                            : _submitRequest,
                        child: subscriptionProvider.isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Upgrade now"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: const TextStyle(
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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

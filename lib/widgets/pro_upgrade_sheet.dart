import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';

class ProUpgradeSheet extends StatefulWidget {
  const ProUpgradeSheet({Key? key}) : super(key: key);

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  bool _isYearlySelected = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 12),

          // 14 Days Free Trial Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '14 days free trial',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Upgrade to PRO title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Upgrade to ',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
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
                  border: isDark ? Border.all(color: Colors.white24) : null,
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subscription Plans Selection Options
          // Option 1: Yearly
          GestureDetector(
            onTap: () {
              setState(() {
                _isYearlySelected = true;
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.02)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isYearlySelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white12 : const Color(0xFFE5E5EA)),
                      width: _isYearlySelected ? 2.2 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yearly',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs 8.300 billed yearly',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PKR 691.66',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                '/month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        _isYearlySelected
                            ? Icons.check_circle
                            : Icons.radio_button_off,
                        color: _isYearlySelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white30 : Colors.black26),
                        size: 24,
                      ),
                    ],
                  ),
                ),
                // Badge: "7 months free"
                Positioned(
                  top: -11,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: isDark ? Border.all(color: Colors.white24) : null,
                    ),
                    child: const Text(
                      '7 months free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Option 2: Monthly
          GestureDetector(
            onTap: () {
              setState(() {
                _isYearlySelected = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_isYearlySelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white12 : const Color(0xFFE5E5EA)),
                  width: !_isYearlySelected ? 2.2 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monthly',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Rs 1.600',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '/month',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    !_isYearlySelected
                        ? Icons.check_circle
                        : Icons.radio_button_off,
                    color: !_isYearlySelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white30 : Colors.black26),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Cancel anytime text
          Text(
            'Cancel anytime.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Benefits Checklist Card Container
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
                _buildBenefitRow(
                  icon: Icons.palette_outlined,
                  text: 'Customize your profile design',
                  isDark: isDark,
                ),
                _buildBenefitRow(
                  icon: Icons.qr_code_scanner_rounded,
                  text: 'Unlimited scans with AI scanner',
                  isDark: isDark,
                ),
                _buildBenefitRow(
                  icon: Icons.remove_circle_outline_rounded,
                  text: 'Remove Tapni branding and add your own',
                  isDark: isDark,
                ),
                _buildBenefitRow(
                  icon: Icons.analytics_outlined,
                  text: 'Analytics & insights',
                  isDark: isDark,
                ),
                _buildBenefitRow(
                  icon: Icons.people_outline_rounded,
                  text: 'Unlimited contacts & contact categories',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Learn More Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Learn more',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade Now CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              onPressed: () {
                profileProvider.upgradeToPro();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🎉 Congratulations! You upgraded to Tapni PRO!',
                    ),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text(
                'Upgrade now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Policy & Terms disclaimer text
          Text(
            'By upgrading, you agree to our\nTerms of Service and Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white30 : Colors.black38,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Row helper for benefits card
  Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

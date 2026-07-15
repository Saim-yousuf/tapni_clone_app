import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/utils/theme.dart';

import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class TemplatesSheet extends StatefulWidget {
  const TemplatesSheet({Key? key}) : super(key: key);

  @override
  State<TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends State<TemplatesSheet> {
  late PageController _pageController;
  int _activePage = 0;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    _activePage = profileProvider.selectedTemplateIndex;
    _pageController = PageController(
      initialPage: _activePage,
      viewportFraction: 0.68, // gives the peek effect of next/previous cards
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    final templates = profileProvider.templates;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF161618) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 20,
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
          SizedBox(height: 16),
          
          // Title
          Text(
            context.l10n.templates,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal Swipe PageView Carousel
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _pageController,
              itemCount: templates.length,
              onPageChanged: (int page) {
                setState(() {
                  _activePage = page;
                });
              },
              itemBuilder: (context, index) {
                final template = templates[index];
                
                // Active Card size animation scaling
                double scale = _activePage == index ? 1.0 : 0.88;
                double opacity = _activePage == index ? 1.0 : 0.6;

                return AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: opacity,
                    duration: const Duration(milliseconds: 250),
                    child: _buildTemplateCard(template, profile.name),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Horizontal Page Indicator (Dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              templates.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4.5),
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  color: _activePage == index
                      ? (isDark ? AppTheme.secondaryWhite : AppTheme.primaryBlack)
                      : (isDark ? Colors.white24 : Colors.black12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Apply Template Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
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
                onPressed: _isApplying
                    ? null
                    : () async {
                        final selectedTemplate = templates[_activePage];
                        if (selectedTemplate.isPro &&
                            !profileProvider.isProUser) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ProUpgradeSheet(),
                          );
                          return;
                        }

                        setState(() => _isApplying = true);
                        bool saved = false;
                        try {
                          saved = await profileProvider.saveCardTemplate(
                            _activePage,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isApplying = false);
                          }
                        }
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              saved
                                  ? 'Applied "${selectedTemplate.name}" template'
                                  : context.l10n.templateAppliedLocallySyncFailed,
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      },
                child: _isApplying
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(context.l10n.applyTemplate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Template card layout widget
  Widget _buildTemplateCard(CardTemplate template, String name) {
    final hasBorder = template.backgroundColor == Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: template.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: hasBorder
            ? Border.all(color: Colors.black.withOpacity(0.08), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (Initials circle + Type label)
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: template.isDark 
                            ? Colors.white.withOpacity(0.15) 
                            : Colors.black.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : 'S',
                          style: TextStyle(
                            color: template.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.digitalBusinessCard,
                        style: TextStyle(
                          color: template.textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Name Details
                Text(
                  context.l10n.name2,
                  style: TextStyle(
                    color: template.labelColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: template.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12),

                // Bio details
                Text(
                  context.l10n.bio,
                  style: TextStyle(
                    color: template.labelColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                // Simple high fidelity bio line visualizers
                Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: template.labelColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Beautiful Vector QR Code Mock in center
                Expanded(
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: CustomPaint(
                        painter: MockQrPainter(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // branding logo
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contactless, 
                        size: 16, 
                        color: template.brandingColor.withOpacity(0.7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        context.l10n.tapni,
                        style: TextStyle(
                          color: template.brandingColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Optional PRO Badge on Top Right
          if (template.isPro)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Text(context.l10n.pro,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter to draw a very sleek realistic mock QR Code
class MockQrPainter extends CustomPainter {
  final Color color;
  MockQrPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double blockSize = size.width / 9;

    // Helper to draw a square block
    void drawBlock(double col, double row, double w, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(col * blockSize, row * blockSize, w * blockSize, h * blockSize),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }

    // Top-Left Finder Pattern
    drawBlock(0, 0, 3, 3);
    paint.color = Colors.white;
    drawBlock(0.6, 0.6, 1.8, 1.8);
    paint.color = color;
    drawBlock(1.1, 1.1, 0.8, 0.8);

    // Top-Right Finder Pattern
    drawBlock(6, 0, 3, 3);
    paint.color = Colors.white;
    drawBlock(6.6, 0.6, 1.8, 1.8);
    paint.color = color;
    drawBlock(7.1, 1.1, 0.8, 0.8);

    // Bottom-Left Finder Pattern
    drawBlock(0, 6, 3, 3);
    paint.color = Colors.white;
    drawBlock(0.6, 6.6, 1.8, 1.8);
    paint.color = color;
    drawBlock(1.1, 7.1, 0.8, 0.8);

    // Various mock data blocks in between
    drawBlock(4, 1, 1, 1);
    drawBlock(4, 3, 1, 2);
    drawBlock(1, 4, 2, 1);
    drawBlock(4, 6, 1, 1);
    drawBlock(7, 4, 1, 1);
    drawBlock(6, 5, 2, 1);
    drawBlock(3, 7, 2, 1);
    drawBlock(7, 7, 1, 2);
    drawBlock(6, 8, 1, 1);
    drawBlock(4, 8, 1, 1);
    drawBlock(5, 4, 1, 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
